function alias-if {
    local alias_name="$1"
    shift
    while (( "$#" ))
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

alias-if o xdg-open start
alias-if p ptipython3 ipython python3 'py -3' python

alias l="ls --color=always --classify --group-directories-first"
alias cl="clear && l"
alias la="l --almost-all"
alias ll="la -l --si"

alias gdiff="git diff --no-index"
alias giff="gdiff"
