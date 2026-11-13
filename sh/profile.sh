# This is where we must set PATH and XDG_CONFIG_DIRS. On MSYS2 the unix PATH
# isn't set until the system profile is set. XDG_CONFIG_DIRS is also set in the
# system profile, so we should set it here.
#
# Start up process:
# -- environment.sh (All shells)
#   -- environment.d/*
# -> profile.sh (Login shells (once))
# -- rc.sh (Interactive shells (multiple times))
#   -- rc.d/*
#
# See here for a summary of the source order of zsh:
#   https://isamert.net/2021/03/02/a-relatively-deep-dive-into-zsh-shell-login-process-without-a-display-manager-.html
#   Also see "man zsh" then "/STARTUP"

function igtd_append {
    local name="$1"
    shift
    local current=""
    if igtd_defined "$name"
    then
        eval "current=\"\$$name\""
    fi
    # echo "igtd_append $name: BEFORE: $current"
    local val
    for val in "$@"
    do
        # echo "igtd_append $name: ADD: $val"
        local match=false
        local remaining="$current"
        while [ -n "$remaining" ]
        do
            local entry="${remaining%%:*}"
            if [ "${entry%/}" = "${val%/}" ]
            then
                match=true
                break
            fi
            if [ "$remaining" = "$entry" ]
            then
                break
            fi
            remaining="${remaining#*:}"
        done
        if ! $match
        then
            current="${current:+$current:}$val"
        fi
    done
    # echo "igtd_append $name: AFTER: $current"
    eval "export \"$name\"=\"$current\""
}

igtd_append PATH \
    "$HOME/.local/bin" \
    "$HOME/bin" \
    "$CONFIG/bin" \

igtd_append XDG_DATA_DIRS \
    /usr/local/share \
    /usr/share \

