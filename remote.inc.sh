__remote_refcache_update() {
  local remote=$1 cachefile=$ASPCACHE/remote-$remote refs

  refs=$(git ls-remote "$remote" 'refs/heads/packages/*') ||
      log_fatal "failed to update remote $remote"

  printf '%s' "$refs" |
      awk '{ sub(/refs\/heads\/packages\//, "", $2); print $2 }' >"$cachefile"
}

__remote_refcache_is_stale() {
  local now cachetime cachefile=$1 ttl=3600

  printf -v now '%(%s)T' -1

  # The cache is stale if we've exceeded the TTL.
  if ! cachetime=$(stat -c %Y "$cachefile" 2>/dev/null) ||
      (( now > (cachetime + ttl) )); then
    return 0
  fi

  # We also consider the cache to be stale when this script is newer than the
  # cache. This allows upgrades to asp to implicitly wipe the cache and not
  # make any guarantees about the file format.
  if (( $(stat -c %Y "${BASH_SOURCE[0]}" 2>/dev/null) > cachetime )); then
    return 0
  fi

  return 1
}

__remote_refcache_get() {
  local remote=$1 cachefile=$ASPCACHE/remote-$remote

  if __remote_refcache_is_stale "$cachefile"; then
    __remote_refcache_update "$remote"
  fi

  mapfile -t "$2" <"$cachefile"
}

remote_get_all_refs() {
  local remote=$1

  __remote_refcache_get "$remote" "$2"
}

remote_has_package() {
  local remote=$1 pkgname=$2 refs

  remote_get_all_refs "$remote" refs

  in_array "$pkgname" "${refs[@]}"
}

remote_is_tracking() {
  local repo=$1 pkgname=$2

  git show-ref -q "$repo/packages/$pkgname"
}

remote_get_tracked_refs() {
  local remote=$1

  mapfile -t "$2" < \
    <(git for-each-ref --format='%(refname:strip=3)' "refs/remotes/$remote")
}

remote_update_refs() {
  local remote=$1 refspecs=("${@:2}")

  quiet_git fetch "$remote" "${refspecs[@]}"
}

remote_update() {
  local remote=$1 refspecs

  remote_get_tracked_refs "$remote" refspecs

  # refuse to update everything
  [[ -z $refspecs ]] && return 0

  remote_update_refs "$remote" "${refspecs[@]}"
}

remote_untrack() {
  local remote=$1 pkgname=$2

  if git show-ref -q "refs/remotes/$remote/packages/$pkgname"; then
    git branch -dr "$remote/packages/$pkgname"
  fi
}
