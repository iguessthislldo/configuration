function u {
    if [ $# -eq 1 ]; then
        local path=''
        if [[ $1 =~ "^[0-9]+$" ]]; then
            for i in $(echo {1..$1}); do
                path="../$path"
            done
        else
            echo "Not a number: $1" 1>&2
            return 1
        fi
        cd $path
    else
        cd ..
    fi
}
