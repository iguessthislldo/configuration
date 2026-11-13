# Start up process:
# -- environment.sh (All shells)
#   -- environment.d/*
# -- profile.sh (Login shells (once))
# -> rc.sh (Interactive shells (multiple times))
#   -- rc.d/*
#
# See here for a summary of the source order of zsh:
#   https://isamert.net/2021/03/02/a-relatively-deep-dive-into-zsh-shell-login-process-without-a-display-manager-.html
#   Also see "man zsh" then "/STARTUP"

source "$CONFIG/sh/igtd_sh_loader.sh"
igtd_sh_loader "$CONFIG/sh/rc.d"
unset -f igtd_sh_loader
