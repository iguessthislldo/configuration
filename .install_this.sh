#!/bin/bash

InstallLink --home cfg

# Flox
InstallLink --file flox --home .flox

# zsh
if $doing_install
then
    temp_file=$(mktemp)
    echo "export DATA=\"$install_data\"" > "$temp_file"
    echo "export CONFIG=\"$install_config\"" >> "$temp_file"
    echo "export IGTD_XDG_CONFIG_HOME=\"$install_xdg_config_home\"" >> "$temp_file"
    echo "export IGTD_XDG_DATA_HOME=\"$install_xdg_data_home\"" >> "$temp_file"
    if [ ! -z ${MSYS+x} ]
    then
        echo "export MSYS=\"$MSYS\"" >> "$temp_file"
    fi
    echo "source \"\$CONFIG/sh/environment.sh\"" >> "$temp_file"
    InstallFile "$temp_file" .zshenv
fi
InstallLink --file sh/rc.sh --home .zshrc

# neovim
InstallLink --file vim --xdg nvim

# ptpython
InstallLink --file ptpython.py --xdg ptpython/config.py

InstallLink --file tmux --home .tmux.conf

InstallLink --file gdb --xdg gdb

if $install_user_dirs
then
    InstallLink --file user-dirs.dir --xdg user-dirs.dirs
fi

Scan
