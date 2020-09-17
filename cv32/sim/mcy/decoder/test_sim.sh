#!/bin/bash

exec 2>&1
set -ex

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

source ../../../common/params.sh

# create modified manifest
ORIG_MANIFEST="$PROJ_ROOT_DIR/core-v-cores/cv32e40p/cv32e40p_manifest.flist"
grep -v "cv32e40p_decoder.sv" $ORIG_MANIFEST > mutated_manifest.flist
echo "../../cv32e40p_decoder_wrapper_dpi.sv" >> mutated_manifest.flist
echo "mutated.sv" >> mutated_manifest.flist

source ../../../common/run_sim.sh
