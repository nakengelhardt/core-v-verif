#!/bin/bash

set -e

source params.sh

PROJ_ROOT_DIR=$PWD/../../../..

cd database/setup

MAKEFILE=../../setup_dsim.mk
MAKE_PATH=$PROJ_ROOT_DIR/cv32/sim/uvmt_cv32/
MAKEFLAGS="PROJ_ROOT_DIR=$PROJ_ROOT_DIR MAKE_PATH=$MAKE_PATH"

make -f $MAKEFILE $MAKEFLAGS corev-dv

make -f $MAKEFILE $MAKEFLAGS firmware.hex firmware.elf

for PROG in $CUSTOM_PROGS ; do
make -f $MAKEFILE $MAKEFLAGS custom-$PROG.hex custom-$PROG.elf
done

for PROG in $ASM_PROGS ; do
make -f $MAKEFILE $MAKEFLAGS asm-$PROG.hex asm-$PROG.elf
done
