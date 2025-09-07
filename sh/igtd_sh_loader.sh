function igtd_sh_loader { # LOCATION
    local dir="$1"

    if $IS_ZSH
    then
        setopt null_glob
    fi
    if $IS_BASH
    then
        shopt -s nullglob
    fi

    if [ -z ${IGTD_SH_LOADER_DEBUG+x} ]
    then
        local IGTD_SH_LOADER_DEBUG=false
    fi

    if [ -z ${IGTD_SH_LOADER_VERBOSE+x} ]
    then
        local IGTD_SH_LOADER_VERBOSE=false
    fi

    local -a files
    if $IS_ZSH
    then
        files=($dir/*.{sh,zsh})
    fi
    if $IS_BASH
    then
        files=($dir/*.{sh,bash})
    fi

    local f
    local re_match
    local local_regex='\.local-for-(.*).*\.'
    for f in "${files[@]}"
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
                echo ">>>>>>>>>> $f"
                local before_source=$(igtd_time_now)
            fi

            source $f

            if $IGTD_SH_LOADER_VERBOSE
            then
                local after_source=$(igtd_time_now)
                echo "----- $(igtd_humanize_millsec $(($after_source-$before_source)))"
            fi
        fi
    done
}
