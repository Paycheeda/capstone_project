/*
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
    output logic              s_axis_tready,

    // Outputs
    output eth_header_t       eth_hdr,
    output logic              header_done,
    output logic              start_ipv4,
    output logic 					start_ipv6
);

    // For now, always ready (can improve later)
    assign s_axis_tready = 1'b1;

    // Extract byte helper
    function automatic logic [7:0] get_byte(input logic [63:0] d, input int idx);
        return d[8*idx +: 8];
    endfunction

    typedef enum logic [1:0] {s_idle, s_word0, s_word1} state_t;
    state_t state, nstate;

    // Registers
    logic [47:0] dst_mac_r, src_mac_r;
    logic [15:0] eth_type_r;
    logic header_done_r, start_ipv4_r;

    // Assign outputs
    assign eth_hdr.dst_mac   = dst_mac_r;
    assign eth_hdr.src_mac   = src_mac_r;
    assign eth_hdr.ethertype = eth_type_r;
    assign header_done       = header_done_r;
    assign start_ipv4        = start_ipv4_r;

    // FSM state register
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            state <= s_idle;
        else
            state <= nstate;
    end

    // FSM next-state logic
    always_comb begin
        nstate = state;
        unique case (state)
            s_idle : if (s_axis_tvalid) begin nstate = s_word0; end
            s_word0: if (s_axis_tvalid) begin nstate = s_word1; end
            s_word1:                    nstate = s_idle;
        endcase
    end

    // Main parsing logic
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            dst_mac_r      <= 0;
            src_mac_r      <= 0;
            eth_type_r     <= 0;
            header_done_r  <= 1'b0;
            start_ipv4_r   <= 1'b0;
        end else begin
            header_done_r <= 1'b0; // default low

            case (state)
                s_idle: if (s_axis_tvalid) begin
                    dst_mac_r <= {
                        get_byte(s_axis_tdata, 5),
                        get_byte(s_axis_tdata, 4),
                        get_byte(s_axis_tdata, 3),
                        get_byte(s_axis_tdata, 2),
                        get_byte(s_axis_tdata, 1),
                        get_byte(s_axis_tdata, 0)
                    };
                    src_mac_r[47:32] <= {
                        get_byte(s_axis_tdata, 7),
                        get_byte(s_axis_tdata, 6)
                    };
                end

                s_word0: if (s_axis_tvalid) begin
                    src_mac_r[31:0] <= {
                        get_byte(s_axis_tdata, 11),
                        get_byte(s_axis_tdata, 10),
                        get_byte(s_axis_tdata, 9),
                        get_byte(s_axis_tdata, 8)
                    };
                    eth_type_r <= {
                        get_byte(s_axis_tdata, 13),
                        get_byte(s_axis_tdata, 12)
                    };
                end

                s_word1: begin
                    header_done_r <= 1'b1;
                    start_ipv4_r  <= (eth_type_r == 16'h0800);
                    start_ipv6 <= (eth_type_r == 16'h86DD);

                end
            endcase
        end
    end

endmodule : ethernet_header_parser */

// ethernet_header_parser_fixed.sv
/*import parser_pkg::*;
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
    output logic              s_axis_tready,

    // Outputs
    output eth_header_t       eth_hdr,
    output logic              header_done,
    output logic              start_ipv4,
    output logic              start_ipv6
);

    // bytes per beat (must be integer)
    localparam int BYTES_W = DATA_W/8;
    // sanity check (synthesis will error if DATA_W not divisible by 8)
    initial begin
        if (DATA_W % 8 != 0) $fatal("DATA_W must be multiple of 8");
    end

    // passive parser for TB (always ready). Use accept for proper handshake.
    assign s_axis_tready = 1'b1;
    wire accept = s_axis_tvalid && s_axis_tready;

    // states: first beat -> second beat -> done
    typedef enum logic [1:0] {S_IDLE, S_WORD1, S_DONE} state_t;
    state_t state, nstate;

    // internal regs
    logic [47:0] dst_mac_r;
    logic [47:0] src_mac_r;
    logic [15:0] eth_type_r;
    logic header_done_r;
    logic start_ipv4_r, start_ipv6_r;

    // outputs
    assign eth_hdr.dst_mac   = dst_mac_r;
    assign eth_hdr.src_mac   = src_mac_r;
    assign eth_hdr.ethertype = eth_type_r;
    assign header_done       = header_done_r;
    assign start_ipv4        = start_ipv4_r;
    assign start_ipv6        = start_ipv6_r;

    // next state (use accept to advance)
    always_comb begin
        nstate = state;
        unique case (state)
            S_IDLE : if (accept)     nstate = S_WORD1;
            S_WORD1: if (accept)     nstate = S_DONE;
            S_DONE :                  nstate = S_IDLE;
        endcase
    end

    // state register
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) state <= S_IDLE;
        else          state <= nstate;
    end

    // Helper: slice bytes with assumption that TB built words as {byte0,byte1,...}
    // We define "byte_idx 0" as the *first* byte in your concatenation (MSB).
    // So byte_idx i maps to bits: DATA_W-1 - 8*i  down to DATA_W-8 - 8*i.
    function automatic logic [7:0] be_byte(input logic [DATA_W-1:0] word, input int byte_idx);
        be_byte = word[DATA_W-1 - (8*byte_idx) -: 8];
    endfunction

    // parse stored aligned to beats; compute slices using the helper.
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            dst_mac_r      <= '0;
            src_mac_r      <= '0;
            eth_type_r     <= '0;
            header_done_r  <= 1'b0;
            start_ipv4_r   <= 1'b0;
            start_ipv6_r   <= 1'b0;
        end else begin
            // default: clear pulses
            header_done_r <= 1'b0;
            start_ipv4_r  <= 1'b0;
            start_ipv6_r  <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (accept) begin
                        // first beat contains:
                        // MSB region: DST MAC (48 bits) then top 16 bits of SRC MAC (if DATA_W==64)
                        // We must extract 6 bytes for dst and 2 bytes for upper src.
                        // byte indices inside this beat: 0..(BYTES_W-1)
                        // dst_mac bytes -> byte_idx 0..5 (MSB->LSB)
                        dst_mac_r <= {
                            be_byte(s_axis_tdata,0),
                            be_byte(s_axis_tdata,1),
                            be_byte(s_axis_tdata,2),
                            be_byte(s_axis_tdata,3),
                            be_byte(s_axis_tdata,4),
                            be_byte(s_axis_tdata,5)
                        };
                        // upper 2 bytes of src_mac are next bytes in this beat (if BYTES_W>=8 it's safe)
                        // They are byte_idx 6 and 7 for DATA_W==64.
                        if (BYTES_W >= 8) begin
                            src_mac_r[47:32] <= { be_byte(s_axis_tdata,6), be_byte(s_axis_tdata,7) };
                        end else begin
                            src_mac_r[47:32] <= 16'h0; // defensive
                        end
                    end
                end

                S_WORD1: begin
                    if (accept) begin
                        // second beat: top bytes contain remaining src_mac (4 bytes) then ethertype (2 bytes)
                        // For DATA_W==64:
                        // byte_idx 0..3 = src_mac[31:0]
                        // byte_idx 4..5 = ethertype (high byte then low byte)
                        src_mac_r[31:0] <= {
                            be_byte(s_axis_tdata,0),
                            be_byte(s_axis_tdata,1),
                            be_byte(s_axis_tdata,2),
                            be_byte(s_axis_tdata,3)
                        };
                        eth_type_r <= { be_byte(s_axis_tdata,4), be_byte(s_axis_tdata,5) };

                        // pulse header_done and protocol start signals
                        header_done_r <= 1'b1;
                        start_ipv4_r  <= ( {be_byte(s_axis_tdata,4), be_byte(s_axis_tdata,5)} == parser_pkg::eth_type_ipv4 );
                        start_ipv6_r  <= ( {be_byte(s_axis_tdata,4), be_byte(s_axis_tdata,5)} == parser_pkg::eth_type_ipv6 );
                    end
                end

                S_DONE: begin
                    
                end

            endcase
        end
    end

endmodule : ethernet_header_parser */

// ethernet_header_parser_fixed.sv
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
    output /*input*/ logic              s_axis_tready,/*enable signal*/

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

    

    wire accept = s_axis_tvalid && s_axis_tready/*enable*/;

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

