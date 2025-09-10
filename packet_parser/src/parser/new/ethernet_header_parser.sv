import parser_pkg::*;
import axis_pkg::*;

module ethernet_header_parser #(
    parameter int DATA_W = 64
)(
    input  logic aclk,
    input  logic aresetn,

    // AXI-stream slave input
    input  logic [DATA_W-1:0] s_axis_tdata,
    input  logic              s_axis_tvalid,
    input  logic              s_axis_tlast,
    input /*input*/ logic              enable,/*enable signal*/

    // Handshake from top: signals when whole metadata (eth+ip) has been consumed
    input  logic              meta_done,

    // Outputs
    output eth_header_t       eth_hdr,
    output logic              header_done,
    output logic              start_ipv4,
    output logic              start_ipv6
);


    localparam int BYTES_W = DATA_W/8;
    initial begin
        if (DATA_W % 8 != 0) $fatal("DATA_W must be multiple of 8");
    end

    

    wire accept = s_axis_tvalid && enable/*enable*/;

    typedef enum logic [1:0] {S_IDLE, S_WORD1, S_DONE, S_HOLD} state_t;

    state_t state, nstate;

    logic [47:0] dst_mac_r;
    logic [47:0] src_mac_r;
    logic [15:0] eth_type_r;
    logic header_done_r;

    // cycle-stretch counters
    logic [2:0] ipv4_cnt;
    logic [2:0] ipv6_cnt;

    // outputs
    assign eth_hdr.dst_mac   = dst_mac_r;
    assign eth_hdr.src_mac   = src_mac_r;
    assign eth_hdr.ethertype = eth_type_r;
    assign header_done       = header_done_r;
    assign start_ipv4        = (ipv4_cnt != 0);
    assign start_ipv6        = (ipv6_cnt != 0);
    assign s_axis_tready = 1'b1;

    // next state
    always_comb begin
        nstate = state;
        unique case (state)
            S_IDLE : if (accept) nstate = S_WORD1;
            S_WORD1: if (accept) nstate = S_DONE;
            S_DONE :              nstate = S_HOLD;
            S_HOLD : if (meta_done && s_axis_tlast) nstate = S_IDLE;
        endcase
    end
/*all good till here*/

    // state register
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) state <= S_IDLE;
        else          state <= nstate;
    end

    // byte slice helper
    function automatic logic [7:0] be_byte(input logic [DATA_W-1:0] word, input int byte_idx);
        be_byte = word[DATA_W-1 - (8*byte_idx) -: 8];
    endfunction

    // main parsing
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            dst_mac_r     <= '0;
            src_mac_r     <= '0;
            eth_type_r    <= '0;
            header_done_r <= 1'b0;
            ipv4_cnt      <= '0;
            ipv6_cnt      <= '0;
        end else begin
            header_done_r <= 1'b0;

            // decrement counters if active
            if (ipv4_cnt != 0) ipv4_cnt <= ipv4_cnt - 1;
            if (ipv6_cnt != 0) ipv6_cnt <= ipv6_cnt - 1;

            case (state)
                S_IDLE: if (accept) begin
                    dst_mac_r <= {
                        be_byte(s_axis_tdata,0),
                        be_byte(s_axis_tdata,1),
                        be_byte(s_axis_tdata,2),
                        be_byte(s_axis_tdata,3),
                        be_byte(s_axis_tdata,4),
                        be_byte(s_axis_tdata,5)
                    };
                    if (BYTES_W >= 8)
                        src_mac_r[47:32] <= { be_byte(s_axis_tdata,6), be_byte(s_axis_tdata,7) };
                    else
                        src_mac_r[47:32] <= 16'h0;
                end

                S_WORD1: if (accept) begin
                    src_mac_r[31:0] <= {
                        be_byte(s_axis_tdata,0),
                        be_byte(s_axis_tdata,1),
                        be_byte(s_axis_tdata,2),
                        be_byte(s_axis_tdata,3)
                    };
                    eth_type_r <= { be_byte(s_axis_tdata,4), be_byte(s_axis_tdata,5) };

                    header_done_r <= 1'b1;

                    if ({be_byte(s_axis_tdata,4), be_byte(s_axis_tdata,5)} == parser_pkg::eth_type_ipv4)
                        ipv4_cnt <= 5;   // hold 3 cycles
                    else if ({be_byte(s_axis_tdata,4), be_byte(s_axis_tdata,5)} == parser_pkg::eth_type_ipv6)
                        ipv6_cnt <= 6;   // hold 6 cycles
                end

                default: ;
            endcase
        end
    end

endmodule : ethernet_header_parser