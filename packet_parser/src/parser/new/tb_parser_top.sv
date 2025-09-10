`timescale 1ns/1ps
import axis_pkg::*;
import parser_pkg::*;

module tb_parser_top;

    // ---------------------------------------------------------
    // Clock & Reset
    // ---------------------------------------------------------
    logic clk;
    logic rstn;

    always #5 clk = ~clk; // 100 MHz

    initial begin
        clk  = 0;
        rstn = 0;
        #50 rstn = 1; // release reset
    end

    // ---------------------------------------------------------
    // DUT IO
    // ---------------------------------------------------------
    logic [63:0] s_axis_tdata;
    logic        s_axis_tvalid;
    logic        s_axis_tlast;
    logic        s_axis_tready;

    logic        preamble_detected;
    eth_header_t eth_hdr;
    logic        header_done;
    logic        start_ipv4, start_ipv6;

    // ---------------------------------------------------------
    // Instantiate DUT
    // ---------------------------------------------------------
    parser_top dut (
        .aclk            (clk),
        .aresetn         (rstn),
        .s_axis_tdata    (s_axis_tdata),
        .s_axis_tvalid   (s_axis_tvalid),
        .s_axis_tlast    (s_axis_tlast),
        .s_axis_tready   (s_axis_tready),
        .preamble_detected(preamble_detected),
        .eth_hdr         (eth_hdr),
        .header_done     (header_done),
        .start_ipv4      (start_ipv4),
        .start_ipv6      (start_ipv6)
    );

    // ---------------------------------------------------------
    // Stimulus
    // ---------------------------------------------------------
    task send_word(input [63:0] data, input bit last);
        @(posedge clk);
        s_axis_tdata  <= data;
        s_axis_tvalid <= 1;
        s_axis_tlast  <= last;
        @(posedge clk);
        s_axis_tvalid <= 0;
        s_axis_tlast  <= 0;
    endtask

    initial begin
        // Initialize
        s_axis_tdata  = '0;
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;

        wait(rstn == 1);
        @(posedge clk);

        // ====================================================
        // Build Ethernet frame: PREAMBLE + SFD + ETH header
        // ====================================================
        // Preamble (7 bytes of 0x55) + SFD (0xD5)
        // Put them in one 64-bit word for simplicity
        send_word(64'h5555_5555_5555_D5AA, 0); // AA dummy after SFD

        // Ethernet header (14 bytes):
        // dst_mac = 0x112233445566
        // src_mac = 0xAABBCCDDEEFF
        // ethertype = 0x0800 (IPv4)
        send_word(64'h1122_3344_5566_AABB, 0);
        send_word(64'hCCDD_EEFF_0800_0000, 1); // pad remaining with 0

        // Wait some cycles
        repeat(10) @(posedge clk);

        $display("===== Results =====");
        $display("Preamble detected: %0d", preamble_detected);
        $display("Header done:       %0d", header_done);
        $display("Start IPv4:        %0d", start_ipv4);
        $display("Start IPv6:        %0d", start_ipv6);
        $display("Dst MAC: %h, Src MAC: %h, Ethertype: %h",
                  eth_hdr.dst_mac, eth_hdr.src_mac, eth_hdr.ethertype);

        $finish;
    end

endmodule
