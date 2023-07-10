`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:04:45 07/10/2023
// Design Name:   ChnLnk_Frame_SampMax_FSM
// Module Name:   /home/firmware/Projects/DCFEB/ISE_14.7/dcfeb3a_vttx/ChnLnk_TF.v
// Project Name:  dcfeb3a_vttx
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ChnLnk_Frame_SampMax_FSM
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module ChnLnk_TF;

	// Inputs
	reg CLK;
	reg F_MT;
	reg L1A_BUF_MT;
	reg RST;
	reg [6:0] SAMP_MAX;

	// Outputs
	wire CLR_CRC;
	wire HDR;
	wire LAST_WRD;
	wire RD;
	wire [6:0] SEQ;
	wire VALID;
	wire [3:0] FRM_STATE;

	// Instantiate the Unit Under Test (UUT)
	ChnLnk_Frame_SampMax_FSM uut (
		.CLR_CRC(CLR_CRC), 
		.HDR(HDR), 
		.LAST_WRD(LAST_WRD), 
		.RD(RD), 
		.SEQ(SEQ), 
		.VALID(VALID), 
		.FRM_STATE(FRM_STATE), 
		.CLK(CLK), 
		.F_MT(F_MT), 
		.L1A_BUF_MT(L1A_BUF_MT), 
		.RST(RST), 
		.SAMP_MAX(SAMP_MAX)
	);
   parameter CMS_PERIOD = 24;

	initial begin
		// Initialize Inputs
      CLK = 1'b1;
      forever
         #(CMS_PERIOD/2) CLK = ~CLK;
	end

	initial begin
		// Initialize Inputs
		F_MT = 0;
		L1A_BUF_MT = 1;
		RST = 1;
		SAMP_MAX = 7'd8;

		// Wait 100 ns for global reset to finish
		#100;
		#(4*CMS_PERIOD);
		RST = 0;
		#(4*CMS_PERIOD);
		L1A_BUF_MT = 0;
        
		// Add stimulus here

	end
      
endmodule

