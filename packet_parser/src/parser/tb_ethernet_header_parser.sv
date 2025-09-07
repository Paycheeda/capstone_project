// tb_ethernet_header_parser.sv
`timescale 1ns/1ps
import parser_pkg::*;
import axis_pkg::*;

module tb_ethernet_header_parser;

  localparam int DATA_W = 64;

  logic aclk, aresetn;
  logic [DATA_W-1:0] s_axis_tdata;
  logic              s_axis_tvalid, s_axis_tlast;
  logic              s_axis_tready;

  eth_header_t eth_hdr;
  logic        header_done, start_ipv4, start_ipv6;

  // DUT
  ethernet_header_parser #(.DATA_W(DATA_W)) dut (
    .aclk(aclk),
    .aresetn(aresetn),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tready(s_axis_tready),
    .eth_hdr(eth_hdr),
    .header_done(header_done),
    .start_ipv4(start_ipv4),
    .start_ipv6(start_ipv6)
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

    // --------------------------------
    // Test 1: IPv4 Ethernet Frame
    // --------------------------------
    $display("\n--- Sending IPv4 Ethernet Frame (64B) ---");

    // word0 = dst_mac[47:0] + src_mac[47:32]
    send_word({8'hAA,8'hBB,8'hCC,8'hDD,8'hEE,8'hFF, 8'h11,8'h22}, 0);
    // word1 = src_mac[31:0] + ethertype
    send_word({8'h33,8'h44,8'h55,8'h66, 16'h0800, 16'h0000}, 0);
    // word2–word6 = payload padding
    send_word(64'h0, 0);
    send_word(64'h0, 0);
    send_word(64'h0, 0);
    send_word(64'h0, 0);
    send_word(64'h0, 0);
    // word7 = final padding, mark last
    send_word(64'h0, 1);

    wait(header_done);
    assert(eth_hdr.dst_mac   == 48'hAABBCCDDEEFF) else $fatal("Wrong dst_mac");
    assert(eth_hdr.src_mac   == 48'h112233445566) else $fatal("Wrong src_mac");
    assert(eth_hdr.ethertype == 16'h0800) else $fatal("Wrong ethertype");
    assert(start_ipv4) else $fatal("Expected start_ipv4=1");

    $display("IPv4 Ethernet frame parsed OK ✅");

    repeat (5) @(posedge aclk);

    // --------------------------------
    // Test 2: IPv6 Ethernet Frame
    // --------------------------------
    $display("\n--- Sending IPv6 Ethernet Frame (64B) ---");

    // word0 = dst_mac + upper src_mac
    send_word({8'h01,8'h02,8'h03,8'h04,8'h05,8'h06, 8'hAA,8'hBB}, 0);
    // word1 = lower src_mac + ethertype
    send_word({8'hCC,8'hDD,8'hEE,8'hFF, 16'h86DD, 16'h0000}, 0);
    // word2–word6 = payload padding
    send_word(64'h0, 0);
    send_word(64'h0, 0);
    send_word(64'h0, 0);
    send_word(64'h0, 0);
    send_word(64'h0, 0);
    // word7 = final padding, mark last
    send_word(64'h0, 1);

    wait(header_done);
    assert(eth_hdr.dst_mac   == 48'h010203040506) else $fatal("Wrong dst_mac (IPv6)");
    assert(eth_hdr.src_mac   == 48'hAABBCCDDEEFF) else $fatal("Wrong src_mac (IPv6)");
    assert(eth_hdr.ethertype == 16'h86DD) else $fatal("Wrong ethertype (IPv6)");
    assert(start_ipv6) else $fatal("Expected start_ipv6=1");

    $display("IPv6 Ethernet frame parsed OK ✅");

    #50 $finish;
  end

endmodule
