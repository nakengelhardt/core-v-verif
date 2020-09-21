#!/bin/bash
#
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
#

# build verilator testbench with mutated module
MAKEFLAGS="CV32E40P_MANIFEST=mutated_manifest.flist PROJ_ROOT_DIR=$PROJ_ROOT_DIR"
MAKEFILE=../../Makefile
make -f $MAKEFILE $MAKEFLAGS testbench_verilator

# for each mutation (listed in input.txt)
while read idx mut; do
	for PROG in $CUSTOM_PROGS $PULP_CUSTOM_PROGS $COREV_PROGS; do
		ln -fs ../../database/setup/custom-$PROG.hex
		timeout 1m ./testbench_verilator +firmware=custom-$PROG.hex --mutidx ${idx} --mutprobe "${mutprobe}" > sim_${PROG}_${idx}.out || true
		if ! grep "EXIT SUCCESS" sim_${PROG}_${idx}.out && ! grep "ALL TESTS PASSED" sim_${PROG}_${idx}.out
		then
			echo "${idx} FAIL" >> output.txt
			continue 2
		fi
	done
	echo "$idx PASS" >> output.txt
done < input.txt
