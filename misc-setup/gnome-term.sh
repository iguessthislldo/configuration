#!/usr/bin/env bash

set -e

gsettings set org.gnome.desktop.wm.preferences audible-bell false
gsettings set org.gnome.desktop.wm.preferences visual-bell true
gsettings set org.gnome.desktop.wm.preferences visual-bell-type frame-flash

# Test
tput bel
