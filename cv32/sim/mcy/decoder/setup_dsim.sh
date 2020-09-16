#!/bin/bash

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
