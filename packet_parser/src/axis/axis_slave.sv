module axis_slave #(
	parameter data_width = 64,
	parameter data_user = 128
	)
	(
	input logic aclk,    // Clock
	input logic aresetn, // Clock Enable
	
	axis_if.slave s_axis //axis mod port as slave

	//the right side of slave where it gets connected to fifo
	output logic [data_width-1:0]   fifo_wdata,
	output logic [data_width/8-1:0] fifo_wkeep,
	output logic 					fifo_wlast,
	output logic [data_user-1:0]    fifo_wuser,
	output logic                    fifo_wen,
	
	input logic                     fifo_full,
	
);

	wire accept = s_axis.tready && s_axis.tvalid;

	assign s_axis.tready = !fifo_full;

	always_ff @(posedge aclk or negedge aresetn) begin : proc_
		if(!aresetn) begin
			fifo_wen <= 1'b0;
			fifo_wdata <= '0;
			fifo_wkeep <= '0;
			fifo_wlast <= 1'b0;
			fifo_wuser <= '0;
		end else begin
			fifo_wen <= accept;
			if (accept) begin
				fifo_wdata <= s_axis.tdata;
				fifo_wkeep <= s_axis.tkeep;
				fifo_wlast <= s_axis.tlast;
				fifo_wuser <= s_axis.tuser;
			end
		end
	end


endmodule : axis_slave