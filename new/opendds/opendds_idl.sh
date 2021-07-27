#!/bin/bash
set -e
exec bash "%dest%/run_in_env.sh" opendds_idl $@
