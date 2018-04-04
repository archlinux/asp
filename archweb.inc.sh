archweb_get_pkgbase() {
  curl -Gs "https://www.archlinux.org/packages/search/json/" --data-urlencode "q=$1" |
    jq -er --arg pkgname "$1" 'limit(1; .results[] | select(.pkgname == $pkgname).pkgbase)'
}
