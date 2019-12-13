ZSH_CUSTOM=$CONFIG/sh/oh-my-zsh/custom
ZSH_THEME="iguessthislldo"

ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

plugins=(cake new docker pip sudo systemd zsh_reload)

export ZSH=$CONFIG/sh/oh-my-zsh/ohmyzsh
ZSH_CACHE_DIR=$CONFIG/sh/oh-my-zsh/cache/${IGTD_MACHINE_ID}
mkdir -p $ZSH_CACHE_DIR
source $ZSH/oh-my-zsh.sh
