#!/bin/bash
set -e

source "%dest%/setenv.sh"

cd "%dest%/OpenDDS"
makej opendds_idl
makej -t
