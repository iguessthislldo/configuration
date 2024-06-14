if [ -z ${IGTD_WSL+x} ]
then
    if [[ $(grep -i microsoft /proc/version) ]]
    then
        export IGTD_WSL=true
    else
        export IGTD_WSL=false
    fi
fi
