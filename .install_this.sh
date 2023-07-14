#!/bin/bash

InstallLink cfg

# zsh
InstallLink sh/rc.sh .zshrc
InstallLink sh/environment.sh .zshenv

# neovim
InstallLink vim .config/nvim

# ptpython
InstallLink ptpython.py .config/ptpython/config.py

InstallLink tmux .tmux.conf

Scan
