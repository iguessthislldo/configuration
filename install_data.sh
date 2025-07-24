#!/usr/bin/env bash

set -e

if [ -t 2 ]
then
    red_bold=`tput bold setaf 1`
    reset=`tput sgr0`
else
    red_bold=""
    reset=""
fi

function error {
    printf "%sERROR:%s %s\n" "$red_bold" "$reset" "$1" 1>&2
}

function fatal_error {
    error "$1"
    exit 1
}

function if_to_var {
    if [ $@ ]
    then
        echo true
    else
        echo false
    fi
}

function defined_to_var {
    local name=$1
    local -n name_ref=$name
    if_to_var ! -z ${name_ref+x}
}

function set_var {
    local name=$1
    local defined=`defined_to_var $name`
    local type=$2
    local -n ref=$name
    local value=$ref
    if ! $defined
    then
        value=$3
    fi
    case $type in
        path)
            if [ -z "${value}" ]
            then
                fatal_error "$name can't be empty or unset"
            fi
            value=`realpath -s $value`
            ;;
        bool)
            if [[ ! $value =~ ^(true|false)$ ]]
            then
                fatal_error "$name not true or false: $value"
            fi
            ;;
    esac
    if $defined
    then
        echo "$type $name=$value"
    else
        echo "$type $name=$value (default)"
    fi
    ref="$value"
}

set_var install_data path "/data"
set_var install_home path "$HOME"
if [ -z ${XDG_CONFIG_HOME+x} ]
then
    export XDG_CONFIG_HOME="$install_home/.config"
fi
set_var install_xdg_config_home path "$XDG_CONFIG_HOME"
if [ -z ${XDG_DATA_HOME+x} ]
then
    export XDG_DATA_HOME="$install_home/.local/share"
fi
set_var install_xdg_data_home path "$XDG_DATA_HOME"
set_var install_user_dirs bool true

subscript=".install_this.sh"
install_config=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
install_config=`realpath "$install_config"`
echo "install_config=$install_config"
export_list="$(realpath -s "$install_config/export-list")"
export_file="export.txz"
export_path="$(realpath -s "$install_config/$export_file")"
doing_export=false
doing_install=false

function paths_are_same {
    a=$(readlink -f $1)
    b=$(readlink -f $2)
    test $a -ef $b
    return $?
}

function ask {
    if ${GITHUB_ACTIONS:-false}
    then
        echo "${@}? (Assuming yes because GitHub Actions)"
        return
    fi
    while true; do
        read -p "${@}? " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) error "Please answer y(es) or n(o).";;
        esac
    done
}

ask "Does it look good? Continue"

function InstallRun {
    if ! $doing_install
    then
        return
    fi
    echo "---- InstallRun $@"
    $@
    echo "---- Done: $?"
}

function InstallLink {
    if ! $doing_install
    then
        return
    fi
    echo -n "---- InstallLink $@ ... "
    file="$PWD"
    while [[ $# -gt 0 ]]
    do
        case $1 in
            --file)
                file=`realpath -s $2`
                shift
                shift
                ;;
            --home)
                link="$install_home/$2"
                shift
                shift
                ;;
            --xdg)
                link="$install_xdg_config_home/$2"
                shift
                shift
                ;;
            --xdg-data)
                link="$install_xdg_data_home/$2"
                shift
                shift
                ;;
            *)
                fatal_error "Unknown option $1"
                ;;
        esac
    done
    if [ -z "$link" ]
    then
        fatal_error "Need --home or --xdg"
    fi
    dirname=$(dirname "$link")
    if [ ! -d "$dirname" ]
    then
        mkdir -p "$dirname"
    fi
    if [ -e "$link" ]
    then
        if paths_are_same "$file" "$link"
        then
            echo "Already Done"
            return 0
        fi
        error "File/Directory already exists: $link"
        if ask "Remove existing $link"
        then
            rm -fr "$link"
        elif ask "Skip installing $link"
        then
            echo "Skipped"
            return 0
        else
            fatal_error "alright, can't continue"
        fi
    fi
    ln -s "$file" "$link"
    echo "Done"
}

function InstallFile {
    if ! $doing_install
    then
        return
    fi
    echo -n "---- InstallFile $@ ... "
    src=`realpath $1`
    dest="$install_home/$2"
    if [ -e "$dest" ]
    then
        if paths_are_same "$src" "$dest"
        then
            echo "Already Done"
            return 0
        fi
        if cmp "$src" "$dest"
        then
            echo "Already Done"
            return 0
        fi
        error "File/Directory already exists: $dest"
        if ask "Remove existing $dest"
        then
            rm -fr "$dest"
        elif ask "Skip installing $dest"
        then
            echo "Skipped"
            return 0
        else
            fatal_error "alright, can't continue"
        fi
    fi
    cp "$src" "$dest"
    echo "Done"
}

function InstallDir {
    if ! $doing_install
    then
        return
    fi
    echo -n "---- InstallDir $@ ... "
    mkdir -p $install_home/$1 || exit 1
    echo "Done"
}

function ExportFiles {
    if ! $doing_export
    then
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

    # Make sure XDG_CONFIG_HOME and XDG_DATA_HOME exist
    mkdir -p "$install_xdg_config_home"
    mkdir -p "$install_xdg_data_home"

    # Install Data Directory
    cd $install_data
    InstallLink --home dat
    InstallDir bin
    if $install_user_dirs
    then
        mkdir -p downloads
        InstallLink --file downloads --home dl
        mkdir -p documents
        InstallLink --file documents --home docs
        mkdir -p music
        InstallLink --file music --home music
        mkdir -p pictures
        InstallLink --file pictures --home pics
        mkdir -p videos
        InstallLink --file videos --home vids
        mkdir -p src
        InstallLink --file src --home src
        mkdir -p dev
        InstallLink --file dev --home dev
        mkdir -p work
        InstallLink --file work --home work
    fi

    # Install Configuration Directory
    cd $install_config
    source .install_this.sh

    # If we can ssh to the repo, set the origin of the configuration repo to
    # use ssh.
    ssh_to=git@github.com
    ssh -qT $ssh_to || ssh_status=$?
    if [ $ssh_status -ne 255 ]
    then
        echo 'Making sure git origin is SSH'
        cd $install_config
        origin="$ssh_to:iguessthislldo/configuration.git"
        if [ "$(git remote get-url origin)" != "$origin" ]
        then
            git remote set-url origin $origin
        else
            echo "Already set to $origin"
        fi
    fi
}

function action_export {
    echo Exporting \"$install_data\" to \"$install_home\"

    doing_export=true
    rm -f $export_list $export_path
    cd $install_data
    Scan
    tar --create --xz --file $export_path --files-from $export_list
}

function action_import {
    if [ ! -z "$1" ]
    then
        echo "Importing from $1"
        ssh $1 'bash $CONFIG/install_data.sh export'
        scp $1:$install_config/$export_file $install_data
    fi
    cd $install_data
    if [ ! -f "$export_file" ]
    then
        fatal_error "$export_file not found in `pwd`"
    fi
    tar xf "$export_file"
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
        echo "install_data.sh import [SSH_ARGS]"
        ;;
    *)
        fatal_error "Invalid action \"$action\""
        ;;
esac
