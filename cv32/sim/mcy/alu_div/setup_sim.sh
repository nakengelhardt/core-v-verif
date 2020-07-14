#!/bin/bash

set -e

PROJ_ROOT_DIR=$PWD/../../../..
TEST_DIR=$PROJ_ROOT_DIR/cv32/tests/core
MAKEFLAGS="PROJ_ROOT_DIR=$PROJ_ROOT_DIR"
MAKEFILE=Makefile

make -f $MAKEFILE $MAKEFLAGS clone

make -f $MAKEFILE $MAKEFLAGS $TEST_DIR/div_only_firmware/div_only_firmware.hex
cp $TEST_DIR/div_only_firmware/div_only_firmware.hex database/setup/div_only_firmware.hex

make -f $MAKEFILE $MAKEFLAGS $TEST_DIR/firmware/firmware.hex
cp $TEST_DIR/firmware/firmware.hex database/setup/firmware.hex
