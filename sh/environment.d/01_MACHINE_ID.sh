if [ -z ${MACHINE_ID+x} ]
then
    export MACHINE_ID=$(cat /etc/machine-id)
fi
