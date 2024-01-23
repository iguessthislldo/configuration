#!/usr/bin/env bash
set -e

source "%dest%/setenv.sh"

if [ ! -z ${D+x} ]
then
  exec gdb -x ${workspace}/idl.gdb --args tao_idl $@
fi

if [ ! -z ${V+x} ]
then
  exec valgrind --leak-check=full tao_idl $@
fi

exec tao_idl $@
