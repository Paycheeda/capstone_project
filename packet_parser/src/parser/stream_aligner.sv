// stream_aligner.sv
// Drops SLICE_BYTES from the AXI-stream and realigns the remainder so the
// first byte after the slice appears at byte index 0 of the output stream.
//
// Works for DATA_W that is a multiple of 8 (bytes).
import axis_pkg::*;

module stream_aligner #(
    parameter int DATA_W     = 64,
    parameter int SLICE_BYTES = 14
)(
    input  logic                  aclk,
    input  logic                  aresetn,

    // input AXIS
    input  logic [DATA_W-1:0]     s_axis_tdata,
    input  logic                  s_axis_tvalid,
    input  logic                  s_axis_tlast,
    output logic                  s_axis_tready,

    // output AXIS (aligned)
    output logic [DATA_W-1:0]     m_axis_tdata,
    output logic                  m_axis_tvalid,
    output logic                  m_axis_tlast,
    input  logic                  m_axis_tready
);

    localparam int BYTES_W = DATA_W/8;
    localparam int SHIFT_W = $clog2(BYTES_W+1);

    // internal counters/state
    logic [31:0] bytes_to_drop; // remaining bytes to drop
    logic [7:0]  rem_drop;      // remaining drop less than BYTES_W (0..BYTES_W-1)
    logic        dropping_done;

    // buffer to build aligned words
    logic [DATA_W-1:0] prev_word; // holds previous input word for concatenation
    logic               have_prev; // indicates prev_word valid
    logic [SHIFT_W-1:0] shift_bytes; // number of bytes to shift (0..BYTES_W-1)
    logic               first_aligned_emitted;

    // handshakes
    // We'll accept input when downstream (m_axis) can accept previously produced output
    // or when we are simply dropping words (still need to read s_axis).
    // Simpler: always ready when m_axis ready OR we are still dropping and don't need m_axis.
    // Use safe approach: drive s_axis_tready = 1 (parser upstream controls flow).
    assign s_axis_tready = 1'b1;

    // defaults

    // initialize
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            bytes_to_drop         <= SLICE_BYTES;
            rem_drop              <= 0;
            dropping_done         <= 1'b0;
            prev_word             <= '0;
            have_prev             <= 1'b0;
            shift_bytes           <= '0;
            first_aligned_emitted <= 1'b0;
        end else begin
            // Default keep
            // If we still need to drop whole words:
            if (!dropping_done) begin
                if (s_axis_tvalid && s_axis_tready) begin
                    if (bytes_to_drop >= BYTES_W) begin
                        // consume this entire word and reduce drop count
                        bytes_to_drop <= bytes_to_drop - BYTES_W;
                        // store prev_word so we can form first aligned output when remainder drop left < BYTES_W
                        prev_word <= s_axis_tdata;
                        have_prev <= 1'b1;
                    end else begin
                        // bytes_to_drop < BYTES_W -> we need to remove partial leading bytes from this word
                        rem_drop <= bytes_to_drop[7:0]; // small value
                        shift_bytes <= bytes_to_drop[SHIFT_W-1:0];
                        // store the tail of this word as prev_word
                        prev_word <= s_axis_tdata;
                        have_prev <= 1'b1;
                        bytes_to_drop <= 0;
                        dropping_done <= 1'b1; // next cycle start producing aligned outputs (when next word arrives)
                    end
                    // If tlast occurs while dropping, we must reset state on that beat
                    if (s_axis_tlast) begin
                        // packet ended while dropping; reset drop for next packet
                        bytes_to_drop <= SLICE_BYTES;
                        dropping_done <= 1'b0;
                        have_prev <= 1'b0;
                    end
                end
            end else begin
                // dropping_done == 1, we must start producing aligned outputs.
                // Two cases:
                //  - rem_drop == 0 -> already word-aligned: just pass-through subsequent words
                //  - rem_drop > 0  -> produce first aligned word by combining prev_word and this word
                if (s_axis_tvalid && s_axis_tready) begin
                    if (rem_drop == 0) begin
                        // aligned, output current word directly
                        // produce output if downstream ready
                        if (m_axis_tready) begin
                            // pass-through current input as output
                            // output will be handled below in combinational assignments using registers
                        end
                        // update prev_word for next cycle
                        prev_word <= s_axis_tdata;
                        have_prev <= 1'b1;
                        // if tlast => reset drop state afterwards
                        if (s_axis_tlast) begin
                            bytes_to_drop <= SLICE_BYTES; // reset for next packet
                            dropping_done <= 1'b0;
                            have_prev <= 1'b0;
                        end
                    end else begin
                        // rem_drop > 0 => we must combine prev_word and current s_axis_tdata to form aligned output
                        // The logic to compute m_axis_tdata is in combinational area below
                        // after producing first aligned word, set rem_drop=0 (we'll be aligned from then on)
                        // update prev_word for subsequent shifted outputs
                        prev_word <= s_axis_tdata;
                        have_prev <= 1'b1;
                        rem_drop <= 0;
                        shift_bytes <= 0;
                        first_aligned_emitted <= 1'b1;
                        if (s_axis_tlast) begin
                            // if this was last, after forming output we must reset drop state
                            bytes_to_drop <= SLICE_BYTES;
                            dropping_done <= 1'b0;
                            have_prev <= 1'b0;
                        end
                    end
                end
            end
        end
    end

    // Combinational output assembler
    // We need a separate small pipeline to generate m_axis_tdata when appropriate.
    // Simpler approach: generate m_axis_tvalid/data when either:
    //  - rem_drop == 0 and dropping_done==1 -> pass through s_axis_tdata
    //  - rem_drop > 0 and have_prev && s_axis_tvalid -> generate combined word
    // Because we used s_axis_tready = 1, we must gate m_axis_tvalid with m_axis_tready externally in top-level.
    logic [DATA_W-1:0] combined_word;
    logic               produce_combined;

    int shift_bits;
    int left_bits;

    always_comb begin
        produce_combined = 1'b0;
        combined_word    = '0;
        m_axis_tvalid    = 1'b0;
        m_axis_tdata     = '0;
        m_axis_tlast     = 1'b0;

        if (!dropping_done) begin
            // still dropping - no output
            m_axis_tvalid = 1'b0;
        end else begin
            if (rem_drop == 0) begin
                // aligned: pass-through current input as output
                // only valid when upstream provides a valid word (s_axis_tvalid)
                if (s_axis_tvalid) begin
                    m_axis_tvalid = 1'b1;
                    m_axis_tdata  = s_axis_tdata;
                    m_axis_tlast  = s_axis_tlast;
                end
            end else begin
                // Need to produce combined output using prev_word and current s_axis_tdata.
                // prev_word contains the word where remainder bytes are in its high-side (because we dropped low bytes)
                // Build as: lower bytes from prev_word shifted right by rem_drop bytes,
                // high bytes from current word shifted left by (BYTES_W - rem_drop)
                if (have_prev && s_axis_tvalid) begin
                    shift_bits = rem_drop * 8;
                    left_bits  = DATA_W - shift_bits;
                    // create concatenation:
                    combined_word = (prev_word >> shift_bits) | (s_axis_tdata << left_bits);
                    m_axis_tvalid = 1'b1;
                    m_axis_tdata  = combined_word;
                    // m_axis_tlast: if current s_axis_tlast && (we consumed remainder), propagate
                    m_axis_tlast  = s_axis_tlast;
                end
            end
        end
    end

endmodule : stream_aligner
