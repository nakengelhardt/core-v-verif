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

include $(PROJ_ROOT_DIR)/cv32/sim/uvmt_cv32/Makefile

dsim-custom-%: comp custom-%.hex custom-%.elf
	mkdir -p $(DSIM_RESULTS)/custom-$* && cd $(DSIM_RESULTS)/custom-$* && \
	$(DSIM) -l dsim-custom-$*.log -image $(DSIM_IMAGE) \
	-work $(DSIM_WORK) $(DSIM_RUN_FLAGS) $(DSIM_DMP_FLAGS) \
	-sv_lib $(UVM_HOME)/src/dpi/libuvm_dpi.so \
	-sv_lib $(OVP_MODEL_DPI) \
	+UVM_TESTNAME=uvmt_cv32_firmware_test_c \
	+firmware=$(PWD)/custom-$*.hex \
	+elf_file=$(PWD)/custom-$*.elf
