#!/bin/bash
set -e

dir="$1"
if [ -z "$dir" -o ! -d "$dir" ]
then
    echo "Error: Invalid directory: \"$dir\"" 1>&2
    exit 1
fi

sudo chown -R $(whoami) "$dir"
sudo find "$dir" -type f | xargs -I {} chmod 600 {}
sudo find "$dir" -type d | xargs -I {} chmod 700 {}
