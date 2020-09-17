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

override PROJ_ROOT_DIR:=$(shell realpath $(PWD)/../../../../../..)
override MAKE_PATH:=$(PROJ_ROOT_DIR)/cv32/sim/uvmt_cv32
override TEST_YAML_PARSE_TARGETS=mcy

include $(PROJ_ROOT_DIR)/cv32/sim/uvmt_cv32/Makefile

print-%  : ; @echo $* = $($*)

mcy: $(TEST_TEST_DIR)/$(TEST_NAME).elf $(TEST_TEST_DIR)/$(TEST_NAME).hex
	cp $(TEST_TEST_DIR)/$(TEST_NAME).elf custom-$(TEST_NAME).elf
	cp $(TEST_TEST_DIR)/$(TEST_NAME).hex custom-$(TEST_NAME).hex
