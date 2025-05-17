#!/bin/bash

InstallLink cfg

# Flox
InstallLink flox .flox

# zsh
if $doing_install
then
    temp_file=$(mktemp)
    echo "export DATA=\"$install_data\"" > "$temp_file"
    echo "export CONFIG=\"$install_config\"" >> "$temp_file"
    echo "source \"\$CONFIG/sh/environment.sh\"" >> "$temp_file"
    InstallFile "$temp_file" .zshenv
fi
InstallLink sh/rc.sh .zshrc

# neovim
InstallLink vim .config/nvim

# ptpython
#InstallLink ptpython.py .config/ptpython/config.py

InstallLink tmux .tmux.conf

InstallLink gdb .config/gdb

InstallLink user-dirs.dir .config/user-dirs.dirs

Scan
