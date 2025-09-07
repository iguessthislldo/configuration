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

if $IS_ZSH
then
    # Provide EPOCHREALTIME
    zmodload zsh/datetime
fi

function igtd_time_now {
    printf "%d\n" $(($(printf "%.3f\n" $EPOCHREALTIME) * 1000))
}

function igtd_print_time {
    local name=$1
    local number=$2
    local after=${3- }
    if [ $number -gt 0 ]
    then
        local s='s'
        if [ $number -eq 1 ]
        then
            s=''
        fi
        printf '%d %s%s%s' $number $name $s "$after"
    fi
}

function igtd_humanize_millsec {
    local total_milliseconds=$1
    igtd_print_time day $((total_milliseconds/1000/60/60/24))
    igtd_print_time hour $((total_milliseconds/1000/60/60%24))
    igtd_print_time minute $((total_milliseconds/1000/60%60))
    igtd_print_time second $((total_milliseconds/1000%60))
    igtd_print_time millisecond $((total_milliseconds%1000)) ''
}

IGTD_CMD_TIME_BEGIN=$(igtd_time_now)

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

function igtd_defined {
    eval "[ ! -z \${$1+x} ]"
}

read IGTD_PROC_VERSION < /proc/version

function igtd_proc_version_has {
    local name="$1"
    if igtd_defined $name
    then
        return
    fi
    local regex="$2"
    local value
    eval "[[ \$IGTD_PROC_VERSION =~ \$regex ]] && value=true || value=false"
    # echo $name=$value
    eval "export $name=$value"
}

igtd_proc_version_has IGTD_LINUX '[Ll]inux'
igtd_proc_version_has IGTD_WSL '[Mm]icrosoft.*WSL2'
igtd_proc_version_has IGTD_MSYS2 'MINGW64_NT'

if [ -f $CONFIG/machine_id.local.sh ]
then
    source $CONFIG/machine_id.local.sh
fi
if [ -z ${IGTD_MACHINE_ID+x} ]
then
    if [ -f /etc/machine-id ]
    then
        read IGTD_MACHINE_ID < /etc/machine-id
        export IGTD_MACHINE_ID
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

    local f
    local configs=($CONFIG/sh/config-for-*.sh)
    for f in "${configs[@]}"
    do
        local line
        read line < "$f"
        if [ "$line" = "# config for $IGTD_MACHINE_ID" ]
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
