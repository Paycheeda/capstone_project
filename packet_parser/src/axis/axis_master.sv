module axis_master (
	parameter data_width = 64,
	parameter data_user = 128,
	parameter depth = 1024

	) 

(
	input logic aclk,    // Clock
	input logic aresetn, // Clock Enable
	
	axis_if.master m_	
	
);

endmodule : axis_master