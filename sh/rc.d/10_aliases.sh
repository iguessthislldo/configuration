alias r="source ~/.zshenv;source ~/.zshrc"
alias e=$EDITOR
alias p="sudo pacman"
alias o="xdg-open"
alias apt="sudo apt"
alias awk="gawk" # Always use gawk
alias s="sudo systemctl"
alias vim="nvim"
alias ipy="ipython3"

# Pager
alias P="$EDITOR -R -"
alias lP="l|P"
alias llP="ll|P"

# navigation
function u {
    if [ $# -eq 1 ]; then
        local path=''
        if [[ $1 =~ "^[0-9]+$" ]]; then
            for i in $(echo {1..$1}); do
                path="../$path"
            done
        else
            echo "Not a number: $1" 1>&2
            return 1
        fi
        cd $path
    else
        cd ..
    fi
}

alias l="ls --color=always --classify --group-directories-first"
alias cl="clear && l"
alias la="l --almost-all"
alias ll="la -l --si"