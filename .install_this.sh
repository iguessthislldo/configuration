#!/bin/bash

if ! $complete_install
then
    cp sh/rc.sh $HOME/.zshrc
    cp sh/env.sh $HOME/.zshenv
    return
fi

InstallLink cfg

# Flox
InstallLink flox .flox

# zsh
InstallLink sh/rc.sh .zshrc
InstallLink sh/environment.sh .zshenv

# neovim
InstallLink vim .config/nvim

# ptpython
#InstallLink ptpython.py .config/ptpython/config.py

InstallLink tmux .tmux.conf

InstallLink gdb .config/gdb

InstallLink user-dirs.dir .config/user-dirs.dirs

Scan
