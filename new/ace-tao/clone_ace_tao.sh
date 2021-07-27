#!/bin/bash
set -e
cd "%dest%"
git clone git@github.com:iguessthislldo/ACE_TAO.git
cd "ACE_TAO"
git remote add upstream git@github.com:DOCGroup/ACE_TAO.git
gitid use work
