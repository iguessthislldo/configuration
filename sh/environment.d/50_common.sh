if [ -z ${EDITOR+x} ]
then
    export EDITOR=nvim
fi

if [ -z ${IGTD_EDITOR_IS_VI+x} ]
then
    if [[ $EDITOR =~ 'vi' ]]
    then
        export IGTD_EDITOR_IS_VI=true
    else
        export IGTD_EDITOR_IS_VI=false
    fi
fi

if [ -z ${IGTD_EDITOR_IS_NEOVIM+x} ]
then
    if [[ $EDITOR =~ 'nvim' ]]
    then
        export IGTD_EDITOR_IS_NEOVIM=true
    else
        export IGTD_EDITOR_IS_NEOVIM=false
    fi
fi

if [ -z ${LANG+x} ]
then
    export LANG=en_US.UTF-8
fi
