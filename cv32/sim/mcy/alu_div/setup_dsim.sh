#!/bin/bash

source params.sh

PROJ_ROOT_DIR=$PWD/../../../..

MAKEFILE=setup_dsim.mk

#make -f $MAKEFILE PROJ_ROOT_DIR=$PROJ_ROOT_DIR build-unit-test div
#make -f $MAKEFILE PROJ_ROOT_DIR=$PROJ_ROOT_DIR build-unit-test divu

make -f $MAKEFILE PROJ_ROOT_DIR=$PROJ_ROOT_DIR corev-dv

make -f $MAKEFILE PROJ_ROOT_DIR=$PROJ_ROOT_DIR firmware.hex firmware.elf

for PROG in $CUSTOM_PROGS ; do
make -f $MAKEFILE PROJ_ROOT_DIR=$PROJ_ROOT_DIR custom-$PROG.hex custom-$PROG.elf
done

for PROG in $ASM_PROGS ; do
make -f $MAKEFILE PROJ_ROOT_DIR=$PROJ_ROOT_DIR asm-$PROG.hex asm-$PROG.elf
done
