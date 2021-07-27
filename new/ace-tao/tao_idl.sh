#!/bin/bash
set -e
if [ -z ${ACE_ROOT+x} ]
then
  source "%dest%/setenv.sh"
fi

if [ ! -z ${D+x} ]
then
  exec gdb -x ${workspace}/idl.gdb --args tao_idl $@
fi

if [ ! -z ${V+x} ]
then
  exec valgrind --leak-check=full tao_idl $@
fi

exec tao_idl $@
