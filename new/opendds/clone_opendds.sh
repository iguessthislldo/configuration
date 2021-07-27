#!/bin/bash
set -e
cd "%dest%"
git clone git@github.com:iguessthislldo/OpenDDS.git
cd "OpenDDS"
git remote add upstream git@github.com:objectcomputing/OpenDDS.git
git submodule init
git submodule update
gitid use work
