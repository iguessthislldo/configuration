#!/usr/bin/env bash

set -e

subscript=".install_this.sh"
install_data="$(realpath -s /data)"
install_cfg="$(realpath -s $install_data/configuration)"
install_home="$(realpath -s $HOME)"
export_list="$(realpath -s "$install_cfg/export-list")"
export_txz="$(realpath -s "$install_cfg/export.txz")"
doing_export=false
doing_install=false

function paths_are_same {
    a=$(readlink -f $1)
    b=$(readlink -f $2)
    test $a -ef $b
    return $?
}

function ask {
    while true; do
        read -p "${@}? " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer y(es) or n(o).";;
        esac
    done
}

function InstallRun {
    if ! $doing_install ; then
        return
    fi
    echo "---- InstallRun $@"
    $@
    echo "---- Done: $?"
}

function InstallLink {
    if ! $doing_install ; then
        return
    fi
    echo -n "---- InstallLink $@ ... "
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
            if ask "Remove existing $link" ; then
                rm -fr "$link"
            else
                exit 1
            fi
        else
            echo "Already Done"
            return 0
        fi
    fi
    ln -s $file $link
    echo "Done"
}

function InstallDir {
    if ! $doing_install ; then
        return
    fi
    echo -n "---- InstallDir $@ ... "
    mkdir -p $install_home/$1 || exit 1
    echo "Done"
}

function ExportFiles {
    if ! $doing_export ; then
        return
    fi
    echo "---- Has Exportable Files $1"
    bash -c "find $@ -exec realpath --relative-to \"$install_data\" '{}' \;" \
        | tee --append $export_list
}

function Scan {
    echo "---- Scanning $PWD"
    for i in $(find -L $PWD -xdev -mindepth 2 -maxdepth 2 -type f -wholename '*/'$subscript)
    do
        dir=$(dirname $i)
        echo "==== Entering $dir"
        pushd $dir &> /dev/null
        source $i
        popd &> /dev/null
    done
}

function action_install {
    echo Installing from \"$install_data\" to \"$install_home\"

    doing_install=true
    cd $install_data
    InstallLink dat

    InstallDir bin

    mkdir -p downloads
    InstallLink downloads dl
    mkdir -p documents
    InstallLink documents docs
    mkdir -p music
    InstallLink music music
    mkdir -p pictures
    InstallLink pictures pics
    mkdir -p videos
    InstallLink videos vids
    mkdir -p src
    InstallLink src src
    mkdir -p dev
    InstallLink dev dev
    mkdir -p work
    InstallLink work work

    Scan

    cd $install_cfg
    echo 'Make sure git origin is SSH'
    origin='git@github.com:iguessthislldo/configuration.git'
    if [ "$(git remote get-url origin)" != "$origin" ]
    then
        git remote set-url origin $origin
    else
        echo "Already set to $origin"
    fi
}

function action_export {
    echo Exporting \"$install_data\" to \"$install_home\"

    doing_export=true
    rm -f $export_list $export_txz
    cd $install_data
    Scan
    tar --create --xz --file $export_txz --files-from $export_list
}

function action_import {
    echo Importing from $1
    ssh $1 'bash /data/configuration/install_data.sh export'
    scp $1:/data/configuration/export.txz /data
    cd /data
    tar xf export.txz
}

if [ "$#" == 0 ]
then
    action="install"
else
    action="$1"
    shift
fi

case $action in
    install)
        action_install
        ;;
    export)
        action_export
        ;;
    import)
        action_import $@
        ;;
    help | "--help" | "-h")
        echo "install_data.sh [install]"
        echo "install_data.sh export"
        echo "install_data.sh import SSH_ARGS"
        ;;
    *)
        echo "Invalid action \"$action\""
        exit 1
        ;;
esac
