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

if [ -z ${LANG+x} ]
then
    export LANG=en_US.UTF-8
fi

igtd_add_to_path "$HOME/.local/bin"
igtd_add_to_path "$HOME/bin"
igtd_add_to_path "$CONFIG/bin"
