ZSH_CUSTOM=$CONFIG/sh/oh-my-zsh/custom
ZSH_THEME="iguessthislldo"

ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

plugins=(
    docker
    docker-compose
    fancy-ctrl-z
    fzf
    pip
    ripgrep
    sudo
    systemd
    z

    # 3rd Party
    autoupdate
    zsh-syntax-highlighting
)

export ZSH=$CONFIG/sh/oh-my-zsh/ohmyzsh
ZSH_CACHE_DIR=$CONFIG/sh/oh-my-zsh/cache/${IGTD_MACHINE_ID}
mkdir -p $ZSH_CACHE_DIR
