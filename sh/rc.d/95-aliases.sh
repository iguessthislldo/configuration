function alias-if {
    local alias_name="$1"
    shift
    while (( $# ))
    do
        local command="$1"
        shift
        local command_name=$(echo "$command"| cut -d " " -f1)
        if command -v "$command_name" &> /dev/null
        then
            alias "$alias_name=$command"
            break
        fi
    done
}

if $IGTD_WSL; then
    wsl-open() {
        local target="$1"
        [ -e "$target" ] && target="$(readlink -f "$target")"
        powershell.exe -c Start "$(wslpath -w "$target")"
    }
fi
alias-if o xdg-open wsl-open start
alias-if p ptipython3 ipython python3 'py -3' python

alias l="ls --color=always --classify --group-directories-first"
alias cl="clear && l"
alias la="l --almost-all"
alias ll="la -l --si"

# From ignored "directories" aliases in OMZ
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

alias gdiff="git diff --no-index"
alias giff="gdiff"
