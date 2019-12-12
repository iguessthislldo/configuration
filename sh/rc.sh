if $IS_ZSH
then
    for f in $(find $CONFIG/sh/rc.d -name '*.zsh')
    do
        source $f
    done
fi

if $IS_BASH
then
    for f in $(find $CONFIG/sh/rc.d -name '*.bash')
    do
        source $f
    done
fi

for f in $(find $CONFIG/sh/rc.d -name '*.sh')
do
    source $f
done

unset f
