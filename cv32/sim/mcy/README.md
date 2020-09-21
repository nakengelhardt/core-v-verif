Directory for MCY coverage reporting
==================================

This is an example setup for using Mutation Cover with Yosys (MCY).
Each folder contains setup for evaluating testbench coverage of a subcomponent of the cv32e40p core:
- `alu_div` checks coverage for the divider (cv32e40p_alu_div)
- `decoder` checks coverage for the decoder (cv32e40p_decoder)

The cv32e40p verification test suite is split into two environments, "core" and "uvm".
Correspondingly, there are two tests set up in the mcy project to run on the mutated module: `test_sim` runs the core testbench using verilator as the simulator,
`test_dsim` runs the UVM testbench with step-and-compare to the Imperas ISS using dsim.
Both tests run on the whole core, with the mutated module substituted in the sources.

The equivalence check `test_eq` is used to check if a mutation introduces a relevant behavioral modification in the first place. It runs a bounded model check on a miter circuit comparing the original and mutated module. If a mutation is equivalent to the original, it is disregarded.

This assumes that the SEDA suite and the pulp-riscv-gcc can be found in the path.
Set it e.g. as follows:

  export PATH=/opt/symbiotic/bin:/opt/riscv/bin:$PATH

To obtain a coverage measurement, `cd` to the desired folder and run `mcy init` to initialize the project followed by `mcy run -j$(nproc)` to run the measurement.
It will print coverage measures at the end of the run. Call `mcy status` to print the measurement from the last run again.
