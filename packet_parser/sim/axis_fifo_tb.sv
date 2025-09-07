`timescale 1ns/1ps

import axis_pkg::*;

module axis_fifo_tb;

    // Parameters
    localparam int DATA_WIDTH = 64;
    localparam int USER_WIDTH = 128;
    localparam int DEPTH = 8;

    // Clock & Reset
    logic aclk;
    logic aresetn;

    // FIFO signals
    logic wr_en;
    axis_word_t wr_data;
    logic full;

    logic rd_en;
    axis_word_t rd_data;
    logic empty;

    // Instantiate FIFO
    axis_fifo #(
        .data_width(DATA_WIDTH),
        .data_user(USER_WIDTH),
        .depth(DEPTH)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .full(full),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty)
    );

    // Clock generation
    initial aclk = 0;
    always #5 aclk = ~aclk; // 100 MHz clock

    // Reset
    initial begin
        aresetn = 0;
        #20;
        aresetn = 1;
    end

    // Test sequence
    initial begin
        // Dump waveforms
        $dumpfile("axis_fifo_tb.vcd");
        $dumpvars(0, axis_fifo_tb);

        // Initialize
        wr_en = 0;
        wr_data = '{default:'0};
        rd_en = 0;

        // Wait for reset deassertion
        @(posedge aclk);
        @(posedge aclk);

        // --- Write some data ---
        for (int i = 0; i < 10; i++) begin
            @(posedge aclk);
            if (!full) begin
                wr_data.tdata = i;
                wr_data.tkeep = 8'hFF;
                wr_data.tlast = (i == 9) ? 1'b1 : 1'b0;
                wr_data.tuser = i;
                wr_en = 1;
            end else begin
                wr_en = 0;
            end
        end
        wr_en = 0;

        // --- Read data ---
        repeat (10) begin
            @(posedge aclk);
            if (!empty) begin
                rd_en = 1;
                $display("Read data: %0d, tlast=%0b, tuser=%0d", rd_data.tdata, rd_data.tlast, rd_data.tuser);
            end else begin
                rd_en = 0;
            end
        end
        rd_en = 0;

        // Finish simulation
        #20;
        $finish;
    end

endmodule
