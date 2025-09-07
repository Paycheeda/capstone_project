/*// tb_packet_parser_top.sv
`timescale 1ns/1ps
import parser_pkg::*;
import axis_pkg::*;

module tb_packet_parser_top;

    localparam int DATA_W = 64;

    logic aclk, aresetn;
    logic [DATA_W-1:0] s_axis_tdata;
    logic              s_axis_tvalid, s_axis_tlast, s_axis_tready;

    parsed_metadata_t  metadata;
    logic              meta_valid;

    // DUT
    packet_parser_top #(.DATA_W(DATA_W)) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tready(s_axis_tready),
        .metadata(metadata),
        .meta_valid(meta_valid)
    );

    // clock
    initial aclk = 0;
    always #5 aclk = ~aclk;

    // reset
    initial begin
        aresetn = 0;
        s_axis_tdata  = 0;
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;
        repeat (5) @(posedge aclk);
        aresetn = 1;
    end

    // AXIS send task
    task send_word(input logic [DATA_W-1:0] data, input bit last);
        @(posedge aclk);
        s_axis_tdata  <= data;
        s_axis_tvalid <= 1;
        s_axis_tlast  <= last;
        wait(s_axis_tready);
        @(posedge aclk);
        s_axis_tvalid <= 0;
        s_axis_tlast  <= 0;
    endtask
        logic [511:0] ipv4_pkt;
        logic [1023:0] ipv6_pkt;
    // Stimulus
    initial begin
        wait(aresetn);

        // -------------------------------
        // IPv4 Test Packet
        // -------------------------------

        ipv4_pkt = {
            48'h010203040506,   // dst mac
            48'h111213141516,   // src mac
            16'h0800,           // ethertype = IPv4
            4'h4, 4'h5, 8'h00,  // version/ihl, TOS
            16'd40,             // total length
            16'h1234,           // identification
            3'b010, 13'h0000,   // flags+frag offset
            8'd64,              // TTL
            8'd6,               // protocol TCP
            16'h0000,           // hdr checksum
            32'hC0A80101,       // src_ip 192.168.1.1
            32'hC0A80102        // dst_ip 192.168.1.2
        };

        send_word(ipv4_pkt[63:0],   0);
        send_word(ipv4_pkt[127:64], 0);
        send_word(ipv4_pkt[191:128],0);
        send_word(ipv4_pkt[255:192],1);

        wait(meta_valid);
        $display("Metadata (IPv4): %p", metadata);

        assert(metadata.is_ipv4) else $fatal("Expected IPv4");
        assert(metadata.eth_hdr.ethertype == eth_type_ipv4) else $fatal("Wrong Ethertype");
        assert(metadata.ipv4_hdr.src_ip == 32'hC0A80101) else $fatal("Wrong Src IP");
        assert(metadata.ipv4_hdr.dst_ip == 32'hC0A80102) else $fatal("Wrong Dst IP");

        $display("IPv4 test passed ✅");

        // small delay before next test
        repeat(10) @(posedge aclk);

        // -------------------------------
        // IPv6 Test Packet
        // -------------------------------

        ipv6_pkt = {
            48'h0A0B0C0D0E0F,   // dst mac
            48'h202122232425,   // src mac
            16'h86DD,           // ethertype = IPv6
            4'h6, 8'h00, 20'h12345, // version, traffic_class, flow_label
            16'd40,             // payload length
            8'd17,              // next header (UDP)
            8'd64,              // hop limit
            128'h20010DB8000000000000000000000001, // src_ip
            128'h20010DB8000000000000000000000002  // dst_ip
        };

        // send IPv6 header (Ethernet+IPv6 = 14+40=54B = 7 words)
        send_word(ipv6_pkt[63:0],    0);
        send_word(ipv6_pkt[127:64],  0);
        send_word(ipv6_pkt[191:128], 0);
        send_word(ipv6_pkt[255:192], 0);
        send_word(ipv6_pkt[319:256], 0);
        send_word(ipv6_pkt[383:320], 0);
        send_word(ipv6_pkt[447:384], 1);

        wait(meta_valid);
        $display("Metadata (IPv6): %p", metadata);

        assert(metadata.is_ipv6) else $fatal("Expected IPv6");
        assert(metadata.eth_hdr.ethertype == eth_type_ipv6) else $fatal("Wrong Ethertype");
        assert(metadata.ipv6_hdr.src_ip == 128'h20010DB8000000000000000000000001)
            else $fatal("Wrong IPv6 Src IP");
        assert(metadata.ipv6_hdr.dst_ip == 128'h20010DB8000000000000000000000002)
            else $fatal("Wrong IPv6 Dst IP");

        $display("IPv6 test passed ✅");

        #100 $finish;
    end

endmodule
*/

// tb_packet_parser_top.sv
`timescale 1ns/1ps
import parser_pkg::*;
import axis_pkg::*;

module tb_packet_parser_top;

  localparam int DATA_W = 64;

  // DUT signals
  logic aclk, aresetn;
  logic [DATA_W-1:0] s_axis_tdata;
  logic              s_axis_tvalid, s_axis_tlast;
  logic              s_axis_tready;

  parsed_metadata_t  metadata;
  logic              meta_valid;

  // DUT instantiation
  packet_parser_top #(.DATA_W(DATA_W)) dut (
    .aclk(aclk),
    .aresetn(aresetn),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tready(s_axis_tready),
    .metadata(metadata),
    .meta_valid(meta_valid)
  );

  // Clock generation
  initial aclk = 0;
  always #5 aclk = ~aclk;

  // Reset
  initial begin
    aresetn = 0;
    s_axis_tdata  = '0;
    s_axis_tvalid = 0;
    s_axis_tlast  = 0;
    repeat (5) @(posedge aclk);
    aresetn = 1;
  end

  // Task to send one 64-bit word
  task send_word(input logic [63:0] data, input bit last);
    @(posedge aclk);
    s_axis_tdata  <= data;
    s_axis_tvalid <= 1;
    s_axis_tlast  <= last;
    wait(s_axis_tready);
    @(posedge aclk);
    s_axis_tvalid <= 0;
    s_axis_tlast  <= 0;
  endtask

  // Stimulus
  initial begin
    wait(aresetn);

       // ==============================
    // Test 1: IPv4 Frame (64B min)
    // ==============================
    $display("\n--- Sending IPv4 Frame ---");

    // Ethernet header (14 bytes)
    send_word({8'hAA,8'hBB,8'hCC,8'hDD,8'hEE,8'hFF, 8'h11,8'h22}, 0); // 8B
    send_word({8'h33,8'h44,8'h55,8'h66, 16'h0800, 8'h45, 8'h00}, 0); // pad to 8B

    // IPv4 header (20B)
    send_word({16'd40,8'h12,8'h34,8'h40,8'h00,8'h40, 8'h06}, 0); // ver/ihl,TOS,len,ID,flags/frag,TTL
    send_word({16'h0000,32'hC0A80101, 16'hC0A8}, 0);                          // proto,cksum,src_ip
    send_word({16'h0102,48'h0}, 0);                            // dst_ip + pad

    // Padding to reach 64B (8 beats total)
    send_word(64'h0, 0);
    send_word(64'h0, 0);
    send_word(64'h0, 1); // mark last word

    wait(meta_valid);
    assert(metadata.eth_hdr.dst_mac   == 48'hAABBCCDDEEFF) else $fatal("Wrong dst_mac (IPv4)");
    assert(metadata.eth_hdr.src_mac   == 48'h112233445566) else $fatal("Wrong src_mac (IPv4)");
    assert(metadata.eth_hdr.ethertype == 16'h0800) else $fatal("Wrong ethertype (IPv4)");
    assert(metadata.is_ipv4) else $fatal("Expected is_ipv4=1");
    assert(metadata.ipv4_hdr.src_ip   == 32'hC0A80101) else $fatal("Wrong src_ip (IPv4)");
    assert(metadata.ipv4_hdr.dst_ip   == 32'hC0A80102) else $fatal("Wrong dst_ip (IPv4)");
    $display("IPv4 frame parsed OK ✅");

    repeat (5) @(posedge aclk);

    // ==============================
    // Test 2: IPv6 Frame (64B min)
    // ==============================
    $display("\n--- Sending IPv6 Frame ---");

    // Ethernet header (14 bytes)
    send_word({8'h01,8'h02,8'h03,8'h04,8'h05,8'h06, 8'hAA,8'hBB}, 0);
    send_word({8'hCC,8'hDD,8'hEE,8'hFF, 16'h86DD, 16'h0400}, 0);

    // IPv6 header (first 40 bytes, but we truncate for min frame)
    send_word({8'h00,8'h00,16'd40,8'h3A,16'h0000, 8'h20}, 0); // version, traffic class, flow label, payload len, next hdr, hop limit
    send_word({24'h010DB8,32'h00000000, 8'h00}, 0);                     // src_ip[127:96]
    send_word({24'h000000,32'h00000001, 8'h20}, 0);                     // src_ip[95:64], src_ip[63:32]
    send_word({24'h010DB8,32'h00000000, 8'h00}, 0);                     // dst_ip[127:96], dst_ip[95:64]
    send_word({24'h000000,32'h00000002}, 1);                     // dst_ip[63:32], dst_ip[31:0], mark last

    wait(meta_valid);
    assert(metadata.eth_hdr.dst_mac   == 48'h010203040506) else $fatal("Wrong dst_mac (IPv6)");
    assert(metadata.eth_hdr.src_mac   == 48'hAABBCCDDEEFF) else $fatal("Wrong src_mac (IPv6)");
    assert(metadata.eth_hdr.ethertype == 16'h86DD) else $fatal("Wrong ethertype (IPv6)");
    assert(metadata.is_ipv6) else $fatal("Expected is_ipv6=1");
    $display("IPv6 frame parsed OK ✅");

    #100 $finish;
  end

endmodule
