function preexec() {
    IGTD_CMD_TIME_BEGIN=$(($(date +%s%N)/1000000))
}

function print_time {
    local name=$1
    local number=$2
    local after=${3- }
    if [ $number -gt 0 ]
    then
        local s='s'
        if [ $number -eq 1 ]
        then
            s=''
        fi
        printf '%d %s%s%s' $number $name $s "$after"
    fi
}

function humanize_millsec {
    local total_milliseconds=$1
    print_time day $((total_milliseconds/1000/60/60/24))
    print_time hour $((total_milliseconds/1000/60/60%24))
    print_time minute $((total_milliseconds/1000/60%60))
    print_time second $((total_milliseconds/1000%60))
    print_time millisecond $((total_milliseconds%1000)) ''
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
        export IGTD_CMD_TIME="$(humanize_millsec $(($now-$IGTD_CMD_TIME_BEGIN)))"
        unset IGTD_CMD_TIME_BEGIN
    fi
}
