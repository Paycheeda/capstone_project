module preamble_sfd_detector #(
    parameter int DATA_W = 8   // process byte-by-byte for simplicity
)(
    input  logic              aclk,
    input  logic              aresetn,

    input  logic [DATA_W-1:0] s_axis_tdata,
    input  logic              s_axis_tvalid,
    input  logic              s_axis_tlast,
    output logic              s_axis_tready,

    output logic              preamble_detected   // high during preamble/SFD
);

    // Fixed preamble (7 bytes of 0x55 + 1 byte of 0xD5)
    localparam byte PREAMBLE = 8'h55;
    localparam byte SFD      = 8'hD5;

    // Ethertype values
    localparam logic [15:0] ETH_TYPE_IPV4 = 16'h0800;
    localparam logic [15:0] ETH_TYPE_IPV6 = 16'h86DD;

    typedef enum logic [2:0] {
        S_IDLE,
        S_PREAMBLE,
        S_SFD,
        S_ETH_HDR,
        S_DONE
    } state_t;

    state_t state, next_state;

    logic [2:0] pre_cnt;
    logic [15:0] ethertype;

    assign s_axis_tready = 1'b1; // always ready

    // output: high only during PREAMBLE/SFD stage
    assign preamble_detected = (state == S_PREAMBLE) || (state == S_SFD);

    // State register
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state     <= S_IDLE;
            pre_cnt   <= 3'd0;
            ethertype <= 16'd0;
        end else begin
            state <= next_state;

            if (s_axis_tvalid) begin
                case (state)
                    S_PREAMBLE: begin
                        if (s_axis_tdata == PREAMBLE)
                            pre_cnt <= pre_cnt + 1;
                        else
                            pre_cnt <= 0; // restart if mismatch
                    end
                    S_SFD: begin
                        // nothing to count, just waiting for SFD
                    end
                    S_ETH_HDR: begin
                        // capture Ethertype (bytes 12-13 of Ethernet header)
                        // assuming sequential byte stream
                        if (pre_cnt == 12) ethertype[15:8] <= s_axis_tdata;
                        if (pre_cnt == 13) ethertype[7:0]  <= s_axis_tdata;
                        pre_cnt <= pre_cnt + 1;
                    end
                endcase
            end
        end
    end

    // Next-state logic
    always_comb begin
        next_state = state;
        case (state)
            S_IDLE:     if (s_axis_tvalid && s_axis_tdata == PREAMBLE) next_state = S_PREAMBLE;
            S_PREAMBLE: if (pre_cnt == 7 && s_axis_tvalid && s_axis_tdata == SFD) next_state = S_SFD;
            S_SFD:      if (s_axis_tvalid) next_state = S_ETH_HDR;
            S_ETH_HDR:  if (ethertype == ETH_TYPE_IPV4 || ethertype == ETH_TYPE_IPV6)
                            next_state = S_DONE;
            S_DONE:     if (s_axis_tlast) next_state = S_IDLE;
        endcase
    end

endmodule
