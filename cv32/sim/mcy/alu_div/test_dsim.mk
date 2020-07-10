include $(PROJ_ROOT_DIR)/cv32/sim/uvmt_cv32/Makefile

dsim-%-unit-test: comp firmware_%_unit_test.hex
	mkdir -p $(DSIM_RESULTS)/firmware && cd $(DSIM_RESULTS)/firmware && \
	$(DSIM) -l dsim-$*.log -image $(DSIM_IMAGE) \
	-work $(DSIM_WORK) $(DSIM_RUN_FLAGS) $(DSIM_DMP_FLAGS) \
	-sv_lib $(UVM_HOME)/src/dpi/libuvm_dpi.so \
	+UVM_TESTNAME=uvmt_cv32_firmware_test_c \
	+firmware=$(PWD)/firmware_$*_unit_test.hex

dsim-firmware: comp 
	mkdir -p $(DSIM_RESULTS)/firmware && cd $(DSIM_RESULTS)/firmware && \
	$(DSIM) -l dsim-firmware.log -image $(DSIM_IMAGE) \
	-work $(DSIM_WORK) $(DSIM_RUN_FLAGS) $(DSIM_DMP_FLAGS) \
	-sv_lib $(UVM_HOME)/src/dpi/libuvm_dpi.so \
	-sv_lib $(OVP_MODEL_DPI) \
	+UVM_TESTNAME=uvmt_cv32_firmware_test_c \
	+firmware=$(PWD)/firmware.hex +elf_file=$(PWD)/firmware.elf

dsim-custom-%: comp custom-%.hex custom-%.elf
	mkdir -p $(DSIM_RESULTS)/custom-$* && cd $(DSIM_RESULTS)/custom-$* && \
	$(DSIM) -l dsim-custom-$*.log -image $(DSIM_IMAGE) \
	-work $(DSIM_WORK) $(DSIM_RUN_FLAGS) $(DSIM_DMP_FLAGS) \
	-sv_lib $(UVM_HOME)/src/dpi/libuvm_dpi.so \
	-sv_lib $(OVP_MODEL_DPI) \
	+UVM_TESTNAME=uvmt_cv32_firmware_test_c \
	+firmware=$(PWD)/custom-$*.hex \
	+elf_file=$(PWD)/custom-$*.elf
