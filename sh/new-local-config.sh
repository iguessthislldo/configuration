#!/bin/bash

if [ -z ${IGTD_MACHINE_ID+x} ]
then
    echo "Error: IGTD_MACHINE_ID isn't defined" 1>&2
    exit 1
fi

if [ -z ${1+x} ]
then
    echo "Error: pass nickname" 1>&2
    exit 1
fi

path="$CONFIG/sh/config-for-$1.sh"
if [ -f "$path" ]
then
    echo "Error: $path already exists" 1>&2
    exit 1
fi

echo "# config for ${IGTD_MACHINE_ID}\n\nexport IGTD_OS_NICKNAME=${1}" > "$path"
