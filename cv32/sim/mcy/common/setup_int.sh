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

cd database/setup
source ../../../common/params.sh


pushd $PROJ_ROOT_DIR/cv32/sim/uvmt_cv32
make comp SIMULATOR=dsim USE_ISS=YES COV=NO
make comp_corev-dv SIMULATOR=dsim USE_ISS=YES COV=NO
make gen_corev-dv TEST=corev_rand_interrupt SIMULATOR=dsim COMP=0 USE_ISS=YES COV=NO SEED=random GEN_START_INDEX=0 GEN_NUM_TESTS=$NUM_INTERRUPT_TESTS
make gen_corev-dv TEST=corev_rand_interrupt_wfi SIMULATOR=dsim COMP=0 USE_ISS=YES COV=NO SEED=random GEN_START_INDEX=0 GEN_NUM_TESTS=$NUM_INTERRUPT_TESTS
popd
for i in $(seq 0 $((NUM_INTERRUPT_TESTS-1))) ; do
	make mcy TEST=corev_rand_interrupt RUN_INDEX=$i
done

# for i in $(seq 0 $((NUM_INTERRUPT_TESTS-1))) ; do
# 	make gen_corev-dv mcy TEST=corev_rand_interrupt_wfi SIMULATOR=dsim COMP=0 USE_ISS=YES COV=NO SEED=random CCOV=0
# done
