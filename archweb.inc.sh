archweb_get_pkgbase() {
  local pkgbase

  pkgbase=$(curl -Gs 'https://www.archlinux.org/packages/search/json/' --data-urlencode "q=$1" |
      jq -r --arg pkgname "$1" 'limit(1; .results[] | select(.pkgname == $pkgname).pkgbase)')
  [[ $pkgbase ]] || return

  printf '%s\n' "$pkgbase"
}
