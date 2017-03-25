archweb_get_pkgbase() {
  local pkgbase

  pkgbase=$(curl -s "https://www.archlinux.org/packages/search/json/?q=$1" |
    jq -r --arg pkgname "$1" 'limit(1; .results[] | select(.pkgname == $pkgname).pkgbase)')
  [[ $pkgbase ]] || return 1

  printf '%s\n' "$pkgbase"
}
