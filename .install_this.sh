#!/bin/bash

InstallLink cfg

# zsh
InstallLink sh/rc.sh .zshrc
InstallLink sh/environment.sh .zshenv

# neovim
InstallLink vim .config/nvim

Scan
