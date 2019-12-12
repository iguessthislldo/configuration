function igtd_sh_config_loader { # LOCATION
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
    for f in $(find "$1" "${find_args[@]}" | sort)
    do
        if [ -z ${IGTD_SH_CONFIG_LOADER_DEBUG+x} ]
        then
            source $f
        else
            echo $f
        fi
    done
}
