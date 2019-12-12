export DATA=/data
export CONFIG=$DATA/configuration

for f in $(find $CONFIG/sh/environment.d -name '*.sh')
do
    source $f
done

if $IS_ZSH
then
    for f in $(find $CONFIG/sh/environment.d -name '*.zsh')
    do
        source $f
    done
fi

if $IS_BASH
then
    for f in $(find $CONFIG/sh/environment.d -name '*.bash')
    do
        source $f
    done
fi

unset f
