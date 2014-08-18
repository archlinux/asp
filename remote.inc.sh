declare -A refcache=()

__remote_refcache_get() {
  local remote=$1 ttl=3600 now= cachetime= cachefile=$ASPCACHE/remote-$remote

  # miss
  cachetime=$(stat -c %Y "$cachefile" 2>/dev/null) || return 1

  printf -v now '%(%s)T' -1

  # miss
  (( now > (cachetime + ttl) )) && return 1

  # hit
  mapfile -t "$2" <"$cachefile"
}

__remote_refcache_update() {
  local remote=$1 cachefile=$ASPCACHE/remote-$remote

  trap "rm -f '$cachefile~'" RETURN

  git ls-remote "$remote" 'refs/heads/packages/*' |
      awk '{ sub(/refs\/heads\//, "", $2); print $2 }' >"$cachefile~" &&
          mv "$cachefile"{~,}
}

remote_get_all_refs() {
  local remote=$1

  if ! __remote_refcache_get "$remote" "$2"; then
    __remote_refcache_update "$remote"
    __remote_refcache_get "$remote" "$2"
  fi
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

  mapfile -t "$2" < <(git branch --remote 2>/dev/null |
      awk -F'( +|/)' -v "remote=$1" \
        '$2 == remote && $3 == "packages" { print "packages/" $4 }')
}

remote_update_refs() {
  local remote=$1 refspecs=("${@:2}")

  git fetch "$remote" "${refspecs[@]}"
}

remote_update() {
  local remote=$1 refspecs

  remote_get_tracked_refs "$remote" refspecs

  # refuse to update everything
  [[ -z $refspecs ]] && return 0

  remote_update_refs "$remote" "${refspecs[@]}"
}

remote_get_url() {
  local remote=$1

  git ls-remote --get-url "$remote"
}

remote_untrack() {
  local remote=$1 pkgname=$2

  if git show-ref -q "refs/remotes/$remote/packages/$pkgname"; then
    git branch -dr "$remote/packages/$pkgname"
  fi
}
