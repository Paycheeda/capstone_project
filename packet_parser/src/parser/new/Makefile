# Makefile for Packet Parser Project
SV_FILES = axis_pkg.sv \
		   parser_pkg.sv \
		   ethernet_header_parser.sv \
		   preamble_sfd_detector.sv \
		   top.sv \
		   tb_parser_top.sv

all: compile

compile:
	vlog -sv $(SV_FILES)

clean:
	rm -rf *.log *.wlf work *.vcd

.PHONY: all compile clean