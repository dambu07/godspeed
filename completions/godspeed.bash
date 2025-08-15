#!/bin/bash
_godspeed() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="setup-global install go build deploy template ai search status stop logs doctor update --help --version"

    case "${prev}" in
        template)
            COMPREPLY=( $(compgen -W "react vue angular laravel fastapi flutter" -- ${cur}) )
            return 0
            ;;
        ai)
            COMPREPLY=( $(compgen -W "configure chat" -- ${cur}) )
            return 0
            ;;
        logs)
            COMPREPLY=( $(compgen -W "error ai all" -- ${cur}) )
            return 0
            ;;
        *)
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _godspeed godspeed
