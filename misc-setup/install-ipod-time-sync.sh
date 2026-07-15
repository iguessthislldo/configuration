#!/bin/bash
set -e
sudo apt install libgpod-common
sudo install -D ipod-time-sync.policy /usr/share/polkit-1/actions/ipod-time-sync.policy
