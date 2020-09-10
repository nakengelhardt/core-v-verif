#!/bin/bash

exec 2>&1
set -ex

source ../../params.sh

# create yosys script for exporting mutation
{
	echo "read_ilang ../../database/design.il"
	while read -r idx mut; do
		# add multiple mutations to module, selectable with 'mutsel' input
		echo "mutate -ctrl mutsel 8 ${idx} ${mut#* }"
	done < input.txt
	echo "opt_dff" # workaround for verilator not supporting posedge 1'b1
	echo "rename cv32e40p_decoder mutated"
	echo "write_verilog -attr2comment mutated.sv"
} > mutate.ys

# export mutated.sv
yosys -ql mutate.log mutate.ys

# locations
PROJ_ROOT_DIR=$PWD/../../../../../..
TEST_DIR=$PROJ_ROOT_DIR/cv32/tests/core

# create modified manifest
ORIG_MANIFEST="$PROJ_ROOT_DIR/core-v-cores/cv32e40p/cv32e40p_manifest.flist"
#ORIG_MANIFEST="$PROJ_ROOT_DIR/cv32/sim/core/cv32e40p_temp_manifest.flist"
grep -v "cv32e40p_decoder.sv" $ORIG_MANIFEST > mutated_manifest.flist
echo "../../cv32e40p_decoder_wrapper_dpi.sv" >> mutated_manifest.flist
echo "mutated.sv" >> mutated_manifest.flist

# build verilator testbench with mutated module
MAKEFLAGS="CV32E40P_MANIFEST=mutated_manifest.flist PROJ_ROOT_DIR=$PROJ_ROOT_DIR"
MAKEFILE=../../Makefile
make -f $MAKEFILE $MAKEFLAGS testbench_verilator

# for each mutation (listed in input.txt)
while read idx mut; do
	for PROG in $CUSTOM_PROGS $PULP_CUSTOM_PROGS ; do
		ln -fs ../../database/setup/custom-$PROG.hex
		timeout 1m ./testbench_verilator +firmware=custom-$PROG.hex --mutidx ${idx} > sim_${PROG}_${idx}.out || true
		if ! grep "EXIT SUCCESS" sim_${PROG}_${idx}.out && ! grep "ALL TESTS PASSED" sim_${PROG}_${idx}.out
		then
			echo "${idx} FAIL" >> output.txt
			continue 2
		fi
	done
	echo "$idx PASS" >> output.txt
done < input.txt
