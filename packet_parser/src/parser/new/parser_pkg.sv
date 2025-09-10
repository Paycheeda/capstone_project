package parser_pkg;
	import axis_pkg::*;

	//few constants
	localparam logic [15:0] eth_type_ipv4 = 16'h0800;
	localparam logic [15:0] eth_type_ipv6 = 16'h86DD;

	localparam logic [3:0] ipv4_version = 4'h4;
	localparam logic [3:0] ipv6_version = 4'h6;


	// eth head size
	localparam int eth_hdr_len = 14;
	//ipv4 hdr size , minimum
	localparam int ipv4_hdr_len = 20;
	//ipv6 hdr size , this be fixed
	localparam int ipv6_hdr_len = 40;

	//hdr structs from here onwards
	

	//ethernet
	typedef struct packed {
		logic [47:0] dst_mac;
		logic [47:0] src_mac;
		logic [15:0] ethertype;
	} eth_header_t;

	//ipv4
	typedef struct packed {
		logic [3:0]  version;
		logic [3:0]  ihl; //headerlength
		logic [7:0]  qos; // quality of service
		logic [15:0] total_length;
		logic [15:0] identification;
		logic [2:0]  flags;
		logic [12:0] frag_offset; //fragment offset
		logic [7:0]  ttl; //time to live
		logic [7:0]  protocol;
		logic [15:0] hdr_checksum; //header checksum
		logic [31:0] src_ip;
		logic [31:0] dst_ip;
	} ipv4_header_t;

	//ipv6
	typedef struct packed{
		logic [3:0]   version;
		logic [7:0]   traffic_class; //priority/traffic class
		logic [19:0]  flow_label;
		logic [15:0]  payload_length;
		logic [7:0]   nxt_hdr;
		logic [7:0]   hop_lmt;
		logic [127:0] src_ip;
		logic [127:0] dst_ip;
	} ipv6_header_t;

	//metadata output
	typedef struct packed{
		eth_header_t eth_hdr;
		logic is_ipv4;
		logic is_ipv6;
		ipv4_header_t ipv4_hdr;
		ipv6_header_t ipv6_hdr;
	} parsed_metadata_t;

		
endpackage : parser_pkg
