#!/bin/bash

exec 2>&1
set -ex

{
	echo "read_ilang ../../database/design.il"
	while read -r idx mut; do
		echo "mutate -ctrl mutsel 8 ${idx} ${mut#* }"
	done < input.txt
	echo "pmuxtree" # workaround for possible source of fmgap
	echo 'simplemap cv32e40p_ff_one/t:$or'
	echo "write_verilog mutated.sv"
} > mutate.ys

yosys -ql mutate.log mutate.ys
ln -s ../../cv32e40p_core_miter.sv ../../test_eq.sby .

sby -f test_eq.sby
gawk "{ print 1, \$1; }" test_eq/status >> output.txt

exit 0