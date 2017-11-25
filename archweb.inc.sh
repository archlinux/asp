archweb_get_pkgbase() {
  curl -s "https://www.archlinux.org/packages/search/json/?q=$1" |
    jq -er --arg pkgname "$1" 'limit(1; .results[] | select(.pkgname == $pkgname).pkgbase)'
}
