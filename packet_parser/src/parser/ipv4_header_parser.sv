// ipv4_header_parser.sv
import parser_pkg::*;
import axis_pkg::*;

module ipv4_header_parser #(
    parameter int DATA_W = 64
)(
    input  logic              aclk,
    input  logic              aresetn,

    // AXI-stream input (aligned so byte 0 of IP is at index 0)
    input  logic [DATA_W-1:0] s_axis_tdata,
    input  logic              s_axis_tvalid, //start_ipv4
    input  logic              s_axis_tlast,
    output logic              s_axis_tready,

    // Outputs
    output ipv4_header_t      ipv4_hdr,
    output logic              header_done    // 1-cycle pulse when finished
);

    localparam int BYTES_W = DATA_W/8;

    assign s_axis_tready = 1'b1; // passive parser

    function automatic logic [7:0] get_byte(input logic [DATA_W-1:0] d, input int idx);
        return d[8*idx +: 8];
    endfunction

    typedef enum logic [2:0] {S_IDLE, S_WORD0, S_WORD1, S_WORD2, S_WORD3, S_DONE} state_t;
    state_t state, next_state;

    ipv4_header_t ipv4_r;
    logic         header_done_r;

    assign ipv4_hdr   = ipv4_r;
    assign header_done = header_done_r;

    wire accept = s_axis_tvalid && s_axis_tready;

    // State register
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) state <= S_IDLE;
        else          state <= next_state;
    end

    // Next-state
    always_comb begin
        next_state = state;
        unique case (state)
            S_IDLE:  if (accept) next_state = S_WORD0;
            S_WORD0: if (accept) next_state = S_WORD1;
            S_WORD1: if (accept) next_state = S_WORD2;
            S_WORD2: if (accept) next_state = S_WORD3;
            S_WORD3: if (accept) next_state = S_DONE;
            S_DONE:  next_state = S_IDLE;
        endcase
    end

    // Capture
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            ipv4_r        <= '0;
            header_done_r <= 1'b0;
        end else begin
            header_done_r <= 1'b0;
            case (state)
                S_WORD0: if (accept) begin
                    // bytes 0..7
                    ipv4_r.version      <= get_byte(s_axis_tdata, 1)[7:4];
                    ipv4_r.ihl          <= get_byte(s_axis_tdata, 1)[3:0];
                    ipv4_r.qos          <= get_byte(s_axis_tdata, 0);
                    // identification may start later
                end

                S_WORD1: if (accept) begin
                    // bytes 8..15 (contain identification, flags/frag, ttl, protocol, checksum part)
                    ipv4_r.total_length <= { get_byte(s_axis_tdata, 2), get_byte(s_axis_tdata, 3) };
                    ipv4_r.identification <= { get_byte(s_axis_tdata, 0), get_byte(s_axis_tdata, 1) };
                    ipv4_r.flags          <= get_byte(s_axis_tdata, 2)[7:5];
                    ipv4_r.frag_offset    <= { get_byte(s_axis_tdata, 2)[4:0], get_byte(s_axis_tdata, 3) };
                    // next bytes may include ttl/protocol depending alignment; handle next word
                end

                S_WORD2: if (accept) begin
                    // bytes 16..23 or appropriate positions (we assume aligned stream so
                    // TTL is byte 8 relative to IP, which appears in S_WORD? For clarity:
                    // For aligned stream, byte indices relative to IP header:
                    // S_WORD0: bytes 0..(BYTES_W-1)
                    // S_WORD1: bytes BYTES_W..2*BYTES_W-1
                    // So TTL is at byte index 8 => falls into S_WORD1 when BYTES_W==8.
                    // To be robust, compute by absolute byte offsets per DATA_W==64 case.
                    // We'll assume DATA_W==64 here (BYTES_W==8), thus:
                    ipv4_r.ttl          <= get_byte(s_axis_tdata, 0); // byte8
                    ipv4_r.protocol     <= get_byte(s_axis_tdata, 1); // byte9
                    ipv4_r.hdr_checksum <= { get_byte(s_axis_tdata, 2), get_byte(s_axis_tdata, 3) }; // bytes10..11
                    // src_ip part
                    ipv4_r.src_ip       <= { get_byte(s_axis_tdata, 4), get_byte(s_axis_tdata, 5),
                                             get_byte(s_axis_tdata, 6), get_byte(s_axis_tdata, 7) };
                end

                S_WORD3: if (accept) begin
                    // dst_ip (bytes 16..19)
                    ipv4_r.dst_ip <= { get_byte(s_axis_tdata, 0), get_byte(s_axis_tdata, 1),
                                       get_byte(s_axis_tdata, 2), get_byte(s_axis_tdata, 3) };
                end

                S_DONE: begin
                    header_done_r <= 1'b1;
                end
            endcase
        end
    end

endmodule : ipv4_header_parser
