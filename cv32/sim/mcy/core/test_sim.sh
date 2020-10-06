#!/bin/bash
# Copyright 2020 OpenHW Group
# Copyright 2020 Symbiotic EDA
#
# Licensed under the Solderpad Hardware License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https://solderpad.org/licenses/
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

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
	echo "rename cv32e40p_core mutated"
	echo "write_verilog -attr2comment mutated.sv"
} > mutate.ys

# export mutated.sv
yosys -ql mutate.log mutate.ys

source ../../../common/params.sh

# copy mutated manifest - core contains too many files to make grep-excluding them useful
ln -s ../../mutated_manifest.flist

source ../../../common/run_sim.sh
