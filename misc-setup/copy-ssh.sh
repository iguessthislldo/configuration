#!/bin/bash

dot_ssh="$HOME/.ssh"
if [ ! -d "$dot_ssh" ]
then
    echo "Error: $dot_ssh does not exist" 1>&2
    exit 1
fi

dot_ssh_old="$HOME/.ssh-old"
if [ -e "$dot_ssh_old" ]
then
    echo "Error: $dot_ssh_old already exists!" 1>&2
    exit 1
fi

mv "$dot_ssh" "$dot_ssh_old"
cp -r "$CONFIG/ssh" "$dot_ssh"
"$CONFIG/misc-setup/exclusive-perms.sh" "$dot_ssh"
