function igtd_sh_loader { # LOCATION
    if [ -z ${IGTD_SH_LOADER_DEBUG+x} ]
    then
        local IGTD_SH_LOADER_DEBUG=false
    fi

    if [ -z ${IGTD_SH_LOADER_VERBOSE+x} ]
    then
        local IGTD_SH_LOADER_VERBOSE=false
    fi

    local find_args=(-name '*.sh')

    if $IS_ZSH
    then
        find_args+=(-o -name '*.zsh')
    fi

    if $IS_BASH
    then
        find_args+=(-o -name '*.bash')
    fi

    local f
    local re_match
    local local_regex='\.local-for-(.*).*\.'
    for f in $(find "$1" "${find_args[@]}" | sort)
    do
        if [[ $f =~ $local_regex ]]
        then
            if $IS_ZSH
            then
                re_match="${match[1]}"
            fi

            if $IS_BASH
            then
                re_match="${BASH_REMATCH[1]}"
            fi

            if [[ $re_match != "$IGTD_OS_NICKNAME" ]]
            then
                continue
            fi
        fi
        if $IGTD_SH_LOADER_DEBUG
        then
            echo $f
        else
            if $IGTD_SH_LOADER_VERBOSE
            then
                echo $f
            fi
            source $f
        fi
    done
}
