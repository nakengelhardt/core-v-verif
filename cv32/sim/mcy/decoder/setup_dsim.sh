#!/bin/bash

set -e

source params.sh

cd database/setup
ln -f -s ../../setup_dsim.mk Makefile

make corev-dv

for PROG in $CUSTOM_PROGS $PULP_CUSTOM_PROGS ; do
make CUSTOM_PROG=$PROG custom-$PROG.hex custom-$PROG.elf
done

for PROG in $ASM_PROGS ; do
make asm-$PROG.hex asm-$PROG.elf
done
