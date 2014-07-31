remote_get_all_refs() {
  local remote=$1

  mapfile -t "$2" < <(git ls-remote "$remote" 'refs/heads/packages/*' |
      awk '{ sub(/refs\/heads\//, "", $2); print $2 }')
}

remote_has_package() {
  local remote=$1 pkgname=$2

  [[ $(git ls-remote "$remote" "$pkgname") ]]
}

remote_is_tracking() {
  local repo=$1 pkgname=$2

  git rev-parse "$repo/packages/$pkgname" &>/dev/null
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
  # TODO: allow this with a flag
  [[ -z $refspecs ]] && return 0

  remote_update_refs "$remote" "${refspecs[@]}"
}

remote_get_url() {
  local remote=$1

  git ls-remote --get-url "$remote"
}

remote_untrack() {
  local remote=$1 pkgname=$2

  git branch -dr "$remote/packages/$pkgname"
}
