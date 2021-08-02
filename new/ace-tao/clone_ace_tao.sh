#!/bin/bash
set -e
cd "%dest%"
if %oci_tao%
then
    git clone hornseyf@git.ociweb.com:/git/ocitao
    cd "ocitao"
else
    git clone git@github.com:iguessthislldo/ACE_TAO.git
    cd "ACE_TAO"
fi
git remote add upstream git@github.com:DOCGroup/ACE_TAO.git
gitid use work
