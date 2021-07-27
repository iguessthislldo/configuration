#!/bin/bash
set -e
cd "%dest%/OpenDDS"
make -j 10 opendds_idl
make -t -j 10
