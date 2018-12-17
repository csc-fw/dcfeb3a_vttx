`timescale 1ns / 1ps
module test_points(
    input CLK,
    input STUP_CLK,
    input QPLL_LOCK,
    input DAQ_DATA_CLK,
    input CMS80,
    input COMP_CLK,
    input COMP_CLK80,
    input COMP_CLK160,
    input CLK1MHZ,
    input CLK100KHZ,
    input CLK20,
    input ADC_CLK,
    input [2:0] TIMER,
    input TRG_TX_PLL_LOCK,
    input TRG_GTXTXRESET,
    input TRG_TXRESETDONE,
    input TRG_SYNCDONE,
    input TRG_MMCM_LOCK,
    input COMP_RST,
	input cmp_phs_psen,
	input cmp_phs_psdone,
	input cmp_phs_busy,
	input CMP_PHS_JTAG_RST,
	 input  [4:0] CMP_CLK_PHASE,  
	input [10:0] cmp_phase,
	input CMP_PHS_CHANGE,
	input cmp_phs_rst,
	input [2:0] cmp_phs_state,
    input TRG_RST,
    input LCT,
	 input EOS,
	 input RUN,
	 input [3:0] POR_STATE,
	 input DSR_ALGND,
	 input DSR_RST,
	 //
	 input DSR_RESYNC,
	 input RESYNC,
	 input SYS_RST,
	 input ADC_INIT,
	 input L1A,
	 input L1A_MATCH,
	 input L1A_EVT_PUSH,
	 input ALG_GD,
	 input I2C_START,               // Start I2C processing
	 input I2C_CLR_START,           // Clear the I2C_START instruction
	 input [7:0] I2C_STATUS,        // STATUS word for I2C interface
	 input I2C_AT_SCOPE_SYNC,
	 output I2C_TEST_ENA_B,
	 
	 //
//	 input SEL_CON_B, // not used
//	 input SEL_SKW_B, // not used
    inout [2:0] TP_B24_,
    inout [15:0] TP_B25_,
    inout [1:0] TP_B26_,
    inout [14:1] TP_B35_ // bits 9 and 10 are skipped.
    );

  wire [2:0] tp_b24_dir,tp_b24_in,tp_b24_out,dmy24_fab;
  wire [15:0] tp_b25_dir,tp_b25_in,tp_b25_out,dmy25_fab;
  wire [1:0] tp_b26_dir,tp_b26_in,tp_b26_out,dmy26_fab;
  wire [14:1] tp_b35_dir,tp_b35_in,tp_b35_out,dmy35_fab;
	wire jsel_con_b;
	wire jsel_skw_b;
  
  IOBUF #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) IOBUF_TP_B24_[2:0] (.O(tp_b24_in),.IO(TP_B24_),.I(tp_b24_out),.T(tp_b24_dir));
  IOBUF #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) IOBUF_TP_B25_[15:0] (.O(tp_b25_in),.IO(TP_B25_),.I(tp_b25_out),.T(tp_b25_dir));
  IOBUF #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) IOBUF_TP_B26_[1:0] (.O(tp_b26_in),.IO(TP_B26_),.I(tp_b26_out),.T(tp_b26_dir));
  IOBUF #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) IOBUF_TP_B35_[14:1] (.O(tp_b35_in),.IO(TP_B35_),.I(tp_b35_out),.T(tp_b35_dir));

// IBUF IBUF_SEL_CON_B (.O(jsel_con_b),.I(SEL_CON_B));
// IBUF IBUF_SEL_SKW_B (.O(jsel_skw_b),.I(SEL_SKW_B));
// OBUF  #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) OBUF_JSEL_CON_B (.O(JSEL_CON),.I(~jsel_con_b)); //output not assigned
// OBUF  #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) OBUF_JSEL_SKW_B (.O(JSEL_SKW),.I(~jsel_skw_b)); //output not assigned

// Direction control
// 1 is tri-state (input), 0 is drive (output)
 
assign tp_b24_dir = 3'b000;
assign tp_b25_dir = 16'h0000;
assign tp_b26_dir = 2'b11;
//assign tp_b35_dir = 14'h0300;
assign tp_b35_dir = 14'h2300;

PULLUP I2C_test_ena_b_i(.O(TP_B35_[14]));

// Outgoing data to testpoints
//

assign tp_b24_out = 3'b000;
assign tp_b25_out = {DSR_ALGND,DSR_RST,ADC_CLK,CLK20,DSR_RESYNC,CLK,STUP_CLK,QPLL_LOCK,CLK100KHZ,RUN,SYS_RST,EOS,POR_STATE};
//assign tp_b25_out = {cmp_phase[8:4],CLK,CMP_PHS_CHANGE,CMP_PHS_JTAG_RST,cmp_phs_busy,cmp_phs_psdone,cmp_phs_psen,cmp_phs_rst,SYS_RST,cmp_phs_state};
assign tp_b26_out = 2'b00;
assign tp_b35_out = {1'b0,I2C_CLR_START,I2C_AT_SCOPE_SYNC,I2C_START,2'b0,I2C_STATUS};
//assign tp_b35_out = {CMP_CLK_PHASE[4:1],2'b0,CMP_CLK_PHASE[0],COMP_RST,TRG_GTXTXRESET,TRG_MMCM_LOCK,TRG_SYNCDONE,COMP_CLK160,COMP_CLK80,COMP_CLK};
//assign tp_b35_out = {SYS_RST,RESYNC,4'h0,ALG_GD,CLK,1'b0,1'b0,1'b0,L1A_EVT_PUSH,L1A,L1A_MATCH};
//assign tp_b35_out = {SLOW_FIFO_RST,SLOW_FIFO_RST_DONE,AL_START,AL_EXECUTE,2'b0,
//							AUTO_LOAD,AUTO_LOAD_ENA,CLR_AL_DONE,AL_DONE,AL_BKY_WE,WRT_ON_RST,AL_BK_LD_MT,CLK1MHZ};
//
// Incoming data to fabric
//
assign dmy24_fab = tp_b24_in;
assign dmy25_fab = tp_b25_in;
assign dmy26_fab = tp_b26_in;
assign dmy35_fab = tp_b35_in;
assign I2C_TEST_ENA_B = tp_b35_in[14];

endmodule
