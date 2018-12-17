`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:49:30 12/04/2018
// Design Name:   I2C_interfaces
// Module Name:   F:/DCFEB/firmware/ISE_14.7/dcfeb3a_vttx/source/Sim/I2C_interfaces_sim_tf.v
// Project Name:  dcfeb3a_vttx
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: I2C_interfaces
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module I2C_interfaces_sim_tf;

	// Inputs
	reg CLK40;
	reg CLK1MHZ;
	reg RST;
	reg [7:0] I2C_WRT_FIFO_DATA;
	reg I2C_WE;
	reg I2C_RDENA;
	reg I2C_RESET;
	reg I2C_START;
	reg I2C_TEST_ENA_B;

	// Outputs
	wire COM_LDSCL;
	wire [7:0] I2C_RBK_FIFO_DATA;
	wire I2C_CLR_START;
	wire [7:0] I2C_STATUS;
	wire [3:0] AT_STATE;
	wire DAQ_TST_INPRGS;
	wire DAQ_NACK_ERRS;
	wire DAQ_NACK_FLG;
	wire DAQ_ERR_FLG;
	wire [3:0] DAQ_ERR_REG;
	wire TRG_TST_INPRGS;
	wire TRG_NACK_ERRS;
	wire TRG_NACK_FLG;
	wire TRG_ERR_FLG;
	wire [3:0] TRG_ERR_REG;

	// Bidirs
	wire DAQ_LDSDA;
	wire TRG_LDSDA;

pullup daq_pu (DAQ_LDSDA);
pullup trg_pu (TRG_LDSDA);
pullup com_cl_pu (COM_LDSCL);

	// Instantiate the Unit Under Test (UUT)
	I2C_interfaces #(
		.Simulation(1),
		.USE_CHIPSCOPE(0)
	)
	uut (
		.CLK40(CLK40), 
		.CLK1MHZ(CLK1MHZ), 
		.RST(RST), 
		.DAQ_LDSDA(DAQ_LDSDA), 
		.TRG_LDSDA(TRG_LDSDA), 
		.COM_LDSCL(COM_LDSCL), 
		.I2C_WRT_FIFO_DATA(I2C_WRT_FIFO_DATA), 
		.I2C_WE(I2C_WE), 
		.I2C_RDENA(I2C_RDENA), 
		.I2C_RESET(I2C_RESET), 
		.I2C_START(I2C_START), 
		.I2C_TEST_ENA_B(I2C_TEST_ENA_B), 
		.I2C_RBK_FIFO_DATA(I2C_RBK_FIFO_DATA), 
		.I2C_CLR_START(I2C_CLR_START), 
		.I2C_STATUS(I2C_STATUS), 
		.AT_STATE(AT_STATE), 
		.DAQ_TST_INPRGS(DAQ_TST_INPRGS), 
		.DAQ_NACK_ERRS(DAQ_NACK_ERRS), 
		.DAQ_NACK_FLG(DAQ_NACK_FLG), 
		.DAQ_ERR_FLG(DAQ_ERR_FLG), 
		.DAQ_ERR_REG(DAQ_ERR_REG), 
		.TRG_TST_INPRGS(TRG_TST_INPRGS), 
		.TRG_NACK_ERRS(TRG_NACK_ERRS), 
		.TRG_NACK_FLG(TRG_NACK_FLG), 
		.TRG_ERR_FLG(TRG_ERR_FLG), 
		.TRG_ERR_REG(TRG_ERR_REG)
	);

	
   parameter PERIOD = 24;  // CMS clock period (40MHz)

	initial begin  // CMS clock from QPLL 40 MHz
		CLK40 = 1;  // start high
      forever begin
         #(PERIOD/2) begin
				CLK40 = ~CLK40;  //Toggle
			end
		end
	end
	initial begin  // CMS clock from QPLL 40 MHz
		CLK1MHZ = 1;  // start high
      forever begin
         #(20* PERIOD) begin
				CLK1MHZ = ~CLK1MHZ;  //Toggle
			end
		end
	end
	
assign DAQ_LDSDA_RTN = DAQ_LDSDA;
assign TRG_LDSDA_RTN = TRG_LDSDA;


I2C_slave_sim  #(
	.Dev_Addr(8'hFC)
) 
TRG_slave_i(
	.CLK40(CLK40),
	.CLK1MHZ(CLK1MHZ),
	.RST(RST),
	.SCL(COM_LDSCL),
	.SDA(TRG_LDSDA)
);

I2C_slave_sim  #(
	.Dev_Addr(8'hFC)
) 
DAQ_slave_i(
	.CLK40(CLK40),
	.CLK1MHZ(CLK1MHZ),
	.RST(RST),
	.SCL(COM_LDSCL),
	.SDA(DAQ_LDSDA)
);

	initial begin
		// Initialize Inputs
		RST = 1;
		I2C_WRT_FIFO_DATA = 0;
		I2C_WE = 0;
		I2C_RDENA = 0;
		I2C_RESET = 0;
		I2C_START = 0;
		I2C_TEST_ENA_B = 1;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

		#(5*PERIOD);
		RST = 0;
		#(25*PERIOD);
		I2C_RESET = 1;
		#(11*PERIOD);
		I2C_RESET = 0;
		#(25*PERIOD);
		I2C_TEST_ENA_B = 0;

	end
      
endmodule

