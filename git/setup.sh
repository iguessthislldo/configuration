#!/usr/bin/env bash

git config --global core.excludesfile $CONFIG/git/global_ignore
git config --global push.autosetupremote true
git config --global init.defaultBranch main
git config --global merge.conflictstyle zdiff3

git config --global user.useConfigOnly true

git config --global --unset user.name
git config --global --unset user.email
git config --global --unset user.signingkey

git config --global commit.gpgsign true

# TODO: the loader sees .install_this.sh
source "$CONFIG/sh/igtd_sh_loader.sh"
igtd_sh_loader "$CONFIG/git/identities.d"
unset -f igtd_sh_loader
