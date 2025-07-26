function preexec() {
    IGTD_CMD_TIME_BEGIN=$(igtd_time_now)
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

        local now=$(igtd_time_now)
        export IGTD_CMD_TIME="$(igtd_humanize_millsec $(($now-$IGTD_CMD_TIME_BEGIN)))"
        unset IGTD_CMD_TIME_BEGIN
    fi
}
