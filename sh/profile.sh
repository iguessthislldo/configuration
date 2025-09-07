# This is just for setting PATH, see environment.sh for why.

function igtd_add_to_path {
    if [[ ":$PATH:" != *":$1:"* ]]
    then
        export PATH="$1:$PATH"
    fi
}

igtd_add_to_path "$HOME/.local/bin"
igtd_add_to_path "$HOME/bin"
igtd_add_to_path "$CONFIG/bin"

unset -f igtd_add_to_path
