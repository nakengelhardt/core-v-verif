#!/bin/bash

exec 2>&1
set -ex

# create yosys script for exporting mutation
{
	echo "read_ilang ../../database/design.il"
	while read -r idx mut; do
		echo "mutate ${mut#* }"
	done < input.txt
	echo "opt_rmdff" # workaround for verilator not supporting posedge 1'b1
	echo "write_verilog -attr2comment mutated.sv"
} > mutate.ys

# export mutated.sv
yosys -ql mutate.log mutate.ys

source ../../params.sh

PROJ_ROOT_DIR=$PWD/../../../../../..

# create modified manifest
grep -v "cv32e40p_alu_div.sv" $PROJ_ROOT_DIR/core-v-cores/cv32e40p/cv32e40p_manifest.flist > mutated_manifest.flist
echo "$PWD/mutated.sv" >> mutated_manifest.flist


export SIMULATOR=dsim
MAKEFILE=../../test_dsim.mk
MAKEFLAGS="CV32E40P_MANIFEST=$PWD/mutated_manifest.flist PROJ_ROOT_DIR=$PROJ_ROOT_DIR"
for PROG in $CUSTOM_PROGS ; do
	ln -s ../../database/setup/custom-$PROG.hex
	ln -s ../../database/setup/custom-$PROG.elf

	make -f $MAKEFILE $MAKEFLAGS dsim-custom-$PROG
	if ! grep "SIMULATION PASSED" dsim_results/custom-$PROG/dsim-custom-$PROG.log ; then
		echo "1 FAIL" > output.txt
		exit 0
	fi
done

# disabled - currently known to fail
#ln -s ../../database/setup/firmware.hex
#ln -s ../../database/setup/firmware.elf
#make -f $MAKEFILE $MAKEFLAGS dsim-firmware
#if [[ `grep -c "ERROR" dsim_results/firmware/dsim-firmware.log` -ne 4 ]] ; then
#	echo "1 FAIL" > output.txt
#	exit 0
#fi

echo "1 PASS" > output.txt
