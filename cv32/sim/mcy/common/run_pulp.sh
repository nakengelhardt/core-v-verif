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

export SIMULATOR=dsim
MAKE_PATH=$PROJ_ROOT_DIR/cv32/sim/uvmt_cv32/
MAKEFILE=../../../common/test_dsim.mk
MAKEFLAGS="CV32E40P_MANIFEST=$PWD/mutated_manifest.flist PROJ_ROOT_DIR=$PROJ_ROOT_DIR MAKE_PATH=$MAKE_PATH CCOV=0"


for PROG in $PULP_CUSTOM_PROGS ; do
	ln -fs ../../database/setup/custom-$PROG.elf
	ln -fs ../../database/setup/custom-$PROG.hex

	make -f $MAKEFILE $MAKEFLAGS USE_ISS=NO dsim-custom-$PROG
	if ! grep "SIMULATION PASSED" dsim_results/custom-$PROG/dsim-custom-$PROG.log ; then
		echo "1 FAIL" > output.txt
		exit 0
	fi
done

echo "1 PASS" > output.txt
