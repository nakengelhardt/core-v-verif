SUPPORTED_COMMANDS = build-unit-test

include $(PROJ_ROOT_DIR)/cv32/sim/uvmt_cv32/Makefile

build-unit-test: firmware-unit-test-clean
build-unit-test: $(FIRMWARE)/firmware_unit_test.hex
build-unit-test: copy-unit-test

copy-unit-test:
	cp $(FIRMWARE)/firmware_unit_test.hex firmware_$(UNIT_TEST)_unit_test.hex

firmware.hex: $(FIRMWARE)/firmware.hex
	cp $< $@


