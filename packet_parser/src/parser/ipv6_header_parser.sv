// ipv6_header_parser.sv
import parser_pkg::*;
import axis_pkg::*;

module ipv6_header_parser #(
    parameter int DATA_W = 64
)(
    input  logic              aclk,
    input  logic              aresetn,

    // AXI-stream input (aligned)
    input  logic [DATA_W-1:0] s_axis_tdata,
    input  logic              s_axis_tvalid,
    input  logic              s_axis_tlast,
    output logic              s_axis_tready,

    // Outputs
    output ipv6_header_t      ipv6_hdr,
    output logic              header_done
);

    localparam int BYTES_W = DATA_W/8;
    assign s_axis_tready = 1'b1;

    function automatic logic [7:0] get_byte(input logic [DATA_W-1:0] d, input int idx);
        return d[8*idx +: 8];
    endfunction

    typedef enum logic [3:0] {S_IDLE, S_W0, S_W1, S_W2, S_W3, S_W4, S_DONE} state_t;
    state_t state, next_state;

    ipv6_header_t ipv6_r;
    logic         header_done_r;

    assign ipv6_hdr = ipv6_r;
    assign header_done = header_done_r;

    wire accept = s_axis_tvalid && s_axis_tready;

    // state register
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) state <= S_IDLE;
        else          state <= next_state;
    end

    always_comb begin
        next_state = state;
        unique case (state)
            S_IDLE: if (accept) next_state = S_W0;
            S_W0:   if (accept) next_state = S_W1;
            S_W1:   if (accept) next_state = S_W2;
            S_W2:   if (accept) next_state = S_W3;
            S_W3:   if (accept) next_state = S_W4;
            S_W4:   if (accept) next_state = S_DONE;
            S_DONE: next_state = S_IDLE;
        endcase
    end

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            ipv6_r <= '0;
            header_done_r <= 1'b0;
        end else begin
            header_done_r <= 1'b0;
            case (state)
                S_W0: if (accept) begin
                    ipv6_r.version       <= get_byte(s_axis_tdata, 0)[7:4];
                    ipv6_r.traffic_class <= { get_byte(s_axis_tdata,0)[3:0], get_byte(s_axis_tdata,1)[7:4] };
                    ipv6_r.flow_label    <= { get_byte(s_axis_tdata,1)[3:0], get_byte(s_axis_tdata,2), get_byte(s_axis_tdata,3) };
                end

                S_W1: if (accept) begin
                    ipv6_r.payload_length <= { get_byte(s_axis_tdata,4), get_byte(s_axis_tdata,5) };
                    ipv6_r.nxt_hdr        <= get_byte(s_axis_tdata,6);
                    ipv6_r.hop_lmt        <= get_byte(s_axis_tdata,7);
                end

                S_W2: if (accept) begin
                    // src_ip upper 64
                    ipv6_r.src_ip[127:64] <= {
                        get_byte(s_axis_tdata,0), get_byte(s_axis_tdata,1), get_byte(s_axis_tdata,2), get_byte(s_axis_tdata,3),
                        get_byte(s_axis_tdata,4), get_byte(s_axis_tdata,5), get_byte(s_axis_tdata,6), get_byte(s_axis_tdata,7)
                    };
                end

                S_W3: if (accept) begin
                    // src_ip lower 64, dst_ip upper 64
                    ipv6_r.src_ip[63:0] <= {
                        get_byte(s_axis_tdata,0), get_byte(s_axis_tdata,1), get_byte(s_axis_tdata,2), get_byte(s_axis_tdata,3),
                        get_byte(s_axis_tdata,4), get_byte(s_axis_tdata,5), get_byte(s_axis_tdata,6), get_byte(s_axis_tdata,7)
                    };
                    ipv6_r.dst_ip[127:64] <= {
                        get_byte(s_axis_tdata,8), get_byte(s_axis_tdata,9), get_byte(s_axis_tdata,10), get_byte(s_axis_tdata,11),
                        get_byte(s_axis_tdata,12), get_byte(s_axis_tdata,13), get_byte(s_axis_tdata,14), get_byte(s_axis_tdata,15)
                    } >> 0; // harmless, keeps style
                end

                S_W4: if (accept) begin
                    // dst_ip lower 64 (assuming aligned)
                    ipv6_r.dst_ip[63:0] <= {
                        get_byte(s_axis_tdata,0), get_byte(s_axis_tdata,1), get_byte(s_axis_tdata,2), get_byte(s_axis_tdata,3),
                        get_byte(s_axis_tdata,4), get_byte(s_axis_tdata,5), get_byte(s_axis_tdata,6), get_byte(s_axis_tdata,7)
                    };
                end

                S_DONE: begin
                    header_done_r <= 1'b1;
                end
            endcase
        end
    end

endmodule : ipv6_header_parser
