vlog -sv ./alu.sv
vlog -sv ./alu_tb.sv

vsim -c work.alu_tb

run -all

quit -f