override PROJ_ROOT_DIR:=$(shell realpath $(PWD)/../../../../../..)
override MAKE_PATH:=$(PROJ_ROOT_DIR)/cv32/sim/uvmt_cv32
override TEST_YAML_PARSE_TARGETS=mcy

include $(PROJ_ROOT_DIR)/cv32/sim/uvmt_cv32/Makefile

print-%  : ; @echo $* = $($*)

mcy: $(TEST_TEST_DIR)/$(TEST_NAME).elf $(TEST_TEST_DIR)/$(TEST_NAME).hex
	cp $(TEST_TEST_DIR)/$(TEST_NAME).elf custom-$(TEST_NAME).elf
	cp $(TEST_TEST_DIR)/$(TEST_NAME).hex custom-$(TEST_NAME).hex
