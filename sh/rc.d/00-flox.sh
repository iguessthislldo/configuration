if command -v flox &> /dev/null
then
    if [ -z ${FLOX_ENV+x} ]
    then
        export FLOX_DISABLE_METRICS=true
        eval "$(flox activate -d ~ -m run)"
    fi
fi
