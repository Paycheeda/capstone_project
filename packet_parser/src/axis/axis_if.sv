interface axis_if #(parameter data_width = 64, parameter data_user = 128 ) (input logic aclk, input logic aresetn);
	logic [data_width-1:0]   tdata;
	logic 				     tvalid;
	logic 					 tready;
	logic				     tlast;
	logic [data_width/8-1:0] tkeep;
	logic [data_user-1:0]    tuser;

	modport master (

		input tready, 

		output tdata, tvalid, tlast, tkeep, tuser);

	modport slave (

		input tdata, tvalid, tlast, tkeep, tuser,

		output tready);



	
endinterface : axis_if