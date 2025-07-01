if command -v xdg-open &> /dev/null
then
    alias o="xdg-open"
fi

if ! command -v py &> /dev/null
then
    if command -v ptpython3 &> /dev/null
    then
        alias py="ptpython3"
    elif command -v ipython &> /dev/null
    then
        alias py="ipython"
    elif command -v python3 &> /dev/null
    then
        alias py="python3"
    elif command -v python &> /dev/null
    then
        alias py="python"
    fi
fi

alias l="ls --color=always --classify --group-directories-first"
alias cl="clear && l"
alias la="l --almost-all"
alias ll="la -l --si"

alias gdiff="git diff --no-index"
alias giff="gdiff"
