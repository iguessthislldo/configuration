#!/bin/bash
set -e
source "%dest%/setenv.sh"
if %build_tao%
then
    cd $TAO_ROOT
else
    cd $ACE_ROOT
fi
makej "$@"
