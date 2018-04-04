log_meta() {
  printf "$1 $2\\n" "${@:3}"
}

log_error() {
  log_meta 'error:' "$@" >&2
}

log_fatal() {
  log_error "$@"
  exit 1
}

log_warning() {
  log_meta 'warning:' "$@" >&2
}

log_info() {
  log_meta '==>' "$@"
}

map() {
  local map_r=0
  for _ in "${@:2}"; do
    "$1" "$_" || map_r=1
  done
  return $map_r
}

in_array() {
  local item needle=$1

  for item in "${@:2}"; do
    [[ $item = "$needle" ]] && return 0
  done

  return 1
}

quiet_git() {
  [[ $ASP_GIT_QUIET ]] && set -- "$1" -q "${@:2}"

  command git "$@"
}
