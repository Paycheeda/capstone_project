# Makefile for Packet Parser Project
SV_FILES = axis_pkg.sv \
		   parser_pkg.sv \
		   ethernet_header_parser.sv \
		   ipv4_header_parser.sv \
		   ipv6_header_parser.sv \
		   packet_parser_top.sv \
		   tb_packet_parser_top.sv \
		   tb_ethernet_header_parser.sv 

all: compile

compile:
	vlog -sv $(SV_FILES)

clean:
	rm -rf *.log *.wlf work *.vcd

.PHONY: all compile clean