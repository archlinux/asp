#!/bin/bash

in_array() {
  for _ in "${@:2}"; do
    [[ $_ = "$1" ]] && return 0
  done
  return 1
}

_asp() {
  local verb='' i cur prev comps

  _get_comp_words_by_ref cur prev

  # top level commands
  local -A verbs=(
    [ALL_PACKAGES]='checkout difflog export list-arches list-repos log shortlog show ls-files'
    [LOCAL_PACKAGES]='untrack update'
    [NONE]='disk-usage gc help list-all list-local'
    [PROTO]='set-git-protocol'
  )

  # flags
  local -A opts=(
    [UNKNOWN]='-a'
    [NONE]='-f -h -V'
  )

  if in_array "$prev" ${opts[UNKNOWN]}; then
    return 0
  fi

  if [[ $cur = -* ]]; then
    COMPREPLY=( $(compgen -W '${opts[*]}' -- "$cur") )
    return 0
  fi

  # verb completion
  for (( i = 0; i < ${#COMP_WORDS[@]}; ++i )); do
    word=${COMP_WORDS[i]}
    if in_array "$word" ${verbs[ALL_PACKAGES]}; then
      verb=$word
      comps=$(ASP_GIT_QUIET=1 \asp list-all | sed 's,.*/,,')
      break
    elif in_array "$word" ${verbs[LOCAL_PACKAGES]}; then
      verb=$word
      comps=$(ASP_GIT_QUIET=1 \asp list-local | sed 's,.*/,,')
      break
    elif in_array "$word" ${verbs[PROTO]}; then
      verb=$word
      comps='git http https'
      break
    elif in_array "$word" ${verbs[NONE]}; then
      verb=$word
      break
    fi
  done

  # sub-verb completion
  case $verb in
    show)
      if (( i < ${#COMP_WORDS[@]} - 2 )); then
        comps=$(ASP_GIT_QUIET=1 \asp ls-files "${COMP_WORDS[i+1]}" 2>/dev/null)
      fi
      ;;
    '')
      comps=${verbs[*]}
      ;;
  esac

  if [[ $comps ]]; then
    COMPREPLY=( $(compgen -W '$comps' -- "$cur") )
  fi
}

complete -F _asp asp
