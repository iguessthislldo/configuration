#!/usr/bin/env bash
set -e

source "%dest%/setenv.sh"

cp ${workspace}/default.features $ACE_ROOT/bin/MakeProjectCreator/config/default.features
cp ${workspace}/platform_macros.GNU $ACE_ROOT/include/makeinclude/platform_macros.GNU
cp ${workspace}/config.h $ACE_ROOT/ace/config.h

if %build_tao%
then
    cd $TAO_ROOT
    mwc.pl -type gnuace TAO_ACE.mwc
else
    cd $ACE_ROOT
    mwc.pl -type gnuace ACE.mwc
fi
