#!/bin/bash

set -e

PROJ_ROOT_DIR=$PWD/../../../..
TEST_DIR=$PROJ_ROOT_DIR/cv32/tests/core
MAKEFLAGS="PROJ_ROOT_DIR=$PROJ_ROOT_DIR"
MAKEFILE=Makefile

make -f $MAKEFILE $MAKEFLAGS clone

make -f $MAKEFILE $MAKEFLAGS $TEST_DIR/cv32_riscv_tests_firmware/cv32_riscv_tests_firmware.hex
cp $TEST_DIR/cv32_riscv_tests_firmware/cv32_riscv_tests_firmware.hex database/setup/firmware.hex
