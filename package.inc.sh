package_resolve() {
  local pkgbase

  [[ $pkgname ]] || log_fatal 'BUG: package_resolve called without pkgname var set'

  if package_find_remote "$1" "$2"; then
    return 0
  fi

  if pkgbase=$(archweb_get_pkgbase "$1") && package_find_remote "$pkgbase" "$2"; then
    log_info '%s is part of package %s' "$1" "$pkgbase"
    pkgname=$pkgbase
    return 0
  fi

  log_error 'unknown package: %s' "$pkgname"
  return 1
}

package_init() {
  local do_update=1

  if [[ $1 = -n ]]; then
    do_update=0
    shift
  fi

  pkgname=$1

  package_resolve "$pkgname" "$2" || return

  (( do_update )) || return 0

  remote_is_tracking "${!2}" "$pkgname" ||
      remote_update_refs "${!2}" "packages/$pkgname"
}

package_find_remote() {
  pkgname=$1

  # fastpath, checks local caches only
  for r in "${ARCH_GIT_REPOS[@]}"; do
    if remote_is_tracking "$r" "$pkgname"; then
      printf -v "$2" %s "$r"
      return 0
    fi
  done

  # slowpath, needs to talk to the remote
  for r in "${ARCH_GIT_REPOS[@]}"; do
    if remote_has_package "$r" "$pkgname"; then
      printf -v "$2" %s "$r"
      return 0
    fi
  done

  return 1
}

package_log() {
  local method=$2 logargs remote
  pkgname=$1

  package_init "$pkgname" remote || return

  case $method in
    shortlog)
      logargs=('--pretty=oneline')
      ;;
    difflog)
      logargs=('-p')
      ;;
    log)
      logargs=()
      ;;
    *)
      die 'internal error: unknown log method: %s' "$method"
      ;;
  esac

  git log "${logargs[@]}" "$remote/packages/$pkgname" -- trunk/
}

package_show_file() {
  local file=${2:-PKGBUILD} remote repo subtree
  pkgname=$1

  if [[ $pkgname = */* ]]; then
    IFS=/ read -r repo pkgname <<<"$pkgname"
  fi

  package_init "$pkgname" remote || return

  if [[ $file != */* ]]; then
    if [[ $repo ]]; then
      subtree=repos/$repo-$OPT_ARCH/
    else
      subtree=trunk/
    fi
  fi

  git show "remotes/$remote/packages/$pkgname:$subtree$file"
}

package_list_files() {
  local remote subtree=trunk
  pkgname=$1

  if [[ $pkgname = */* ]]; then
    IFS=/ read -r repo pkgname <<<"$pkgname"
  fi

  package_init "$pkgname" remote || return

  if [[ $repo ]]; then
    subtree=repos/$repo-$OPT_ARCH
  fi


  git ls-tree -r --name-only "remotes/$remote/packages/$pkgname" "$subtree" |
      awk -v "prefix=$subtree/" 'sub(prefix, "")'
}

package_export() {
  local remote repo arch path subtree=trunk
  pkgname=$1

  if [[ $pkgname = */* ]]; then
    IFS=/ read -r repo pkgname <<<"$pkgname"
  fi

  package_init "$pkgname" remote || return

  if [[ $repo ]]; then
    subtree=repos/$repo-$OPT_ARCH
  fi

  if [[ -z $(git ls-tree "remotes/$remote/packages/$pkgname" "$subtree/") ]]; then
    if [[ $repo ]]; then
      log_error "package '%s' not found in repo '%s-%s'" "$pkgname" "$repo" "$OPT_ARCH"
      return 1
    else
      log_error "package '%s' has no trunk directory!" "$pkgname"
      return 1
    fi
  fi

  if (( ! OPT_FORCE )); then
    # shellcheck disable=SC2154
    mkdir "$startdir/$pkgname" || return
  fi

  log_info 'exporting %s:%s' "$pkgname" "$subtree"
  git archive --format=tar "remotes/$remote/packages/$pkgname" "$subtree/" |
      tar -C "$startdir" --transform "s,^$subtree,$pkgname," -xf - "$subtree/"
}

package_checkout() {
  local remote
  pkgname=$1

  package_init "$pkgname" remote || return

  git show-ref -q "refs/heads/$remote/packages/$pkgname" ||
      git branch -qf --no-track {,}"$remote/packages/$pkgname"

  quiet_git clone "$ASPROOT" --single-branch --branch "$remote/packages/$pkgname" \
    "$startdir/$pkgname" || return

  git --git-dir="$startdir/$pkgname/.git" config pull.rebase true
}

package_get_repos_with_arch() {
  local remote=$2 path arch repo
  pkgname=$1

  while read -r path; do
    IFS=/- read -r _ repo arch <<<"$path"
    printf '%s %s\n' "$repo" "$arch"
  done < <(git ls-tree --name-only "remotes/$remote/packages/$pkgname" repos/)
}

package_get_arches() {
  local remote arch
  declare -A arches
  pkgname=$1

  package_init "$pkgname" remote || return

  while read -r _ arch; do
    arches["$arch"]=1
  done < <(package_get_repos_with_arch "$pkgname" "$remote")

  printf '%s\n' "${!arches[@]}"
}

package_get_repos() {
  local remote repo
  declare -A repos
  pkgname=$1

  package_init "$pkgname" remote || return

  while read -r repo _; do
    repos["$repo"]=1
  done < <(package_get_repos_with_arch "$pkgname" "$remote")

  printf '%s\n' "${!repos[@]}"
}

package_untrack() {
  local remote=$2
  pkgname=$1

  if git show-ref -q "refs/heads/$remote/packages/$pkgname"; then
    git branch -D "$remote/packages/$pkgname"
  fi
}
