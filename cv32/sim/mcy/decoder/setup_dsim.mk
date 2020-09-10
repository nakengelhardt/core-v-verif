override PROJ_ROOT_DIR:=$(PWD)/../../../../../..
override MAKE_PATH:=$(PROJ_ROOT_DIR)/cv32/sim/uvmt_cv32/


SUPPORTED_COMMANDS = build-unit-test

include $(PROJ_ROOT_DIR)/cv32/sim/uvmt_cv32/Makefile

build-unit-test: firmware-unit-test-clean
build-unit-test: $(FIRMWARE)/firmware_unit_test.hex
build-unit-test: copy-unit-test

copy-unit-test:
	cp $(FIRMWARE)/firmware_unit_test.hex firmware_$(UNIT_TEST)_unit_test.hex

firmware.hex: $(FIRMWARE)/firmware.hex
	cp $< $@

firmware.elf: $(FIRMWARE)/firmware.elf
	cp $< $@

custom-%.hex: $(CUSTOM_DIR)/%.hex
	cp $< $@

custom-%.elf: $(CUSTOM_DIR)/%.elf
	cp $< $@

asm-%.hex: $(ASM_DIR)/%.hex
	cp $< $@

asm-%.elf: $(ASM_DIR)/%.elf
	cp $< $@

print-%  : ; @echo $* = $($*)

