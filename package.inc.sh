package_init() {
  local pkgname=$1
  local do_update=1

  if [[ $1 = -n ]]; then
    do_update=0
    shift
    pkgname=$1
  fi

  package_find_remote "$pkgname" "$2" || return 1

  (( do_update )) || return 0

  if ! remote_is_tracking "${!2}" "$pkgname"; then
    package_update "$pkgname" "${!2}" || return 1
  fi
}

package_update() {
  local pkgname=$1 remote=$2

  git fetch "$remote" "packages/$pkgname"
}

package_find_remote() {
  local pkgname=$1 out=$2

  # fastpath, checks local caches only
  for r in "${ARCH_GIT_REPOS[@]}"; do
    if remote_is_tracking "$r" "$pkgname"; then
      printf -v "$out" %s "$r"
      return 0
    fi
  done

  # slowpath, needs to talk to the remote
  for r in "${ARCH_GIT_REPOS[@]}"; do
    if remote_has_package "$r" "$pkgname"; then
      printf -v "$out" %s "$r"
      return 0
    fi
  done

  log_error 'unknown package: %s' "$pkgname"

  return 1
}

package_log() {
  local pkgname=$1 method=$2 remote

  package_init "$pkgname" remote || return

  "_package_$method" "$pkgname" "$remote"
}

package_export() {
  local pkgname=$1 remote repo arch
  local mode objtype objid path

  if [[ $pkgname = */* ]]; then
    IFS=/ read -r repo pkgname <<<"$pkgname"
  fi

  package_init "$pkgname" remote || return 1

  # support $repo/$pkgname syntax
  if [[ $repo ]]; then
    subtree=repos/$repo-$OPT_ARCH
  else
    subtree=trunk
  fi

  if [[ -z $(git ls-tree "$remote/packages/$pkgname" "$subtree/") ]]; then
    if [[ $repo ]]; then
      log_error "package '%s' not found in repo '%s-%s'" "$pkgname" "$repo" "$OPT_ARCH"
      return 1
    else
      log_error "package '%s' has no trunk directory!" "$pkgname"
      return 1
    fi
  fi

  if (( ! OPT_FORCE )); then
    mkdir "$startdir/$pkgname" || return 1
  fi

  log_info 'exporting %s:%s' "$pkgname" "$subtree"
  git archive --format=tar "$remote/packages/$pkgname" "$subtree/" |
      bsdtar -C "$startdir" -s ",^$subtree/,$pkgname/," -xf - "$subtree/"
}

package_get_repos_with_arch() {
  local pkgname=$1 remote=$2
  local objtype path arch repo

  while read _ objtype _ path; do
    [[ $objtype = tree ]] || continue
    IFS=- read repo arch <<<"${path#repos/}"
    printf '%s %s\n' "$repo" "$arch"
  done < <(git ls-tree "$remote/packages/$pkgname" repos/)
}

package_get_arches() {
  local pkgname=$1 remote arch
  declare -A arches

  package_init "$pkgname" remote || return 1

  while read _ arch; do
    arches["$arch"]=1
  done < <(package_get_repos_with_arch "$pkgname" "$remote")

  printf '%s\n' "${!arches[@]}"
}

package_get_repos() {
  local pkgname=$1 remote repo
  declare -A repos

  package_init "$pkgname" remote || return 1

  while read repo _; do
    repos["$repo"]=1
  done < <(package_get_repos_with_arch "$pkgname" "$remote")

  printf '%s\n' "${!repos[@]}"
}

_package_shortlog() {
  local pkgname=$1 remote=$2

  git log --pretty=oneline "$remote/packages/$pkgname"
}

_package_difflog() {
  local pkgname=$1 remote=$2

  git log -p "$remote/packages/$pkgname"
}

_package_log() {
  local pkgname=$1 remote=$2

  git log "$remote/packages/$pkgname"
}
