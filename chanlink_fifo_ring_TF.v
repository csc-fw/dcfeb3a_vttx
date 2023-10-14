`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   09:26:32 07/11/2023
// Design Name:   chanlink_fifo_ring
// Module Name:   /home/firmware/Projects/DCFEB/ISE_14.7/dcfeb3a_vttx/chanlink_fifo_ring_TF.v
// Project Name:  dcfeb3a_vttx
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: chanlink_fifo_ring
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module chanlink_fifo_ring_TF;

	// Inputs
	reg WCLK;
	reg RCLK;
	reg RST_RESYNC;
	reg FIFO_RST;
	reg [6:0] SAMP_MAX;
	reg WREN;
	reg L1A_WRT_EN;
	reg WARN;
	reg TRIG_IN;
	wire [36:0] L1A_EVT_DATA;
	wire [17:0] WDATA;


	// Outputs
	wire TRIG_OUT;
	wire LAST_WRD;
	wire DVALID;
	wire OVLP_MUX;
	wire MLT_OVLP;
	wire [15:0] DOUT;
	
	//Internal
	reg [17:0] evnt_buf[767:0];
	reg [36:0] l1a_buf[3:0];
	reg [9:0]  evnt_buf_add;
	reg [1:0]  l1a_buf_add;

	// Bidirs
	wire [35:0] LA_CNTRL;
	
	assign	WDATA = evnt_buf[evnt_buf_add];
	assign	L1A_EVT_DATA = l1a_buf[l1a_buf_add];

	// Instantiate the Unit Under Test (UUT)
	chanlink_fifo_ring #(
		.USE_CHIPSCOPE(0),
		.TMR(1)
	)
	uut (
		.LA_CNTRL(LA_CNTRL), 
		.WCLK(WCLK), 
		.RCLK(RCLK), 
		.RST_RESYNC(RST_RESYNC), 
		.FIFO_RST(FIFO_RST), 
		.SAMP_MAX(SAMP_MAX), 
		.WDATA(WDATA), 
		.WREN(WREN), 
		.L1A_EVT_DATA(L1A_EVT_DATA), 
		.L1A_WRT_EN(L1A_WRT_EN), 
		.WARN(WARN), 
		.TRIG_IN(TRIG_IN), 
		.TRIG_OUT(TRIG_OUT), 
		.LAST_WRD(LAST_WRD), 
		.DVALID(DVALID), 
		.OVLP_MUX(OVLP_MUX), 
		.MLT_OVLP(MLT_OVLP), 
		.DOUT(DOUT)
	);
   parameter CMS_PERIOD = 24;
   parameter C160_PERIOD = 6;
	
	initial begin
		// Initialize Inputs
      WCLK = 1'b1;
      forever
         #(CMS_PERIOD/8) WCLK = ~WCLK; //160MHz clock
	end
	
	initial begin
		// Initialize Inputs
      RCLK = 1'b1;
      forever
         #(CMS_PERIOD/2) RCLK = ~RCLK; //40MHz clock
	end
	
	initial begin
	   $readmemh ("source/Sim/evnt_buf.dat", evnt_buf, 0, 767);
	   $readmemh ("source/Sim/l1a_buf.dat", l1a_buf, 0, 3);
	end
	
	always @(posedge WCLK or posedge FIFO_RST)
	begin
		if (FIFO_RST)
			evnt_buf_add <= 10'd0;
		else 
			if (WREN && evnt_buf_add < 767)
				evnt_buf_add <= evnt_buf_add + 1;
			else if (WREN)
					evnt_buf_add <= 10'd0;
	end
	
	always @(posedge WCLK or posedge FIFO_RST)
	begin
		if (FIFO_RST)
			l1a_buf_add <= 2'd0;
		else 
			if (L1A_WRT_EN)
				l1a_buf_add <= l1a_buf_add + 1;
	end
	
	initial begin
		// Initialize Inputs
		RST_RESYNC = 1;
		FIFO_RST = 1;
		SAMP_MAX = 7'd7;
		WREN = 0;
		L1A_WRT_EN = 0;
		WARN = 0;
		TRIG_IN = 0;

		// Wait 96ns for global reset to finish
		#96;
		#(6*CMS_PERIOD);
		RST_RESYNC = 0;
		FIFO_RST = 0;
      #(4*CMS_PERIOD);
		L1A_WRT_EN = 1;
		#(3*C160_PERIOD);
		WREN = 1;
		#C160_PERIOD;
		L1A_WRT_EN = 0;
		#(767*C160_PERIOD);
		WREN = 0;
		#(542*CMS_PERIOD);
		WREN = 1;
		#(768*C160_PERIOD);
		WREN = 0;
		
	end
      
endmodule

