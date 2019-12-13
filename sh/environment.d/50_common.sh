if [ -z ${ARCHFLAGS+x} ]
then
    export ARCHFLAGS="-arch x86_64"
fi

if [ -z ${EDITOR+x} ]
then
    export EDITOR=nvim
fi

if [ -z ${LANG+x} ]
then
    export LANG=en_US.UTF-8
fi

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

if [ -z ${XDG_CONFIG_HOME+x} ]
then
    export XDG_CONFIG_HOME="$HOME/.config"
fi
