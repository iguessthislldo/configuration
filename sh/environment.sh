export DATA=/data
export CONFIG=$DATA/configuration

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

source "$CONFIG/sh/igtd_sh_config_loader.sh"
igtd_sh_config_loader "$CONFIG/sh/environment.d"
unset -f igtd_sh_config_loader
