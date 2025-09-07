// eth_ipv4_parser_top.sv
import parser_pkg::*;
import axis_pkg::*;

module eth_ipv4_parser_top #(
    parameter int DATA_W = 64
)(
    input  logic              aclk,
    input  logic              aresetn,

    // Input AXIS
    input  logic [DATA_W-1:0] s_axis_tdata,
    input  logic              s_axis_tvalid,
    input  logic              s_axis_tlast,
    output logic              s_axis_tready,

    // Outputs
    output eth_header_t       eth_hdr,
    output ipv4_header_t      ipv4_hdr,
    output logic              eth_done,
    output logic              ipv4_done
);

    // Ethernet parser
    logic start_ipv4, start_ipv6_unused;
    ethernet_header_parser #(.DATA_W(DATA_W)) eth_p (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast (s_axis_tlast),
        .s_axis_tready(s_axis_tready),

        .eth_hdr(eth_hdr),
        .header_done(eth_done),
        .start_ipv4(start_ipv4),
        .start_ipv6(start_ipv6_unused)
    );
/*
    // Stream aligner (drops 14B eth header)
    logic [DATA_W-1:0] ip_tdata;
    logic ip_tvalid, ip_tlast, ip_tready;

    stream_aligner #(.DATA_W(DATA_W), .SLICE_BYTES(parser_pkg::eth_hdr_len)) aligner (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast (s_axis_tlast),
        .s_axis_tready(), // ignored

        .m_axis_tdata (ip_tdata),
        .m_axis_tvalid(ip_tvalid),
        .m_axis_tlast (ip_tlast),
        .m_axis_tready(ip_tready)
    );
*/
    // IPv4 parser
    ipv4_header_parser #(.DATA_W(DATA_W)) ip4_p (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(start_ipv4), // gate until eth parser confirms IPv4
        .s_axis_tlast (s_axis_tlast),
        .s_axis_tready(),
        .ipv4_hdr(ipv4_hdr),
        .header_done(ipv4_done)
    );

endmodule : eth_ipv4_parser_top
