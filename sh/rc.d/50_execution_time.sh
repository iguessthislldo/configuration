function preexec() {
    IGTD_CMD_TIME_BEGIN=$(($(date +%s%N)/1000000))
}

function precmd() {
    local exit_status=$?

    if [ $IGTD_CMD_TIME_BEGIN ]
    then
        if [ $exit_status -ne 0 ]
        then
            export IGTD_CMD_EXIT_STATUS=$exit_status
        else
            unset IGTD_CMD_EXIT_STATUS
        fi

        local now=$(($(date +%s%N)/1000000))
        export IGTD_CMD_TIME=$(($now-$IGTD_CMD_TIME_BEGIN))
        unset IGTD_CMD_TIME_BEGIN
    fi
}
