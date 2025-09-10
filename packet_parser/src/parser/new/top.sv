`timescale 1ns/1ps
import axis_pkg::*;
import parser_pkg::*;

module parser_top (
    input  logic             aclk,
    input  logic             aresetn,

    // AXI-Stream input (64-bit, but detector consumes 8-bit sequentially)
    input  logic [63:0]      s_axis_tdata,
    input  logic             s_axis_tvalid,
    input  logic             s_axis_tlast,
    output logic             s_axis_tready,

    // Outputs
    output logic             preamble_detected,
    output eth_header_t      eth_hdr,
    output logic             header_done,
    output logic             start_ipv4,
    output logic             start_ipv6
);

    // ---------------------------------------------------------
    // Internal wires
    // ---------------------------------------------------------
    logic [7:0]  byte_data;
    logic        byte_valid;
    logic        byte_last;

    // Unpack 64-bit tdata → feed one byte per cycle to detector
    // (here we only forward the MSB [63:56] for simplicity,
    // in practice you'd serialize all 8 bytes sequentially)
    assign byte_data  = s_axis_tdata[63:56];
    assign byte_valid = s_axis_tvalid;
    assign byte_last  = s_axis_tlast;

    // Detector output
    logic detector_preamble;

    // Enable for Ethernet header parser (after preamble detected)
    logic parser_enable;

    // ---------------------------------------------------------
    // Instantiate preamble/SFD detector
    // ---------------------------------------------------------
    preamble_sfd_detector #(
        .DATA_W(8)
    ) u_preamble (
        .aclk           (aclk),
        .aresetn        (aresetn),
        .s_axis_tdata   (byte_data),
        .s_axis_tvalid  (byte_valid),
        .s_axis_tlast   (byte_last),
        .s_axis_tready  (s_axis_tready), // always ready
        .ethertypein      (eth_hdr),
        .preamble_detected(detector_preamble)
    );

    assign preamble_detected = detector_preamble;

    // ---------------------------------------------------------
    // Enable Ethernet parser after preamble ends
    // ---------------------------------------------------------
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            parser_enable <= 1'b0;
        else if (detector_preamble)
            parser_enable <= 1'b1;
        else if (s_axis_tlast)
            parser_enable <= 1'b0;
    end

    // ---------------------------------------------------------
    // Instantiate Ethernet header parser
    // ---------------------------------------------------------
    ethernet_header_parser #(
        .DATA_W(64)
    ) u_eth_parser (
        .aclk        (aclk),
        .aresetn     (aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .enable      (parser_enable),
        .meta_done   (1'b1),    // tie high for now
        .eth_hdr     (eth_hdr),
        .header_done (header_done),
        .start_ipv4  (start_ipv4),
        .start_ipv6  (start_ipv6)
    );

    // Ready: valid if either stage is running

endmodule : parser_top
