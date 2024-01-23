#!/usr/bin/env bash
set -e

source "%dest%/setenv.sh"

cd "%dest%/OpenDDS"
makej "$@"
