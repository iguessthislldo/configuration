#!/bin/bash
set -e

cd "%dest%/OpenDDS"

./configure \
 --no-backup \
 --mpc "%mpc%" \
 --ace "%ace%" \
 --no-tests \

