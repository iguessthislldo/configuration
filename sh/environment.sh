function igtd_cmd_time_now {
    echo $(($(date +%s%N)/1000000))
}

IGTD_CMD_TIME_BEGIN=$(igtd_cmd_time_now)

if [ -z ${DATA+x} ]
then
    export DATA=/data
fi

if [ -z ${CONFIG+x} ]
then
    export CONFIG=$DATA/configuration
fi

if [ -z ${XDG_CONFIG_HOME+x} ]
then
    export XDG_CONFIG_HOME="$IGTD_XDG_CONFIG_HOME"
fi

if [ -z ${XDG_DATA_HOME+x} ]
then
    export XDG_DATA_HOME="$IGTD_XDG_DATA_HOME"
fi

if [ -z ${ZSH_VERSION+x} ]
then
    export IS_ZSH=false
else
    export IS_ZSH=true
fi

if [ -z ${BASH_VERSION+x} ]
then
    export IS_BASH=false
else
    export IS_BASH=true
fi

if [ -f $CONFIG/machine_id.local.sh ]
then
    source $CONFIG/machine_id.local.sh
fi
if [ -z ${IGTD_MACHINE_ID+x} ]
then
    if [ -f /etc/machine-id ]
    then
        export IGTD_MACHINE_ID=$(cat /etc/machine-id)
    elif [ -n "${HOST}" ]
    then
        export IGTD_MACHINE_ID="${HOST}"
    elif [ -n "${HOSTNAME}" ]
    then
        export IGTD_MACHINE_ID="${HOSTNAME}"
    else
        export IGTD_MACHINE_ID="unknown"
        echo "Couldn't get something for IGTD_MACHINE_ID, using \"$IGTD_MACHINE_ID\""
    fi
fi

function igtd_add_to_path {
    if [[ ":$PATH:" != *":$1:"* ]]
    then
        export PATH="$1:$PATH"
    fi
}

source "$CONFIG/sh/igtd_sh_loader.sh"
function igtd_sh_source_config {
    if [ -z ${IGTD_SH_LOADER_DEBUG+x} ]
    then
        local IGTD_SH_LOADER_DEBUG=false
    fi

    local f
    for f in $(find $CONFIG/sh/ -name 'config-for-*')
    do
        if grep -q "# config for $IGTD_MACHINE_ID" $f
        then
            if $IGTD_SH_LOADER_DEBUG
            then
                echo $f
            fi
            source $f
        fi
    done
}
igtd_sh_source_config
igtd_sh_loader "$CONFIG/sh/environment.d"
unset -f igtd_sh_source_config igtd_sh_loader igtd_add_to_path
