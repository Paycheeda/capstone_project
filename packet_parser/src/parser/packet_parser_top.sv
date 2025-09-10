// packet_parser_top.sv
import parser_pkg::*;
import axis_pkg::*;

module packet_parser_top #(
    parameter int DATA_W = 64
)(
    input  logic              aclk,
    input  logic              aresetn,

    // Input AXIS
    input  logic [DATA_W-1:0] s_axis_tdata,
    input  logic              s_axis_tvalid,
    input  logic              s_axis_tlast,
    output logic              s_axis_tready,

    // Output metadata
    output parsed_metadata_t  metadata,
    output logic              meta_valid
);

    // ethernet parser
    eth_header_t eth_hdr;
    logic eth_done, start_ipv4, start_ipv6;



    ethernet_header_parser #(.DATA_W(DATA_W)) eth_p (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast (s_axis_tlast),
        .s_axis_tready(s_axis_tready),

        .meta_done(meta_done),  // NEW

        .eth_hdr(eth_hdr),
        .header_done(eth_done),
        .start_ipv4(start_ipv4),
        .start_ipv6(start_ipv6)
    );


    // aligner: drop ethernet header (14 bytes)
    logic [DATA_W-1:0] ip_tdata;
    logic ip_tvalid, ip_tlast, ip_tready;

    // intermediate ready signals for each parser
logic ip4_tready, ip6_tready;

// connect stream_aligner output ready to the active parser
assign ip_tready = (start_ipv4) ? ip4_tready :
                   (start_ipv6) ? ip6_tready :
                                  1'b0;

  /*  stream_aligner #(.DATA_W(DATA_W), .SLICE_BYTES(parser_pkg::eth_hdr_len)) aligner (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast (s_axis_tlast),
        .s_axis_tready(),

        .m_axis_tdata (ip_tdata),
        .m_axis_tvalid(ip_tvalid),
        .m_axis_tlast (ip_tlast),
        .m_axis_tready(ip_tready)
    );*/

    // parsers outputs
    ipv4_header_t ipv4_h;
    ipv6_header_t ipv6_h;
    logic ipv4_done, ipv6_done;

    // IPv4: only when start_ipv4 asserted; note gate ip_tvalid so only one parser sees data
    ipv4_header_parser #(.DATA_W(DATA_W)) ip4_p (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(start_ipv4),
        .s_axis_tlast (s_axis_tlast),
        .s_axis_tready(),
        .ipv4_hdr(ipv4_h),
        .header_done(ipv4_done)
    );

    ipv6_header_parser #(.DATA_W(DATA_W)) ip6_p (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(start_ipv6),
        .s_axis_tlast (s_axis_tlast),
        .s_axis_tready(),
        .ipv6_hdr(ipv6_h),
        .header_done(ipv6_done)
    );

    // assemble metadata when ipv4_done or ipv6_done pulses
    parsed_metadata_t meta_r;
    logic meta_valid_r;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            meta_r <= '0;
            meta_valid_r <= 1'b0;
        end else begin
            meta_valid_r <= 1'b0;
            // prefer ipv4 if both (shouldn't happen)
            if (ipv4_done) begin
                meta_r.eth_hdr  = eth_hdr;
                meta_r.is_ipv4  = 1'b1;
                meta_r.is_ipv6  = 1'b0;
                meta_r.ipv4_hdr = ipv4_h;
                meta_r.ipv6_hdr = '0;
                meta_valid_r    <= 1'b1;
            end else if (ipv6_done) begin
                meta_r.eth_hdr  = eth_hdr;
                meta_r.is_ipv4  = 1'b0;
                meta_r.is_ipv6  = 1'b1;
                meta_r.ipv6_hdr = ipv6_h;
                meta_r.ipv4_hdr = '0;
                meta_valid_r    <= 1'b1;
            end
        end
    end

    assign metadata  = meta_r;
    assign meta_valid = meta_valid_r;

    // generate meta_done pulse when metadata is valid
    logic meta_done_r;
    assign meta_done = meta_done_r;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) meta_done_r <= 1'b0;
        else          meta_done_r <= meta_valid_r; // one-cycle after meta_valid
    end


endmodule : packet_parser_top
