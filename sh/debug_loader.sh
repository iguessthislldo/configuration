source "$CONFIG/sh/igtd_sh_config_loader.sh"
export IGTD_SH_CONFIG_LOADER_DEBUG=true
igtd_sh_config_loader "$CONFIG/sh/environment.d"
igtd_sh_config_loader "$CONFIG/sh/rc.d"
