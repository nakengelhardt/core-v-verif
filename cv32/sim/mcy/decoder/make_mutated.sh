#!/bin/bash

exec 2>&1
set -ex

mkdir -p mutated
idx=0
while read -r mut; do
	idx=$((idx + 1))
	{
		echo "read_ilang database/design.il"
		echo "${mut}"
		echo "pmuxtree" # workaround for possible source of fmgap
		echo "write_verilog mutated/mutated_${idx}.v"
	} > mutate.ys
	yosys -ql mutate.log mutate.ys
done < database/mutations.txt

