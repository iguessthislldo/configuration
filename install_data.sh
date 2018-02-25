#!/bin/bash

set -e

subscript=".install_this.sh"
install_data="$(realpath -s /data)"
install_home="$(realpath -s $HOME)"
echo Installing from \"$install_data\" to \"$install_home\"

function paths_are_same {
    a=$(readlink -f $1)
    b=$(readlink -f $2)
    test $a -ef $b
    return $?
}

function Run {
    echo "    Run $@"
}

function Link {
    echo -n "    Link $@ ... "
    if [ $# -eq 1 ]; then
        file=$PWD
        link=$install_home/$1
    else
        file=$PWD/$1
        link=$install_home/$2
    fi
    if [ -e $link ]; then
        if ! paths_are_same $file $link ; then
            echo "Error: File/Directory already exists: $link" 1>&2
            exit 1
        else
            echo "Already Done"
        fi
    else
        ln -s $file $link
        echo "Done"
    fi
}

function Dir {
    echo -n "    Dir $@ ... "
    mkdir -p $install_home/$1 || exit 1
    echo "Done"
}

function Scan {
    echo "    Scanning $PWD"
    for i in $(find -L $PWD -xdev -mindepth 2 -maxdepth 2 -type f -wholename '*/'$subscript)
    do
        dir=$(dirname $i)
        echo "Entering $dir"
        pushd $dir &> /dev/null
        source $i
        popd &> /dev/null
    done
}

cd $install_data
Link dat
Scan
