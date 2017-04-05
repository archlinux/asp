__remote_refcache_update() {
  local remote=$1 cachefile=$ASPCACHE/remote-$remote

  # shellcheck disable=SC2064
  trap "rm -f '$cachefile~'" RETURN

  git ls-remote "$remote" 'refs/heads/packages/*' |
      awk '{ sub(/refs\/heads\//, "", $2); print $2 }' >"$cachefile~" &&
          mv "$cachefile"{~,}
}

__remote_refcache_get() {
  local remote=$1 ttl=3600 now cachetime cachefile=$ASPCACHE/remote-$remote

  printf -v now '%(%s)T' -1

  if ! cachetime=$(stat -c %Y "$cachefile" 2>/dev/null) ||
      (( now > (cachetime + ttl) )); then
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

  in_array "packages/$pkgname" "${refs[@]}"
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
