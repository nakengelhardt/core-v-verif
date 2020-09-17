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


set -e

source params.sh

cd database/setup
ln -f -s ../../setup_dsim.mk Makefile

python3 -c "import sys
print(sys.path)"

make corev-dv
make gen_corev-dv mcy TEST=corev_arithmetic_base_test GEN_START_INDEX=0 RUN_INDEX=0 SIMULATOR=dsim USE_ISS=YES
make gen_corev-dv mcy TEST=corev_arithmetic_base_test GEN_START_INDEX=1 RUN_INDEX=1 SIMULATOR=dsim USE_ISS=YES
make gen_corev-dv mcy TEST=corev_rand_instr_test GEN_START_INDEX=0 RUN_INDEX=0 SIMULATOR=dsim USE_ISS=YES
make gen_corev-dv mcy TEST=corev_rand_instr_test GEN_START_INDEX=1 RUN_INDEX=1 SIMULATOR=dsim USE_ISS=YES
make gen_corev-dv mcy TEST=corev_jump_stress_test GEN_START_INDEX=0 RUN_INDEX=0 SIMULATOR=dsim USE_ISS=YES
make gen_corev-dv mcy TEST=corev_jump_stress_test GEN_START_INDEX=1 RUN_INDEX=1 SIMULATOR=dsim USE_ISS=YES

for PROG in $CUSTOM_PROGS $PULP_CUSTOM_PROGS ; do
make mcy TEST=$PROG
done
