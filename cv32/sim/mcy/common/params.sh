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
PROJ_ROOT_DIR=`realpath $PWD/../../../../../..`

CUSTOM_PROGS="hello-world illegal fibonacci misalign dhrystone"
CUSTOM_PROGS+=" riscv_ebreak_test_0 csr_instructions riscv_arithmetic_basic_test_0"
COREV_PROGS=" corev_arithmetic_base_test_0 corev_arithmetic_base_test_1 corev_rand_instr_test_0 corev_rand_instr_test_1 corev_jump_stress_test_0 corev_jump_stress_test_1"

# pulp tests
PULP_CUSTOM_PROGS="pulp_vectorial_comparison_1 pulp_vectorial_comparison_2 pulp_vectorial_comparison_3 pulp_vectorial_dot_product_1 pulp_vectorial_dot_product_2 pulp_vectorial_max pulp_vectorial_min pulp_vectorial_shift pulp_vectorial_shuffle_pack pulp_bit_manipulation pulp_general_alu pulp_immediate_branching pulp_multiply_accumulate pulp_post_increment_load_store pulp_vectorial_avg pulp_vectorial_bitwise"
