`timescale 1ns/1ps
import parser_pkg::*;
import axis_pkg::*;

module tb_eth_ipv4_parser;

  localparam int DATA_W = 64;

  logic aclk, aresetn;
  logic [DATA_W-1:0] s_axis_tdata;
  logic              s_axis_tvalid, s_axis_tlast;
  logic              s_axis_tready;

  eth_header_t  eth_hdr;
  ipv4_header_t ipv4_hdr;
  logic         eth_done, ipv4_done;

  // DUT
  eth_ipv4_parser_top #(.DATA_W(DATA_W)) dut (
    .aclk(aclk),
    .aresetn(aresetn),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tready(s_axis_tready),
    .eth_hdr(eth_hdr),
    .ipv4_hdr(ipv4_hdr),
    .eth_done(eth_done),
    .ipv4_done(ipv4_done)
  );

  // Clock
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

    $display("\n--- Sending Ethernet + IPv4 Frame ---");

    // -----------------------------
    // Ethernet header (14 bytes)
    // -----------------------------
    send_word({8'hAA,8'hBB,8'hCC,8'hDD,8'hEE,8'hFF, 8'h11,8'h22}, 0); // dst_mac + upper src_mac
    send_word({8'h33,8'h44,8'h55,8'h66, 16'h0800, 8'h45, 8'h00}, 0); // pad to 8B
    // -----------------------------
    // IPv4 header (20 bytes min)
    // -----------------------------
    send_word({16'd40,8'h12,8'h34,8'h40,8'h00,8'h40, 8'h06}, 0); // ver/ihl,TOS,len,ID,flags/frag,TTL
    send_word({16'h0000,32'hC0A80101, 16'hC0A8}, 0);                          // proto,cksum,src_ip
    send_word({16'h0102,48'h0}, 0);                            // dst_ip + pad

    // Padding until 64B
    send_word(64'h0, 0);
    send_word(64'h0, 1); // mark last

    // -----------------------------
    // Checks
    // -----------------------------
    wait(eth_done);
    $display("Ethernet header parsed");
    assert(eth_hdr.dst_mac   == 48'hAABBCCDDEEFF) else $fatal("Wrong dst_mac");
    assert(eth_hdr.src_mac   == 48'h112233445566) else $fatal("Wrong src_mac");
    assert(eth_hdr.ethertype == 16'h0800) else $fatal("Wrong ethertype");

    wait(ipv4_done);
    $display("IPv4 header parsed");
    assert(ipv4_hdr.version      == 4) else $fatal("Wrong IPv4 version");
    assert(ipv4_hdr.ihl          == 5) else $fatal("Wrong IHL");
    assert(ipv4_hdr.total_length == 40) else $fatal("Wrong total_length");
    assert(ipv4_hdr.protocol     == 6) else $fatal("Wrong protocol");
    assert(ipv4_hdr.src_ip       == 32'hC0A80101) else $fatal("Wrong src_ip");
    assert(ipv4_hdr.dst_ip       == 32'hC0A80102) else $fatal("Wrong dst_ip");

    $display("Ethernet + IPv4 parsing OK ✅");

    #50 $finish;
  end

endmodule
