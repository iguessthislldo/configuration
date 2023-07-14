#!/bin/bash
set -ex

cd "%dest%"
git clone git@github.com:iguessthislldo/OpenDDS.git

cd "OpenDDS"
git remote add upstream git@github.com:OpenDDS/OpenDDS.git
git fetch upstream master
git merge --ff-only upstream/master
git push
git submodule init
git submodule update
gitid use work
