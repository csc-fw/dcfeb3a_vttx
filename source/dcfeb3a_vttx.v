`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date:    Tue Feb 01 14:46:42 2011
// Design Name: 
// Module Name:    dcfeb3a
//     Version: 2.19 11/12/12 DAQ on fiber uses 16 bit GTX interface and Dual rate selection -- fixed some bugs added logic analyzer signals
//     Version: 2.18 11/09/12 DAQ on fiber uses 16 bit GTX interface and Dual rate selection 
//     Version: 2.17 11/09/12 Changes to mac_fifo port and signal names didn't get propagated to daq_transceiver_io.  Now fixed.
//     Version: 2.16 11/08/12 registered di-strip output in tmb_fiber_out for half strip test mode to adjust phase by half a clock
//////////////////////////////////////////////////////////////////////////////////
(* syn_encoding = "safe original" *)
module dcfeb3a_vttx #(
	parameter USE_I2C_CHIPSCOPE = 0,
	parameter USE_AUTO_LOAD_CHIPSCOPE = 0,
	parameter USE_CHAN_LINK_CHIPSCOPE = 0,
	parameter USE_DESER_CHIPSCOPE = 0,
	parameter USE_CMP_CHIPSCOPE = 0,
	parameter USE_DAQ_CHIPSCOPE = 0,
	parameter USE_RINGBUF_CHIPSCOPE = 0,
	parameter USE_FF_EMU_CHIPSCOPE = 0,
	parameter USE_SPI_CHIPSCOPE = 0,
	parameter USE_PIPE_CHIPSCOPE = 0,
	parameter USE_SEM_CHIPSCOPE = 0,
	parameter Simulation = 0,
	parameter Strt_dly = 20'h7FFFF,
	parameter POR_tmo = 7'd120,
	parameter ADC_Init_tmo = 12'd1000, // 10ms
	parameter TDIS_pulse_duration = 12'd4000, // 100us
	parameter TDIS_on_Startup = 1,
	parameter xDCFEB = 0,
//	parameter Simulation = 1,
//	parameter Strt_dly = 20'h00000,
//	parameter POR_tmo = 7'd10,
//	parameter ADC_Init_tmo = 12'd1, 
	parameter TMR = 0,
	parameter TMR_Err_Det = 0
	)(

	//Clocks
	input CMS_CLK_N,CMS_CLK_P,CMS80_N,CMS80_P,
	input QPLL_CLK_AC_P,QPLL_CLK_AC_N,XO_CLK_AC_P,XO_CLK_AC_N,
	input GC0N,GC0P,GC1N,GC1P,
	output TP_B35_0N,TP_B35_0P,
	
	//Calibration signals
	input \SKW_EXTPLS- ,\SKW_EXTPLS+ ,
	input \SKW_INJPLS- ,\SKW_INJPLS+ ,
	input INJPLS_LV,
	input EXTPLS_LV,
	output \INJPULSE- ,\INJPULSE+ ,
	output \EXTPULSE- ,\EXTPULSE+ ,
	
	//SPI signals
	input SPI_RTN_LV,
	output SPI_CK_LV, SPI_DAT_LV,
	output ADC_CS_LV_B,
	output CAL_DAC_CS_LV_B,
	output COMP_DAC_CS_LV_B,
	
	//I2C signals
	inout DAQ_SDA,
//	input DAQ_SDA_RTN,
	inout TRG_SDA,
//	input TRG_SDA_RTN,
	output COM_SCK,

   //PROM Configuration signals
   inout  [22:0] BPI_AD,
   inout  [15:0] CFG_DAT,
   output BPI_AD21_RS0, BPI_AD22_RS1,
   output FCS_B, FOE_B, FWE_B, FLATCH_B,
	
   //Buckeye slow control signals
   input  G1SHOUTLV,G2SHOUTLV,G3SHOUTLV,G4SHOUTLV,G5SHOUTLV,G6SHOUTLV,
   output G1SHINLV,G2SHINLV,G3SHINLV,G4SHINLV,G5SHINLV,G6SHINLV,
   output G1SHCKLV,G2SHCKLV,G3SHCKLV,G4SHCKLV,G5SHCKLV,G6SHCKLV,
	
   //ADC differential serial datat inputs
   input [15:0] G1AD_N,G1AD_P,G2AD_N,G2AD_P,G3AD_N,G3AD_P,G4AD_N,G4AD_P,G5AD_N,G5AD_P,G6AD_N,G6AD_P,
	
   //ADC clock inputs
   input G1ADCLK0N,G1ADCLK0P,G1ADCLK1N,G1ADCLK1P,G1LCLK0N,G1LCLK0P,G1LCLK1N,G1LCLK1P,
   input G2ADCLK0N,G2ADCLK0P,G2ADCLK1N,G2ADCLK1P,G2LCLK0N,G2LCLK0P,G2LCLK1N,G2LCLK1P,
   input G3ADCLK0N,G3ADCLK0P,G3ADCLK1N,G3ADCLK1P,G3LCLK0N,G3LCLK0P,G3LCLK1N,G3LCLK1P,
   input G4ADCLK0N,G4ADCLK0P,G4ADCLK1N,G4ADCLK1P,G4LCLK0N,G4LCLK0P,G4LCLK1N,G4LCLK1P,
   input G5ADCLK0N,G5ADCLK0P,G5ADCLK1N,G5ADCLK1P,G5LCLK0N,G5LCLK0P,G5LCLK1N,G5LCLK1P,
   input G6ADCLK0N,G6ADCLK0P,G6ADCLK1N,G6ADCLK1P,G6LCLK0N,G6LCLK0P,G6LCLK1N,G6LCLK1P,
	
   //ADC control outputs
   output G1ADC_CS0_B_25,G1ADC_CS1_B_25,G2ADC_CS0_B_25,G2ADC_CS1_B_25,G3ADC_CS0_B_25,G3ADC_CS1_B_25,
   output G4ADC_CS0_B_25,G4ADC_CS1_B_25,G5ADC_CS0_B_25,G5ADC_CS1_B_25,G6ADC_CS0_B_25,G6ADC_CS1_B_25,
   output ADC_RST_B_25,
   output ADC_SCLK_25,
   output ADC_SDATA_25,
   output GA1ADCCLK_FN,GA1ADCCLK_FP,
   output GA2ADCCLK_FN,GA2ADCCLK_FP,
   output GA3ADCCLK_FN,GA3ADCCLK_FP,
	
	//Comparator signals
	input [7:0] G1C_LV, G2C_LV, G3C_LV, G4C_LV, G5C_LV, G6C_LV,  //Comparator data inputs
	output [1:0] CMODE,
	output [2:0] CTIME,
	output LCTCLK, LCTRST,
	
	
	//Channel Link signals
	output [15:0] DATAOUT,
	output CHAN_LNK_CLK,MB_FIFO_PUSH_B,MOVLP,OVLPMUX,DATAAVAIL,ENDWORD,
	
	//Trigger and sync signals
	input \SKW_L1A- ,\SKW_L1A+ ,
//	input \SKW_LCT- ,\SKW_LCT+ , // Names used on DCFEB Rev. 2a boards and in firmware version dcfeb_f2.0
	input \SKW_L1A_MATCH- ,\SKW_L1A_MATCH+ , // Names used on DCFEB Rev. 3b boards and in firmware version dcfeb_f3.0
	input \SKW_RESYNC- ,\SKW_RESYNC+ ,
	input \SKW_BC0- ,\SKW_BC0+ , // Only used on DCFEB Rev. 3b boards and in firmware version dcfeb_f3.0
	
	//Optical Transceiver signals
	input  DAQ_RX_P,DAQ_RX_N,
//	output DAQ_TDIS, // Repurposed on dcfeb_vttx to COM_SCK
	output DAQ_TX_P,DAQ_TX_N,
//	input  ALT_SIGDET, // receiver signal detected (not used on DCFEB and non existant on xDCFEBs
	input  TRG_RX_P,TRG_RX_N,
	output TRG_TDIS,
	output TRG_TX_P,TRG_TX_N,
	output CTRL_TDIS,
//	input  OPCON_RXP,OPCON_RXN, // Optional transceiver connection only on DCFEB Rev. 3b boards
//	output OPCON_TXP,OPCON_TXN, // Optional transceiver connection only on DCFEB Rev. 3b boards
	
	//QPLL signals
	input QP_ERROR,QP_LOCKED,  // These I/O buffs are found in rsm1 reset_manager
	output QP_RST_B,
	
	//System monitor signals
	input DV4P_3_CUR_P, DV4P_3_CUR_N, DV3P_2_CUR_N, DV3P_2_CUR_P, DV3P_25_CUR_N, DV3P_25_CUR_P,
	input V3PDCOMP_MONN, V3PDCOMP_MONP, V3PIO_MONN, V3PIO_MONP, V25IO_MONN, V25IO_MONP,
	input V5PACOMP_MONN, V5PACOMP_MONP, V5PSUB_MONN, V5PSUB_MONP, V5PPA_MONP, V5PPA_MONN,
	input V33PAADC_MONP, V33PAADC_MONN, V18PDADC_MONP, V18PDADC_MONN, V5PAMP_MONP, V5PAMP_MONN,
//	input AV55P_3_CUR_N, AV55P_3_CUR_P,  // Names used on DCFEB Rev. 2a boards and in firmware version dcfeb_f2.0
//	input AV55P_5_CUR_N, AV55P_5_CUR_P,  // Names used on DCFEB Rev. 2a boards and in firmware version dcfeb_f2.0
	input AV54P_3_CUR_N, AV54P_3_CUR_P,  // Names used on DCFEB Rev. 3b boards and in firmware version dcfeb_f3.0
	input AV54P_5_CUR_N, AV54P_5_CUR_P,  // Names used on DCFEB Rev. 3b boards and in firmware version dcfeb_f3.0
	
	//Diagnostic & misc. signals: Logic analyzer and test piont ports
//	input SEL_SKW,SEL_CON, // Names used on DCFEB Rev. 2a boards and in firmware version dcfeb_f2.0
//	input SEL_SKW_B,SEL_CON_B, // Names used on DCFEB Rev. 3b boards and in firmware version dcfeb_f3.0 // no longer used
	inout [2:0] TP_B24_,
	inout [15:0] TP_B25_,
	inout [1:0] TP_B26_,
	inout [14:1] TP_B35_ // bits 9 and 10 are skipped.
);

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//  Chip Scope Pro Control module                                          //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////
	wire [35:0] adc_mem_vio_c0;
	wire [35:0] adc_cnfg_mem_la_c1;
	wire [35:0] DAQ_tx_vio_c3;
	wire [35:0] DAQ_tx_la_c4;
	wire [35:0] rd_fifo2_la_c5;
	wire [35:0] bpi_vio_c6;
	wire [35:0] bpi_la_c7;
	wire [35:0] cmp_tx_vio_c0;
	wire [35:0] cmp_tx_la_c1;
	wire [35:0] g1la0_c0;
	wire [35:0] g1vio0_c0;
	wire [35:0] pipe_la0_c0;
	wire [35:0] pipe_vio_in0_c1;
	wire [35:0] pipe_vio_out1_c2;
	wire [35:0] sem_la0_c0;
	wire [35:0] sem_vio_in0_c1;
	wire [35:0] rng_ff1_la0_c0;
	wire [35:0] rng_buf_la0_c1;
	wire [35:0] rng_eth_la0_c2;
	wire [35:0] rng_chn_la0_c3;
	wire [35:0] rng_xfr_la0_c3;
	wire [35:0] chn_lnk_la0_c0;
	wire [35:0] auto_load_vio_c0;
	wire [35:0] auto_load_la0_c1;



generate
if(USE_AUTO_LOAD_CHIPSCOPE==1) 
begin : chipscope_with_auto_load_const
CSP_auto_load_cntrl CSP_auto_load_cntrl_i (
    .CONTROL0(auto_load_vio_c0), // INOUT BUS [35:0]
    .CONTROL1(auto_load_la0_c1) // INOUT BUS [35:0]
);
	assign g1vio0_c0 = 36'h000000000;
	assign g1la0_c0 = 36'h000000000;
	assign adc_mem_vio_c0 = 36'h000000000;
	assign adc_cnfg_mem_la_c1 = 36'h000000000;
	assign DAQ_tx_vio_c3 = 36'h000000000;
	assign DAQ_tx_la_c4 = 36'h000000000;
	assign rd_fifo2_la_c5 = 36'h000000000;
	assign bpi_vio_c6 = 36'h000000000;
	assign bpi_la_c7 = 36'h000000000;
	assign cmp_tx_vio_c0 = 36'h000000000;
	assign cmp_tx_la_c1 = 36'h000000000;
	assign pipe_la0_c0 = 36'h000000000;
	assign pipe_vio_in0_c1 = 36'h000000000;
	assign pipe_vio_out1_c2 = 36'h000000000;
	assign sem_la0_c0 = 36'h000000000;
	assign sem_vio_in0_c1 = 36'h000000000;
	assign rng_ff1_la0_c0 = 36'h000000000;
	assign rng_buf_la0_c1 = 36'h000000000;
	assign rng_eth_la0_c2 = 36'h000000000;
	assign rng_chn_la0_c3 = 36'h000000000;
	assign rng_xfr_la0_c3 = 36'h000000000;
	assign chn_lnk_la0_c0 = 36'h000000000;
end
else if(USE_CHAN_LINK_CHIPSCOPE==1) 
begin : chipscope_with_chan_link_fifo
CSP_chan_link_cntrl CSP_chan_link_cntrl_i (
    .CONTROL0(chn_lnk_la0_c0) // INOUT BUS [35:0]
);
	assign g1vio0_c0 = 36'h000000000;
	assign g1la0_c0 = 36'h000000000;
	assign adc_mem_vio_c0 = 36'h000000000;
	assign adc_cnfg_mem_la_c1 = 36'h000000000;
	assign DAQ_tx_vio_c3 = 36'h000000000;
	assign DAQ_tx_la_c4 = 36'h000000000;
	assign rd_fifo2_la_c5 = 36'h000000000;
	assign bpi_vio_c6 = 36'h000000000;
	assign bpi_la_c7 = 36'h000000000;
	assign cmp_tx_vio_c0 = 36'h000000000;
	assign cmp_tx_la_c1 = 36'h000000000;
	assign pipe_la0_c0 = 36'h000000000;
	assign pipe_vio_in0_c1 = 36'h000000000;
	assign pipe_vio_out1_c2 = 36'h000000000;
	assign sem_la0_c0 = 36'h000000000;
	assign sem_vio_in0_c1 = 36'h000000000;
	assign rng_ff1_la0_c0 = 36'h000000000;
	assign rng_buf_la0_c1 = 36'h000000000;
	assign rng_eth_la0_c2 = 36'h000000000;
	assign rng_chn_la0_c3 = 36'h000000000;
	assign rng_xfr_la0_c3 = 36'h000000000;
	assign auto_load_vio_c0 = 36'h000000000;
	assign auto_load_vio_c0 = 36'h000000000;
	assign auto_load_la0_c1 = 36'h000000000;
end
else if(USE_CMP_CHIPSCOPE==1 && USE_DAQ_CHIPSCOPE==1 && USE_DESER_CHIPSCOPE==0 && USE_RINGBUF_CHIPSCOPE == 0) 
begin : chipscope_with_comp_and_daq
CSP_comp_daq_cntrl cmp_daq_cntrl1 (
    .CONTROL0(adc_mem_vio_c0), // INOUT BUS [35:0]
    .CONTROL1(adc_cnfg_mem_la_c1), // INOUT BUS [35:0]
    .CONTROL2(rng_ff1_la0_c0), // INOUT BUS [35:0]
    .CONTROL3(DAQ_tx_vio_c3), // INOUT BUS [35:0]
    .CONTROL4(DAQ_tx_la_c4), // INOUT BUS [35:0]
    .CONTROL5(rd_fifo2_la_c5), // INOUT BUS [35:0]
    .CONTROL6(bpi_vio_c6), // INOUT BUS [35:0]
    .CONTROL7(bpi_la_c7), // INOUT BUS [35:0]
    .CONTROL8(cmp_tx_vio_c0), // INOUT BUS [35:0]
    .CONTROL9(cmp_tx_la_c1)  // INOUT BUS [35:0]
);
	assign pipe_la0_c0 = 36'h000000000;
	assign pipe_vio_in0_c1 = 36'h000000000;
	assign pipe_vio_out1_c2 = 36'h000000000;
	assign sem_la0_c0 = 36'h000000000;
	assign sem_vio_in0_c1 = 36'h000000000;
	assign rng_buf_la0_c1 = 36'h000000000;
	assign rng_eth_la0_c2 = 36'h000000000;
	assign rng_chn_la0_c3 = 36'h000000000;
	assign rng_xfr_la0_c3 = 36'h000000000;
	assign chn_lnk_la0_c0 = 36'h000000000;
	assign auto_load_vio_c0 = 36'h000000000;
	assign auto_load_la0_c1 = 36'h000000000;
end
else if(USE_CMP_CHIPSCOPE==1 && USE_DAQ_CHIPSCOPE==0 && USE_DESER_CHIPSCOPE==0 && USE_RINGBUF_CHIPSCOPE == 0) 
begin : chipscope_with_comp_no_daq
 
CSP_comp_cntrl comp_cntrl1 (
    .CONTROL0(cmp_tx_vio_c0), // INOUT BUS [35:0]
    .CONTROL1(cmp_tx_la_c1)  // INOUT BUS [35:0]
);

	assign adc_mem_vio_c0 = 36'h000000000;
	assign adc_cnfg_mem_la_c1 = 36'h000000000;
	assign DAQ_tx_vio_c3 = 36'h000000000;
	assign DAQ_tx_la_c4 = 36'h000000000;
	assign rd_fifo2_la_c5 = 36'h000000000;
	assign bpi_vio_c6 = 36'h000000000;
	assign bpi_la_c7 = 36'h000000000;
	assign pipe_la0_c0 = 36'h000000000;
	assign pipe_vio_in0_c1 = 36'h000000000;
	assign pipe_vio_out1_c2 = 36'h000000000;
	assign sem_la0_c0 = 36'h000000000;
	assign sem_vio_in0_c1 = 36'h000000000;
	assign rng_ff1_la0_c0 = 36'h000000000;
	assign rng_buf_la0_c1 = 36'h000000000;
	assign rng_eth_la0_c2 = 36'h000000000;
	assign rng_chn_la0_c3 = 36'h000000000;
	assign rng_xfr_la0_c3 = 36'h000000000;
	assign chn_lnk_la0_c0 = 36'h000000000;
	assign auto_load_vio_c0 = 36'h000000000;
	assign auto_load_la0_c1 = 36'h000000000;
end
else if(USE_CMP_CHIPSCOPE==0 && USE_DAQ_CHIPSCOPE==1 && USE_DESER_CHIPSCOPE==0 && USE_RINGBUF_CHIPSCOPE == 0) 
begin : chipscope_with_daq_no_comp
CSP_daq_cntrl daq_cntrl1 (
    .CONTROL0(adc_mem_vio_c0), // INOUT BUS [35:0]
    .CONTROL1(adc_cnfg_mem_la_c1), // INOUT BUS [35:0]
    .CONTROL2(rng_ff1_la0_c0), // INOUT BUS [35:0]
    .CONTROL3(DAQ_tx_vio_c3), // INOUT BUS [35:0]
    .CONTROL4(DAQ_tx_la_c4), // INOUT BUS [35:0]
    .CONTROL5(rd_fifo2_la_c5), // INOUT BUS [35:0]
    .CONTROL6(bpi_vio_c6), // INOUT BUS [35:0]
    .CONTROL7(bpi_la_c7) // INOUT BUS [35:0]
);

	assign cmp_tx_vio_c0 = 36'h000000000;
	assign cmp_tx_la_c1 = 36'h000000000;
	assign pipe_la0_c0 = 36'h000000000;
	assign pipe_vio_in0_c1 = 36'h000000000;
	assign pipe_vio_out1_c2 = 36'h000000000;
	assign sem_la0_c0 = 36'h000000000;
	assign sem_vio_in0_c1 = 36'h000000000;
	assign rng_buf_la0_c1 = 36'h000000000;
	assign rng_eth_la0_c2 = 36'h000000000;
	assign rng_chn_la0_c3 = 36'h000000000;
	assign rng_xfr_la0_c3 = 36'h000000000;
	assign chn_lnk_la0_c0 = 36'h000000000;
	assign auto_load_vio_c0 = 36'h000000000;
	assign auto_load_la0_c1 = 36'h000000000;
end
else if(USE_CMP_CHIPSCOPE==0 && USE_DAQ_CHIPSCOPE==0 && USE_DESER_CHIPSCOPE==1) 
begin : chipscope_with_deser
CSP_deser_cntrl deser_cntrl1 (
    .CONTROL0(g1vio0_c0), // INOUT BUS [35:0]
    .CONTROL1(g1la0_c0),  // INOUT BUS [35:0]
    .CONTROL2(adc_mem_vio_c0), // INOUT BUS [35:0]
    .CONTROL3(adc_cnfg_mem_la_c1) // INOUT BUS [35:0]
);

	assign DAQ_tx_vio_c3 = 36'h000000000;
	assign DAQ_tx_la_c4 = 36'h000000000;
	assign rd_fifo2_la_c5 = 36'h000000000;
	assign bpi_vio_c6 = 36'h000000000;
	assign bpi_la_c7 = 36'h000000000;
	assign cmp_tx_vio_c0 = 36'h000000000;
	assign cmp_tx_la_c1 = 36'h000000000;
	assign pipe_la0_c0 = 36'h000000000;
	assign pipe_vio_in0_c1 = 36'h000000000;
	assign pipe_vio_out1_c2 = 36'h000000000;
	assign sem_la0_c0 = 36'h000000000;
	assign sem_vio_in0_c1 = 36'h000000000;
	assign rng_ff1_la0_c0 = 36'h000000000;
	assign rng_buf_la0_c1 = 36'h000000000;
	assign rng_eth_la0_c2 = 36'h000000000;
	assign rng_chn_la0_c3 = 36'h000000000;
	assign rng_xfr_la0_c3 = 36'h000000000;
	assign chn_lnk_la0_c0 = 36'h000000000;
	assign auto_load_vio_c0 = 36'h000000000;
	assign auto_load_la0_c1 = 36'h000000000;
end
else if(USE_CMP_CHIPSCOPE==0 && USE_DAQ_CHIPSCOPE==0 && USE_DESER_CHIPSCOPE==0 && USE_PIPE_CHIPSCOPE == 1) 
begin : chipscope_with_pipeline
CSP_pipe_cntrl pipe_cntrl1 (
    .CONTROL0(pipe_la0_c0), // INOUT BUS [35:0]
    .CONTROL1(pipe_vio_in0_c1),  // INOUT BUS [35:0]
    .CONTROL2(pipe_vio_out1_c2) // INOUT BUS [35:0]
);
	assign g1vio0_c0 = 36'h000000000;
	assign g1la0_c0 = 36'h000000000;
	assign adc_mem_vio_c0 = 36'h000000000;
	assign adc_cnfg_mem_la_c1 = 36'h000000000;
	assign DAQ_tx_vio_c3 = 36'h000000000;
	assign DAQ_tx_la_c4 = 36'h000000000;
	assign rd_fifo2_la_c5 = 36'h000000000;
	assign bpi_vio_c6 = 36'h000000000;
	assign bpi_la_c7 = 36'h000000000;
	assign cmp_tx_vio_c0 = 36'h000000000;
	assign cmp_tx_la_c1 = 36'h000000000;
	assign sem_la0_c0 = 36'h000000000;
	assign sem_vio_in0_c1 = 36'h000000000;
	assign rng_ff1_la0_c0 = 36'h000000000;
	assign rng_buf_la0_c1 = 36'h000000000;
	assign rng_eth_la0_c2 = 36'h000000000;
	assign rng_chn_la0_c3 = 36'h000000000;
	assign rng_xfr_la0_c3 = 36'h000000000;
	assign chn_lnk_la0_c0 = 36'h000000000;
	assign auto_load_vio_c0 = 36'h000000000;
	assign auto_load_la0_c1 = 36'h000000000;
end
else if(USE_CMP_CHIPSCOPE==0 && USE_DAQ_CHIPSCOPE==0 && USE_DESER_CHIPSCOPE==0 && USE_PIPE_CHIPSCOPE == 0 && USE_SEM_CHIPSCOPE == 1) 
begin : chipscope_with_SEM
CSP_sem_cntrl sem_cntrl1 (
    .CONTROL0(sem_la0_c0), // INOUT BUS [35:0]
    .CONTROL1(sem_vio_in0_c1)  // INOUT BUS [35:0]
);
	assign g1vio0_c0 = 36'h000000000;
	assign g1la0_c0 = 36'h000000000;
	assign adc_mem_vio_c0 = 36'h000000000;
	assign adc_cnfg_mem_la_c1 = 36'h000000000;
	assign DAQ_tx_vio_c3 = 36'h000000000;
	assign DAQ_tx_la_c4 = 36'h000000000;
	assign rd_fifo2_la_c5 = 36'h000000000;
	assign bpi_vio_c6 = 36'h000000000;
	assign bpi_la_c7 = 36'h000000000;
	assign cmp_tx_vio_c0 = 36'h000000000;
	assign cmp_tx_la_c1 = 36'h000000000;
	assign pipe_vio_in0_c1 = 36'h000000000;
	assign pipe_vio_out1_c2 = 36'h000000000;
	assign rng_ff1_la0_c0 = 36'h000000000;
	assign rng_buf_la0_c1 = 36'h000000000;
	assign rng_eth_la0_c2 = 36'h000000000;
	assign rng_chn_la0_c3 = 36'h000000000;
	assign rng_xfr_la0_c3 = 36'h000000000;
	assign chn_lnk_la0_c0 = 36'h000000000;
	assign auto_load_vio_c0 = 36'h000000000;
	assign auto_load_la0_c1 = 36'h000000000;
end
else if(USE_CMP_CHIPSCOPE==0 && USE_DAQ_CHIPSCOPE==0 && USE_DESER_CHIPSCOPE==0 && USE_PIPE_CHIPSCOPE == 0 && USE_SEM_CHIPSCOPE == 0 && USE_RINGBUF_CHIPSCOPE == 1) 
begin : chipscope_with_Ring_Buf
CSP_rngbuf_cntrl rngbuf_cntrl1 (
    .CONTROL0(rng_ff1_la0_c0), // INOUT BUS [35:0]
    .CONTROL1(rng_buf_la0_c1), // INOUT BUS [35:0]
    .CONTROL2(rng_eth_la0_c2), // INOUT BUS [35:0]
//    .CONTROL3(rng_chn_la0_c3)  // INOUT BUS [35:0]
    .CONTROL3(rng_xfr_la0_c3)  // INOUT BUS [35:0]
);
	assign g1vio0_c0 = 36'h000000000;
	assign g1la0_c0 = 36'h000000000;
	assign adc_mem_vio_c0 = 36'h000000000;
	assign adc_cnfg_mem_la_c1 = 36'h000000000;
	assign DAQ_tx_vio_c3 = 36'h000000000;
	assign DAQ_tx_la_c4 = 36'h000000000;
	assign rd_fifo2_la_c5 = 36'h000000000;
	assign bpi_vio_c6 = 36'h000000000;
	assign bpi_la_c7 = 36'h000000000;
	assign cmp_tx_vio_c0 = 36'h000000000;
	assign cmp_tx_la_c1 = 36'h000000000;
	assign pipe_vio_in0_c1 = 36'h000000000;
	assign pipe_vio_out1_c2 = 36'h000000000;
	assign chn_lnk_la0_c0 = 36'h000000000;
	assign auto_load_vio_c0 = 36'h000000000;
	assign auto_load_la0_c1 = 36'h000000000;
end
else if(USE_CMP_CHIPSCOPE==0 && USE_DAQ_CHIPSCOPE==1 && USE_DESER_CHIPSCOPE==0 && USE_PIPE_CHIPSCOPE == 0 && USE_SEM_CHIPSCOPE == 0 && USE_RINGBUF_CHIPSCOPE == 1) 
begin : chipscope_with_Ring_Buf
CSP_rngbuf_daq rngbuf_daq1 (
    .CONTROL0(rng_ff1_la0_c0), // INOUT BUS [35:0]
    .CONTROL1(rng_buf_la0_c1), // INOUT BUS [35:0]
    .CONTROL2(rng_eth_la0_c2), // INOUT BUS [35:0]
    .CONTROL3(rng_xfr_la0_c3),  // INOUT BUS [35:0]
    .CONTROL4(DAQ_tx_vio_c3), // INOUT BUS [35:0]
    .CONTROL5(DAQ_tx_la_c4) // INOUT BUS [35:0]
);
	
	assign g1vio0_c0 = 36'h000000000;
	assign g1la0_c0 = 36'h000000000;
	assign adc_mem_vio_c0 = 36'h000000000;
	assign adc_cnfg_mem_la_c1 = 36'h000000000;
	assign rd_fifo2_la_c5 = 36'h000000000;
	assign bpi_vio_c6 = 36'h000000000;
	assign bpi_la_c7 = 36'h000000000;
	assign cmp_tx_vio_c0 = 36'h000000000;
	assign cmp_tx_la_c1 = 36'h000000000;
	assign pipe_la0_c0 = 36'h000000000;
	assign pipe_vio_in0_c1 = 36'h000000000;
	assign pipe_vio_out1_c2 = 36'h000000000;
	assign sem_la0_c0 = 36'h000000000;
	assign sem_vio_in0_c1 = 36'h000000000;
	assign rng_chn_la0_c3 = 36'h000000000;
	assign chn_lnk_la0_c0 = 36'h000000000;
	assign auto_load_vio_c0 = 36'h000000000;
	assign auto_load_la0_c1 = 36'h000000000;
end
else
begin : no_chipscope
	assign g1vio0_c0 = 36'h000000000;
	assign g1la0_c0 = 36'h000000000;
	assign adc_mem_vio_c0 = 36'h000000000;
	assign adc_cnfg_mem_la_c1 = 36'h000000000;
	assign DAQ_tx_vio_c3 = 36'h000000000;
	assign DAQ_tx_la_c4 = 36'h000000000;
	assign rd_fifo2_la_c5 = 36'h000000000;
	assign bpi_vio_c6 = 36'h000000000;
	assign bpi_la_c7 = 36'h000000000;
	assign cmp_tx_vio_c0 = 36'h000000000;
	assign cmp_tx_la_c1 = 36'h000000000;
	assign pipe_la0_c0 = 36'h000000000;
	assign pipe_vio_in0_c1 = 36'h000000000;
	assign pipe_vio_out1_c2 = 36'h000000000;
	assign sem_la0_c0 = 36'h000000000;
	assign sem_vio_in0_c1 = 36'h000000000;
	assign rng_ff1_la0_c0 = 36'h000000000;
	assign rng_buf_la0_c1 = 36'h000000000;
	assign rng_eth_la0_c2 = 36'h000000000;
	assign rng_chn_la0_c3 = 36'h000000000;
	assign rng_xfr_la0_c3 = 36'h000000000;
	assign chn_lnk_la0_c0 = 36'h000000000;
	assign auto_load_vio_c0 = 36'h000000000;
	assign auto_load_la0_c1 = 36'h000000000;
end
endgenerate



 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Clock source and management                                            //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////

   wire sys_rst;
	wire cms80;
	wire icap_clk;
	wire icap_clk_ena;
	wire daq_tx_125_refclk,daq_tx_125_refclk_dv2;
	wire trg_tx_160_refclk;
	wire comp_clk;
	wire comp_clk80;
	wire comp_clk160;
	wire [4:0] cmp_clk_phase;
	wire [2:0] samp_clk_phase;
	wire clk100khz;

	wire trg_tx_pll_lock;
	wire trg_mmcm_lock;
	wire clk160,clk120,clk40,clk20,clk1mhz;
	wire mmcm_rst, daq_mmcm_lock;
	wire strtup_clk, eos;
	wire adc_clk;
	wire dsr_resync;
	wire resync;

	wire resync_d1;
	wire lead_edg_resync;
	wire lead_edg_resync_d1;
	wire cap_phase;
	wire [7:0] rst_mmcm_pipe;
	wire samp_clk_phs_chng;
	wire cmp_phs_jtag_rst;
	wire cmp_phs_psen;
	wire cmp_phs_psdone;
	wire cmp_phs_busy;
	wire [10:0] cmp_phase;
	wire cmp_phs_change;
	wire cmp_phs_rst;
	wire [2:0] cmp_phs_state;
	wire [15:0] cmp_phs_errcnt;
	wire [15:0] fifo_load_errcnt;
	wire [15:0] xf2rb_errcnt;
	wire [15:0] rgtrns_errcnt;
	wire [15:0] smpprc_errcnt;
	wire [15:0] frmprc_errcnt;
	
	Clock_sources #(
		.Simulation(Simulation),
		.TMR(TMR),
		.TMR_Err_Det(TMR_Err_Det)
	)
	Clk_src1(
	   // External inputs
		.CMS_CLK_N(CMS_CLK_N), .CMS_CLK_P(CMS_CLK_P),                      // from QPLL
		.CMS80_N(CMS80_N), .CMS80_P(CMS80_P),                              // from QPLL
		.QPLL_CLK_AC_N(QPLL_CLK_AC_N), .QPLL_CLK_AC_P(QPLL_CLK_AC_P),      // alternate clock 160 MHz Ref for TRG GTX (from QPLL)
		.XO_CLK_AC_N(XO_CLK_AC_N), .XO_CLK_AC_P(XO_CLK_AC_P),              // Crystal Osc. 125 MHz    Ref for DAQ GTX for GbE
		.GC0N(GC0N), .GC0P(GC0P), .GC1N(GC1N), .GC1P(GC1P),                // Spare global clock inputs
		.CMP_PHS_JTAG_RST(cmp_phs_jtag_rst), // on demand reset of comparator MMCM and dynamic phase state machine
		.CMP_CLK_PHASE(cmp_clk_phase),    // Comparator Clock Phase 5 bits (0-31)
		.SAMP_CLK_PHASE(samp_clk_phase),    // Comparator Clock Phase (0-15)
		.SAMP_CLK_PHS_CHNG(samp_clk_phs_chng), // Sampling Clock Phase Change in progress; Reset deserializers.
		.TP_B35_0N(TP_B35_0N), .TP_B35_0P(TP_B35_0P),                                  // Test point clock output
	   // Internal inputs
		.RST(sys_rst),
		.RESYNC(resync),
      .ICAP_CLK_ENA(icap_clk_ena),       // ICAP Clock Enable for holding off initialization.
		.DAQ_MMCM_RST(mmcm_rst),
	   // Internal outputs
		.CMS80(cms80),
		.DAQ_TX_125_REFCLK(daq_tx_125_refclk),
		.DAQ_TX_125_REFCLK_DV2(daq_tx_125_refclk_dv2),
		.TRG_TX_160_REFCLK(trg_tx_160_refclk),
		.COMP_CLK(comp_clk),              // comparator clock 
		.COMP_CLK80(comp_clk80),          // comparator GTX USRCLK2
		.COMP_CLK160(comp_clk160),          // comparator GTX USRCLK
		.CMP_PHS_CHANGE(cmp_phs_change),     // Comp Clock Phase Change in progress; Reset TMB path transceiver.
		.TRG_MMCM_LOCK(trg_mmcm_lock),
		.CLK160(clk160),
		.CLK120(clk120),
		.CLK40(clk40),
		.CLK20(clk20),
		.CLK1MHZ(clk1mhz),
		.CLK100KHZ(clk100khz),
      .ICAP_CLK(icap_clk),       // Clock Enabled 40MHz clock
		.ADC_CLK(adc_clk),
		.DSR_RESYNC(dsr_resync),
		.DAQ_MMCM_LOCK(daq_mmcm_lock),
		.STRTUP_CLK(strtup_clk),           // internal config clock for power on state machines in reset manager
		.EOS(eos),                          // End Of Startup
		.CMP_PHS_ERRCNT(cmp_phs_errcnt),
		.RESYNC_D1(resync_d1),
		.LEAD_EDG_RESYNC(lead_edg_resync),
		.LEAD_EDG_RESYNC_D1(lead_edg_resync_d1),
		.CAP_PHASE(cap_phase),
		.RST_MMCM_PIPE(rst_mmcm_pipe),
		.CMP_PHASE(cmp_phase),    // translated comp Phase 11 bits (0-1344)
		.CMP_PHS_PSEN(cmp_phs_psen),
		.CMP_PHS_PSDONE(cmp_phs_psdone),
		.CMP_PHS_BUSY(cmp_phs_busy),
		.CMP_PHS_RST(cmp_phs_rst),
		.CMP_PHS_STATE(cmp_phs_state)
	);
  

 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  DCFEB Status word                                                      //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////
 reg [15:0] dcfeb_status;
 wire [15:0] startup_status;
 reg  [7:0] qpll_cnt;
 wire [2:0]al_status;
 wire [3:0] por_state;
 wire al_start;
 wire run;
 wire adc_rdy;
 wire [1:0]ttc_src;
 wire [2:0]tmb_tx_mode;
 wire qpll_lock;
 reg  qpll_lock_r1;
 wire falling_edge_qpll;
 wire qpll_error;
 wire qpll_cnt_full;
 reg  qpll_cnt_full_r1;
 reg  qpll_cnt_ovrflw;
 wire jdaq_rate;
 wire rate_1_25;
 wire rate_3_2;
 wire [11:0] bc0cnt;
 wire csp_man_ctrl;
 wire use_any_l1a, juse_any_l1a, csp_use_any_l1a;
 wire l1a_head, jl1a_head, csp_l1a_head;
 wire user_temp_alarm;

// Results of I2C auto testing
wire I2C_test_ena_b;
wire daq_tst_inprgs;
wire daq_nack_errs;
wire daq_nack_flg;
wire daq_err_flg;
wire [3:0] daq_err_reg;
wire trg_tst_inprgs;
wire trg_nack_errs;
wire trg_nack_flg;
wire trg_err_flg;
wire [3:0] trg_err_reg;

 assign use_any_l1a = csp_man_ctrl ? csp_use_any_l1a : juse_any_l1a;
 assign l1a_head = csp_man_ctrl ? csp_l1a_head : jl1a_head;
// assign dcfeb_status = {qpll_lock,qpll_error,l1a_head,use_any_l1a,bc0cnt[3:0],rate_3_2,rate_1_25,jdaq_rate,tmb_tx_mode,ttc_src};
// assign dcfeb_status = {qpll_lock,qpll_error,l1a_head,use_any_l1a,por_state,rate_3_2,rate_1_25,jdaq_rate,tmb_tx_mode,ttc_src};
// assign dcfeb_status = {qpll_lock,qpll_error,l1a_head,use_any_l1a,  user_temp_alarm,al_status,  rate_3_2,rate_1_25,jdaq_rate,tmb_tx_mode,ttc_src};
 assign startup_status = {qpll_lock,qpll_error,qpll_cnt_ovrflw,1'b0,trg_mmcm_lock,daq_mmcm_lock,adc_rdy,run,al_status,eos,por_state};

always @* begin
	if(I2C_test_ena_b) 
		dcfeb_status = {qpll_lock,qpll_error,l1a_head,use_any_l1a,  user_temp_alarm,al_status,  rate_3_2,rate_1_25,jdaq_rate,tmb_tx_mode,ttc_src};
	else
		dcfeb_status = {daq_err_reg, daq_nack_errs, daq_nack_flg, daq_err_flg, daq_tst_inprgs, trg_err_reg, trg_nack_errs, trg_nack_flg, trg_err_flg, trg_tst_inprgs};
end

assign falling_edge_qpll = ~qpll_lock & qpll_lock_r1;
assign qpll_cnt_full     = (qpll_cnt == 8'hFF);
always @(posedge clk40) begin
	qpll_lock_r1 <= qpll_lock;
	qpll_cnt_full_r1 <= qpll_cnt_full;
end
always @(posedge clk40 or posedge sys_rst) begin
	if(sys_rst)
		qpll_cnt <= 8'h00;
	else
		if(falling_edge_qpll)
			qpll_cnt <= qpll_cnt + 1;
		else
			qpll_cnt <= qpll_cnt;
end
always @(posedge clk40 or posedge sys_rst) begin
	if(sys_rst)
		qpll_cnt_ovrflw <= 1'b0;
	else
		if(qpll_cnt_full_r1 && (qpll_cnt == 8'h00))
			qpll_cnt_ovrflw <= 1'b1;
		else
			qpll_cnt_ovrflw <= qpll_cnt_ovrflw;
end
 
 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  BPI controller for XCF128 flash PROM                                   //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////
 // BPI intreface signals
 wire bpi_active;
 wire bpi_busy;
 wire [1:0] bpi_op;
 wire [22:0] bpi_addr;
 wire [15:0] bpi_data_to;
 wire [15:0] bpi_data_from;
 wire bpi_load_data;
 wire bpi_execute;
 wire bpi_seq_idle;
 
 // Jtag interface signals
 	wire [15:0] bpi_rbk_fifo_data;
	wire [15:0] bpi_cmd_fifo_data;
	wire [10:0] bpi_rbk_wrd_cnt;
	wire [15:0] bpi_status;
	wire [31:0] bpi_timer;
	wire bpi_jwe;
	wire bpi_jre;
	wire bpi_jrst;
	wire bpi_rst;
	wire bpi_fifo_rst;
	wire csp_bpi_rst;
	wire BPI_disable;
	wire BPI_enable;

	BPI_ctrl #(
		.USE_CHIPSCOPE(USE_DAQ_CHIPSCOPE),
		.TMR(TMR),
		.TMR_Err_Det(TMR_Err_Det)
	) 
	BPI_ctrl_i(
	 .BPI_VIO_CNTRL(bpi_vio_c6),
	 .BPI_LA_CNTRL(bpi_la_c7),
    .CLK(clk40),
    .CLK1MHZ(clk1mhz),
    .RST(bpi_rst),
    .BPI_FIFO_RST(bpi_fifo_rst),
	 // Interface Signals to/from JTAG interface
	 .BPI_CMD_FIFO_DATA(bpi_cmd_fifo_data),
	 .BPI_WE(bpi_jwe),
	 .BPI_RE(bpi_jre),
	 .BPI_DSBL(BPI_disable),  // Disable BPI processing
	 .BPI_ENBL(BPI_enable),    // Enable BPI processing
	 .BPI_RBK_FIFO_DATA(bpi_rbk_fifo_data),
	 .BPI_RBK_WRD_CNT(bpi_rbk_wrd_cnt),  // Word count of the Read back FIFO (number of available reads)
	 .BPI_STATUS(bpi_status),  // FIFO status bits and latest value of the PROM status register. 
	 .BPI_TIMER(bpi_timer),    // stop watch timer for BPI commands
	 // Signals to/from BPI interface
	 .BPI_BUSY(bpi_busy),
	 .BPI_DATA_FROM(bpi_data_from),
	 .BPI_LOAD_DATA(bpi_load_data),
	 .CSP_BPI_RST(csp_bpi_rst),
	 .BPI_ACTIVE(bpi_active),
	 .BPI_OP(bpi_op),
	 .BPI_ADDR(bpi_addr),
	 .BPI_DATA_TO(bpi_data_to),
	 .BPI_EXECUTE(bpi_execute),
	 .BPI_SEQ_IDLE(bpi_seq_idle)
    );


 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Auto Load Constants from flash PROM                                    //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////
 
reg [15:0] bpi_al_reg;
reg auto_load;
reg auto_load_m1;
wire auto_load_ena;
wire [5:0] al_cnt;
wire al_done;
wire [22:0] al_addr;
wire [15:0] al_cmd_data_out;
wire [1:0]	al_op;
wire al_execute;
wire por_al_start;
wire csp_al_start;
wire clr_al_done;
//wire [20:0] debug_sigs;

//assign csp_al_start = 1'b0;
assign al_start = por_al_start | csp_al_start;

   auto_load_const #(
		.USE_CHIPSCOPE(USE_AUTO_LOAD_CHIPSCOPE),
		.TMR(TMR),
		.TMR_Err_Det(TMR_Err_Det)
	) 
	auto_load_const1 (
		// ChipScope Pro signlas
		.VIO_CNTRL(auto_load_vio_c0),
		.LA_CNTRL(auto_load_la0_c1),
//		.debug_sigs(debug_sigs),
		//
		.CLK(clk40),
		.RST(sys_rst),
		.BUSY(bpi_busy),            //Operation in progress signal (not ready)
		.AL_START(al_start),        //Start Auto Load Operation
		.AL_DONE(al_done),          //Auto Load Operation completed
		.BPI_LOAD_DATA(bpi_load_data),
		.BPI_AL_REG(bpi_al_reg),
		.AUTO_LOAD(auto_load),
		.CSP_AL_START(csp_al_start),
	// signals for BPI interface
	   .AL_ADDR(al_addr),         //Bank/Array Address 
	   .AL_CMD_DATA_OUT(al_cmd_data_out), //Data being written to FLASH device
	   .AL_OP(al_op),           //Operation: 00-standby, 01-write, 10-read, 11-not allowed(standby)
		.AL_EXECUTE(al_execute),
	// signals for Auto Loading Constants
	   .AUTO_LOAD_ENA(auto_load_ena),
	   .CLR_AL_DONE(clr_al_done),
	   .AL_CNT(al_cnt),
	   .AL_STATUS(al_status)
	);

always @(posedge clk40) begin
	if(auto_load_ena && bpi_load_data)
		bpi_al_reg <= bpi_data_from;
	else
		bpi_al_reg <= bpi_al_reg;
end
always @(posedge clk40) begin
	auto_load_m1 <= auto_load_ena ? bpi_load_data : 0;
	auto_load    <= auto_load_m1;
end


 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  BPI interface to XCF128 flash PROM                                     //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////
	wire [2:0] timer;

	 
   bpi_interface #(
		.TMR(TMR),
		.TMR_Err_Det(TMR_Err_Det)
	)
	bpi_intf1 (
		.CLK(clk40),
		.CLK1MHZ(clk1mhz), 
		.CLK100KHZ(clk100khz),
		.RST(sys_rst),
	   .ADDR(bpi_addr),         //Bank/Array Address 
	   .CMD_DATA_OUT(bpi_data_to), //Data being written to FLASH device
	   .OP(bpi_op),           //Operation: 00-standby, 01-write, 10-read, 11-not allowed(standby)
		.EXECUTE(bpi_execute),
		.DATA_IN(bpi_data_from),  //Data read from FLASH device
		.LOAD_DATA(bpi_load_data),           //Clock enable signal for capturing Data read from FLASH device
		.BUSY(bpi_busy),            //Operation in progress signal (not ready)
	// signals for Auto Loading Constants
	   .AUTO_LOAD_ENA(auto_load_ena),
	   .AL_ADDR(al_addr),
	   .AL_CMD_DATA_OUT(al_cmd_data_out),
	   .AL_OP(al_op),
		.AL_EXECUTE(al_execute),
	// signals for LED'S after programing
		.RUN(run),
		.BPI_ACTIVE(bpi_active),
		.DCFEB_STATUS(dcfeb_status),
	 // external connections
      .BPI_AD(BPI_AD),     // Address bus to/from BPI prom
      .CFG_DAT(CFG_DAT),   // Data bus to/from BPI prom
      .RS0(BPI_AD21_RS0),.RS1(BPI_AD22_RS1),
      .FCS_B(FCS_B),.FOE_B(FOE_B),.FWE_B(FWE_B),.FLATCH_B(FLATCH_B),
		// diagnostic outputs for startup display
		.TIMEROUT(timer) // to test point
	);
 

 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Buckeye slow control signals  (LV - low voltage side of translators)   //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////

   wire [6:1] to_bky;
   wire [6:1] bky_rtn;
   wire [6:1] bky_clk;

   buckeye_interface
	bky_intf1 (
      .G1SHOUTLV(G1SHOUTLV),.G2SHOUTLV(G2SHOUTLV),.G3SHOUTLV(G3SHOUTLV),.G4SHOUTLV(G4SHOUTLV),.G5SHOUTLV(G5SHOUTLV),.G6SHOUTLV(G6SHOUTLV),
      .G1SHINLV(G1SHINLV),  .G2SHINLV(G2SHINLV),  .G3SHINLV(G3SHINLV),  .G4SHINLV(G4SHINLV),  .G5SHINLV(G5SHINLV),  .G6SHINLV(G6SHINLV),
      .G1SHCKLV(G1SHCKLV),  .G2SHCKLV(G2SHCKLV),  .G3SHCKLV(G3SHCKLV),  .G4SHCKLV(G4SHCKLV),  .G5SHCKLV(G5SHCKLV),  .G6SHCKLV(G6SHCKLV),
		.TO_BKY(to_bky), .BKY_RTN(bky_rtn), .BKY_CLK(bky_clk)
  );
 
 
 
 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  ADC Serial data input signals and bit clock/ frame clock inputs        //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////
 
	wire [11:0] frm_clks;
//	wire g1_frm_clk0;
//	wire g1_frm_clk1;
//	wire g2_frm_clk0;
//	wire g2_frm_clk1;
//	wire g3_frm_clk0;
//	wire g3_frm_clk1;
//	wire g4_frm_clk0;
//	wire g4_frm_clk1;
//	wire g5_frm_clk0;
//	wire g5_frm_clk1;
//	wire g6_frm_clk0;
//	wire g6_frm_clk1;
	
	wire [11:0] restartps;
//	wire g1restartp0;
//	wire g1restartp1;
//	wire g2restartp0;
//	wire g2restartp1;
//	wire g3restartp0;
//	wire g3restartp1;
//	wire g4restartp0;
//	wire g4restartp1;
//	wire g5restartp0;
//	wire g5restartp1;
//	wire g6restartp0;
//	wire g6restartp1;
	wire dsr_aligned;
	
//	wire [191:0] g1daq16ch,g2daq16ch,g3daq16ch,g4daq16ch,g5daq16ch,g6daq16ch;
	wire [95:0] g1daq8ch_0;
	wire [95:0] g1daq8ch_1;
	wire [95:0] g2daq8ch_0;
	wire [95:0] g2daq8ch_1;
	wire [95:0] g3daq8ch_0;
	wire [95:0] g3daq8ch_1;
	wire [95:0] g4daq8ch_0;
	wire [95:0] g4daq8ch_1;
	wire [95:0] g5daq8ch_0;
	wire [95:0] g5daq8ch_1;
	wire [95:0] g6daq8ch_0;
	wire [95:0] g6daq8ch_1;
	
	wire dsr_rst;
	wire csp_dsr_sys_rst;
	wire adc_init;
	wire adc_init_done;
	wire csp_resync;
	wire bit_slip_odd;
	wire bit_slip_evn;
	wire alg_gd;

	
	adc_data_input_gen_csp #(
		.USE_CHIPSCOPE(USE_DESER_CHIPSCOPE),
		.TMR(TMR)
	)
	adc_data_in1(
		.CSP_G1LA0_CNTRL(g1la0_c0),
		.CSP_G1VIO0_CNTRL(g1vio0_c0),
		.CSP_DSR_SYS_RST(csp_dsr_sys_rst),
		.ADC_INIT(adc_init),
		.ADC_INIT_DONE(adc_init_done),
		.CSP_RESYNC(csp_resync),
		.bit_slip_odd_out(bit_slip_odd),
		.bit_slip_evn_out(bit_slip_evn),
		.ALG_GD(alg_gd),
		
		// Differential Serial Data Inputs
		.G1AD_N(G1AD_N),.G1AD_P(G1AD_P),.G2AD_N(G2AD_N),.G2AD_P(G2AD_P),.G3AD_N(G3AD_N),.G3AD_P(G3AD_P),
		.G4AD_N(G4AD_N),.G4AD_P(G4AD_P),.G5AD_N(G5AD_N),.G5AD_P(G5AD_P),.G6AD_N(G6AD_N),.G6AD_P(G6AD_P),
		// Differential Frame Clock Inputs
		.G1ADCLK0N(G1ADCLK0N),.G1ADCLK0P(G1ADCLK0P),
		.G1ADCLK1N(G1ADCLK1N),.G1ADCLK1P(G1ADCLK1P),
		.G2ADCLK0N(G2ADCLK0N),.G2ADCLK0P(G2ADCLK0P),
		.G2ADCLK1N(G2ADCLK1N),.G2ADCLK1P(G2ADCLK1P),
		.G3ADCLK0N(G3ADCLK0N),.G3ADCLK0P(G3ADCLK0P),
		.G3ADCLK1N(G3ADCLK1N),.G3ADCLK1P(G3ADCLK1P),
		.G4ADCLK0N(G4ADCLK0N),.G4ADCLK0P(G4ADCLK0P),
		.G4ADCLK1N(G4ADCLK1N),.G4ADCLK1P(G4ADCLK1P),
		.G5ADCLK0N(G5ADCLK0N),.G5ADCLK0P(G5ADCLK0P),
		.G5ADCLK1N(G5ADCLK1N),.G5ADCLK1P(G5ADCLK1P),
		.G6ADCLK0N(G6ADCLK0N),.G6ADCLK0P(G6ADCLK0P),
		.G6ADCLK1N(G6ADCLK1N),.G6ADCLK1P(G6ADCLK1P),
		// Differential Bit Clock Inputs
		.G1LCLK0N(G1LCLK0N),.G1LCLK0P(G1LCLK0P),
		.G1LCLK1N(G1LCLK1N),.G1LCLK1P(G1LCLK1P),
		.G2LCLK0N(G2LCLK0N),.G2LCLK0P(G2LCLK0P),
		.G2LCLK1N(G2LCLK1N),.G2LCLK1P(G2LCLK1P),
		.G3LCLK0N(G3LCLK0N),.G3LCLK0P(G3LCLK0P),
		.G3LCLK1N(G3LCLK1N),.G3LCLK1P(G3LCLK1P),
		.G4LCLK0N(G4LCLK0N),.G4LCLK0P(G4LCLK0P),
		.G4LCLK1N(G4LCLK1N),.G4LCLK1P(G4LCLK1P),
		.G5LCLK0N(G5LCLK0N),.G5LCLK0P(G5LCLK0P),
		.G5LCLK1N(G5LCLK1N),.G5LCLK1P(G5LCLK1P),
		.G6LCLK0N(G6LCLK0N),.G6LCLK0P(G6LCLK0P),
		.G6LCLK1N(G6LCLK1N),.G6LCLK1P(G6LCLK1P),
	   // Clocks and Resets
		.RST(dsr_rst),
		.SYS_RST(sys_rst),
		.DSR_RESYNC(dsr_resync),
		.FRM_CLKS(frm_clks),    // Frame Clock for ADC data
		//
		.RESTARTPS(restartps),   // Restart pipeline for  ADC
		.DSR_ALIGNED(dsr_aligned),
		// Deserialized outputs - 16 channels of 12 bits flattend into single vectors (channel 15 in high order bits, 0 in low)
		.G1DAQ8CH_0(g1daq8ch_0),
		.G1DAQ8CH_1(g1daq8ch_1),
		.G2DAQ8CH_0(g2daq8ch_0),
		.G2DAQ8CH_1(g2daq8ch_1),
		.G3DAQ8CH_0(g3daq8ch_0),
		.G3DAQ8CH_1(g3daq8ch_1),
		.G4DAQ8CH_0(g4daq8ch_0),
		.G4DAQ8CH_1(g4daq8ch_1),
		.G5DAQ8CH_0(g5daq8ch_0),
		.G5DAQ8CH_1(g5daq8ch_1),
		.G6DAQ8CH_0(g6daq8ch_0),
		.G6DAQ8CH_1(g6daq8ch_1),
		.RESYNC(resync),
		.resync_d1(resync_d1),
		.lead_edg_resync(lead_edg_resync),
		.lead_edg_resync_d1(lead_edg_resync_d1),
		.cap_phase(cap_phase),
		.rst_mmcm_pipe(rst_mmcm_pipe)
	);
	
  
 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  ADC control output signals and differential sampling clock             //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////

	wire [11:0] adc_cs;
	wire adc_rst,adc_sclk,adc_sdata;

	adc_control_out
	adc_cntrl1 (
	   // External control signals to ADCs
		.G1ADC_CS0_B_25(G1ADC_CS0_B_25), .G1ADC_CS1_B_25(G1ADC_CS1_B_25),
		.G2ADC_CS0_B_25(G2ADC_CS0_B_25), .G2ADC_CS1_B_25(G2ADC_CS1_B_25),
		.G3ADC_CS0_B_25(G3ADC_CS0_B_25), .G3ADC_CS1_B_25(G3ADC_CS1_B_25),
		.G4ADC_CS0_B_25(G4ADC_CS0_B_25), .G4ADC_CS1_B_25(G4ADC_CS1_B_25),
		.G5ADC_CS0_B_25(G5ADC_CS0_B_25), .G5ADC_CS1_B_25(G5ADC_CS1_B_25),
		.G6ADC_CS0_B_25(G6ADC_CS0_B_25), .G6ADC_CS1_B_25(G6ADC_CS1_B_25),
		.ADC_RST_B_25(ADC_RST_B_25),
		.ADC_SCLK_25(ADC_SCLK_25),
		.ADC_SDATA_25(ADC_SDATA_25),
		// Sampling clock to all ADCs
		.GA1ADCCLK_FN(GA1ADCCLK_FN),
		.GA1ADCCLK_FP(GA1ADCCLK_FP),
		.GA2ADCCLK_FN(GA2ADCCLK_FN),
		.GA2ADCCLK_FP(GA2ADCCLK_FP),
		.GA3ADCCLK_FN(GA3ADCCLK_FN),
		.GA3ADCCLK_FP(GA3ADCCLK_FP),
		// Internal control signals
      .ADC_CS(adc_cs),
      .ADC_RST(adc_rst),
      .ADC_SCLK(adc_sclk),
      .ADC_SDATA(adc_sdata),
      .ADC_CLK(adc_clk)
	);

	
 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Pipeline for digitize data for all 96 channels X 12 bits               //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////
 
   wire jrstrt_pipe;
	wire [8:0] pdepth;
	wire [191:0] g1pipout,g2pipout,g3pipout,g4pipout,g5pipout,g6pipout;
	
//pipeline
//pipeline1(
//    .G1_WRCLK0(g1_frm_clk0),   //Frame clock from adc's
//    .G1_WRCLK1(g1_frm_clk1),   //Frame clock from adc's
//    .G2_WRCLK0(g2_frm_clk0),   //Frame clock from adc's
//    .G2_WRCLK1(g2_frm_clk1),   //Frame clock from adc's
//    .G3_WRCLK0(g3_frm_clk0),   //Frame clock from adc's
//    .G3_WRCLK1(g3_frm_clk1),   //Frame clock from adc's
//    .G4_WRCLK0(g4_frm_clk0),   //Frame clock from adc's
//    .G4_WRCLK1(g4_frm_clk1),   //Frame clock from adc's
//    .G5_WRCLK0(g5_frm_clk0),   //Frame clock from adc's
//    .G5_WRCLK1(g5_frm_clk1),   //Frame clock from adc's
//    .G6_WRCLK0(g6_frm_clk0),   //Frame clock from adc's
//    .G6_WRCLK1(g6_frm_clk1),   //Frame clock from adc's
//	 .RDCLK(clk20),             // 20 MHz clock in phase with CMS clock 
//    .RST(sys_rst || ~daq_mmcm_lock),  //Make sure pipeline is not started until valid clocks
//    .JRESTART(jrstrt_pipe),        //Restart pipeline from JTAG command
//	 .G1RESTARTP0(g1restartp0),   // Restart pipeline for G1 ADC0
//	 .G1RESTARTP1(g1restartp1),   // Restart pipeline for G1 ADC1
//	 .G2RESTARTP0(g2restartp0),   // Restart pipeline for G2 ADC0
//	 .G2RESTARTP1(g2restartp1),   // Restart pipeline for G2 ADC1
//	 .G3RESTARTP0(g3restartp0),   // Restart pipeline for G3 ADC0
//	 .G3RESTARTP1(g3restartp1),   // Restart pipeline for G3 ADC1
//	 .G4RESTARTP0(g4restartp0),   // Restart pipeline for G4 ADC0
//	 .G4RESTARTP1(g4restartp1),   // Restart pipeline for G4 ADC1
//	 .G5RESTARTP0(g5restartp0),   // Restart pipeline for G5 ADC0
//	 .G5RESTARTP1(g5restartp1),   // Restart pipeline for G5 ADC1
//	 .G6RESTARTP0(g6restartp0),   // Restart pipeline for G6 ADC0
//	 .G6RESTARTP1(g6restartp1),   // Restart pipeline for G6 ADC1
//    .PDEPTH(pdepth),             //Pipeline depth from JTAG Reg
//    .G1DAQ16CH(g1daq16ch),       //Deserialized data from group 1 amp channels
//    .G2DAQ16CH(g2daq16ch),
//    .G3DAQ16CH(g3daq16ch),
//    .G4DAQ16CH(g4daq16ch),
//    .G5DAQ16CH(g5daq16ch),
//    .G6DAQ16CH(g6daq16ch),
//    .G1PIPOUT(g1pipout),
//    .G2PIPOUT(g2pipout),
//    .G3PIPOUT(g3pipout),
//    .G4PIPOUT(g4pipout),
//    .G5PIPOUT(g5pipout),
//    .G6PIPOUT(g6pipout)
//    );

pipeline_gen_csp #(
		.USE_CHIPSCOPE(USE_PIPE_CHIPSCOPE),
		.TMR(TMR)
	)
	pipeline1(
		.CSP_LA0_CNTRL(pipe_la0_c0),
		.CSP_VIO0_CNTRL(pipe_vio_in0_c1),
		.CSP_VIO1_CNTRL(pipe_vio_out1_c2),
	 .CLK160(clk160),
    .WRCLKS(frm_clks),   //Frame clock from adc's
	 .RDCLK(clk20),             // 20 MHz clock in phase with CMS clock 
    .RST(sys_rst || ~daq_mmcm_lock),  //Make sure pipeline is not started until valid clocks
    .JRESTART(jrstrt_pipe),        //Restart pipeline from JTAG command
	 .RESTARTPS(restartps),   // Restart pipeline for ADC0
    .PDEPTH(pdepth),             //Pipeline depth from JTAG Reg
    .G1DAQ8CH_0(g1daq8ch_0),       //Deserialized data from group 1 amp channels 7:0
    .G1DAQ8CH_1(g1daq8ch_1),       //Deserialized data from group 1 amp channels 15:8
    .G2DAQ8CH_0(g2daq8ch_0),       //Deserialized data from group 2 amp channels 7:0
    .G2DAQ8CH_1(g2daq8ch_1),       //Deserialized data from group 2 amp channels 15:8
    .G3DAQ8CH_0(g3daq8ch_0),       //Deserialized data from group 3 amp channels 7:0
    .G3DAQ8CH_1(g3daq8ch_1),       //Deserialized data from group 3 amp channels 15:8
    .G4DAQ8CH_0(g4daq8ch_0),       //Deserialized data from group 4 amp channels 7:0
    .G4DAQ8CH_1(g4daq8ch_1),       //Deserialized data from group 4 amp channels 15:8
    .G5DAQ8CH_0(g5daq8ch_0),       //Deserialized data from group 5 amp channels 7:0
    .G5DAQ8CH_1(g5daq8ch_1),       //Deserialized data from group 5 amp channels 15:8
    .G6DAQ8CH_0(g6daq8ch_0),       //Deserialized data from group 6 amp channels 7:0
    .G6DAQ8CH_1(g6daq8ch_1),       //Deserialized data from group 6 amp channels 15:8
    .G1PIPOUT(g1pipout),
    .G2PIPOUT(g2pipout),
    .G3PIPOUT(g3pipout),
    .G4PIPOUT(g4pipout),
    .G5PIPOUT(g5pipout),
    .G6PIPOUT(g6pipout)
    );


 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  16 FIFOs (for 16 channels) each 12 bits wide (total is 16X12 bits wide.//
 //  Group G1 to G6 in sequence for sample 1,                               //
 //  then same for sample 2 and so on.                                      //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////

wire l1a,l1a_match,lct,bc0;
wire [23:0] l1a_cnt;
wire [11:0] l1a_mtch_cnt;
wire [191:0] doutfifo;
wire [15:0] fifo1_rd_ena;
wire l1a_rd_en;
wire l1a_smp_rdy;
wire [6:0] samp_max;
wire [37:0] l1a_smp_out;
wire [6:0] ovrlp_smp_out;
wire [15:0] f16_mt;
wire rst_resync;
wire daq_fifo_rst;
wire slow_fifo_rst;
wire rng_ff1_trg_in;
wire rng_buf_trg_in;
wire rng_chn_trg_in;
wire rng_eth_trg_in;
wire rng_xfr_trg_in;
wire rng_ff1_trg_out;
wire rng_buf_trg_out;
wire rng_chn_trg_out;
wire rng_eth_trg_out;
wire rng_xfr_trg_out;
wire csp_daq_trg_out;

assign rng_ff1_trg_in = rng_buf_trg_out || rng_chn_trg_out || rng_eth_trg_out || rng_xfr_trg_out || csp_daq_trg_out;
assign rng_buf_trg_in = rng_ff1_trg_out || rng_chn_trg_out || rng_eth_trg_out || rng_xfr_trg_out || csp_daq_trg_out;
assign rng_chn_trg_in = rng_ff1_trg_out || rng_buf_trg_out || rng_eth_trg_out || rng_xfr_trg_out || csp_daq_trg_out;
assign rng_eth_trg_in = rng_ff1_trg_out || rng_buf_trg_out || rng_chn_trg_out || rng_xfr_trg_out || csp_daq_trg_out;
assign rng_xfr_trg_in = rng_ff1_trg_out || rng_buf_trg_out || rng_chn_trg_out || rng_eth_trg_out || csp_daq_trg_out;

fifo16ch_wide #(
		.USE_CHIPSCOPE(USE_RINGBUF_CHIPSCOPE),
		.TMR(TMR),
		.TMR_Err_Det(TMR_Err_Det)
	)
fifo1 (
	// ChipScope Pro signlas
	.LA_CNTRL(rng_ff1_la0_c0),
	//
	.CLK40(clk40),   // CMS clock for L1A capture
	.RDCLK(clk160),  // Read out at 160 MHz
	.SMPCLK(clk20),	// Sample clock for L1A phase information.
	.WRCLK(clk120),  // write to FIFO at 120 MHz (6 words x 20MHz sample rate)
	.RST(sys_rst || ~daq_mmcm_lock),
	.RST_RESYNC(rst_resync),
	.FIFO_RST(daq_fifo_rst),
	.L1A(l1a),			
	.L1A_MATCH(l1a_match),			
	.G1IN(g1pipout),
	.G2IN(g2pipout),
	.G3IN(g3pipout),
	.G4IN(g4pipout),
	.G5IN(g5pipout),
	.G6IN(g6pipout),
	.RD_ENA(fifo1_rd_ena),
	.L1A_RD_EN(l1a_rd_en),
	.SAMP_MAX(samp_max),
	.TRIG_IN(rng_ff1_trg_in),
	.TRIG_OUT(rng_ff1_trg_out),
	.RDY(l1a_smp_rdy),
	.L1A_SMP_OUT(l1a_smp_out),      // 38 bit wide output two entries per sample, contains L1A info, {l1a_phase,l1a_match,l1amcnt,l1acnt}
	.OVRLP_SMP_OUT(ovrlp_smp_out),  // 7 bit wide output, overlap information, registered and clock enabled to contain the current sample info, {evt_end,multi_ovlp,ovrlap,ovrlap_cnt}.
	.DOUT_16CH(doutfifo),           // 192 bit wide output at 160 MHz for 6 X (n samples)
	.L1A_CNT(l1a_cnt),
	.L1A_MTCH_CNT(l1a_mtch_cnt),
	.FIFO_LOAD_ERRCNT(fifo_load_errcnt),
	.fmt(f16_mt)
	);

wire jrdfifo;
wire rdf_wren;
wire jtag_rd_mode;
wire [11:0] rdf_wdata;
wire [15:0] frm_data;
wire last_wrd;
wire dvalid;
wire daq_data_clk;
wire [15:0] txd;
wire txd_vld;
wire txack;



 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Transfer data from FIFO1 to readout FIFO1 and 2                        //
 //  This is a multiplexer between FIFO1 and Readout FIFOs.                 //
 //  Contains state machine and counters for samples, channels, and chips   //
 //  Sets channel, read enables for 6 chips, then increments channel,       //
 //  After finishing channels, repeats for the next sample.                 //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////
 

xfer2ringbuf  #(
	.USE_CHIPSCOPE(USE_RINGBUF_CHIPSCOPE),
	.TMR(TMR),
	.TMR_Err_Det(TMR_Err_Det)
)
xfer2ringbuf_i(   // Transfer data from FIFO1 to readout ring buffer at 160 MHz
	// ChipScope Pro signlas
	.LA_CNTRL(rng_xfr_la0_c3),
	//
	.CLK(clk160),
	.RST(sys_rst),
	.JTAG_MODE(jtag_rd_mode),
	.J_RD_FIFO(jrdfifo),
	.DIN_16CH(doutfifo),
	.RDY(l1a_smp_rdy),
	.F16_MT(f16_mt),
	.TRIG_IN(rng_xfr_trg_in),
	.TRIG_OUT(rng_xfr_trg_out),
	.RD_ENA(fifo1_rd_ena),
	.L1A_RD_EN(l1a_rd_en),
	.WREN(rdf_wren),
	.DMUX(rdf_wdata),  // 12 bit data out
	.XF2RB_ERRCNT(xf2rb_errcnt)
	);
	 
 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Ring Buffer to feed ethernet and channel link FIFOs.                   //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////

wire [36:0] l1a_evt_data;
wire l1a_evt_push;
wire [17:0] ff_data;
wire ff_push;
wire ring_warn;
wire eth_evt_buf_amt;
wire eth_evt_buf_afl;


ringbuf #(
	.USE_CHIPSCOPE(USE_RINGBUF_CHIPSCOPE),
	.TMR(TMR),
	.TMR_Err_Det(TMR_Err_Det)
) 
ringbuf_i(
	// ChipScope Pro signlas
	.LA_CNTRL(rng_buf_la0_c1),
	//
   .CLK(clk160),
   .RST_RESYNC(rst_resync),
	.FIFO_RST(daq_fifo_rst),
	.SAMP_MAX(samp_max),
   .WDATA(rdf_wdata),               // Data from FIFO1 sample FIFO through xfer2ringbuf multiplexer (12 bits);
	.WREN(rdf_wren),                 // write enable from transfer_samples state machine.
   .L1A_SMP_DATA(l1a_smp_out),      // 38 bit wide input, {l1a_phase,l1a_match,l1amcnt,l1acnt};
   .OVRLP_SMP_DATA(ovrlp_smp_out),  // 7 bit wide input, {evt_end,multi_ovlp,ovrlap,ovrlap_cnt};
	.L1A_WRT_EN(l1a_rd_en),          // Read enable from transfer_samples state machine, (two read enables per sample)
	.EVT_BUF_AMT(eth_evt_buf_amt),
	.EVT_BUF_AFL(eth_evt_buf_afl),
	.TRIG_IN(rng_buf_trg_in),
	.TRIG_OUT(rng_buf_trg_out),
	.L1A_EVT_DATA(l1a_evt_data), // 37 bits {l1a_phs,l1a_mtch_num,l1anum}
	.L1A_EVT_PUSH(l1a_evt_push),
	.RDATA(ff_data),             // 18 bits {movlp,ovrlp,ocnt,ring_out}
	.DATA_PUSH(ff_push),
	.WARN(ring_warn),
	.RGTRNS_ERRCNT(rgtrns_errcnt)
   );

 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Readout FIFO1 (x12 bits) wide.                                         //
 //  Data order is {sample[0],channel[0],chip[0]...chip[5]},                //
 //                {sample[0],channel[1],chip[0]...chip[5]},                //
 //                {sample[0],channel[2],chip[0]...chip[5]},                //
 //                        ...                                              //
 //                {sample[n],channel[15],chip[0]...chip[5]}                //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////

wire mlt_ovlp;
wire ovlp_mux;


 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Channel Link FIFO to feed channel Link path with data from FIFO1       //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////

//chanlink_fifo  #(
//	.USE_CHIPSCOPE(USE_CHAN_LINK_CHIPSCOPE),
//	.TMR(TMR)
//)
//chanlink_fifo_i(
//	// ChipScope Pro signlas
//	.LA_CNTRL(chn_lnk_la0_c0),
//	//
//	.WCLK(clk160),
//	.RCLK(clk40),
//   .RST_RESYNC(rst_resync),
//	.FIFO_RST(daq_fifo_rst),
//	.SAMP_MAX(samp_max),
//	.WDATA(rdf_wdata),               // Data from FIFO1 sample FIFO through xfer2ringbuf multiplexer (12 bits);
//	.WREN(rdf_wren),                 // write enable from transfer_samples state machine.
//	.L1A_EVT_DATA(l1a_smp_out),      // 38 bit wide input, {l1a_phase,l1a_match,l1amcnt,l1acnt};
//	.OVRLP_EVT_DATA(ovrlp_smp_out),  // 7 bit wide input, {evt_end,movlp,ovrlp,ocnt,ring_out};
//	.L1A_WRT_EN(l1a_rd_en),          // Output from L1A sample FIFO is written into L1A event FIFO if an L1A match is present (two read enables per sample).
//	.WARN(ring_warn),
//	.TRIG_IN(rng_chn_trg_in),
//	.TRIG_OUT(rng_chn_trg_out),
//	.LAST_WRD(last_wrd),
//	.DVALID(dvalid),
//	.OVLP_MUX(ovlp_mux),
//	.MLT_OVLP(mlt_ovlp),
//	.DOUT(frm_data)
//	);

 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Channel Link FIFO to feed channel Link path with data from Ring buffer.//
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////

chanlink_fifo_ring  #(
	.USE_CHIPSCOPE(USE_CHAN_LINK_CHIPSCOPE),
	.TMR(TMR)
)
chanlink_fifo_ring_i(
	// ChipScope Pro signlas
	.LA_CNTRL(chn_lnk_la0_c0),
	//
	.WCLK(clk160),
	.RCLK(clk40),
   .RST_RESYNC(rst_resync),
	.FIFO_RST(daq_fifo_rst),
	.SAMP_MAX(samp_max),
	.WDATA(ff_data),              // 18 bits {movlp,ovrlp,ocnt,ring_out}
	.WREN(ff_push),
	.L1A_EVT_DATA(l1a_evt_data),  // 37 bits {l1a_phs,l1a_mtch_num,l1anum}
	.L1A_WRT_EN(l1a_evt_push),
	.WARN(ring_warn),
	.TRIG_IN(rng_chn_trg_in),
	.TRIG_OUT(rng_chn_trg_out),
	.LAST_WRD(last_wrd),
	.DVALID(dvalid),
	.OVLP_MUX(ovlp_mux),
	.MLT_OVLP(mlt_ovlp),
	.DOUT(frm_data)
	);
	 
 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Ethernet FIFO to feed GbE optical path.                                //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////


eth_fifo  #(
	.USE_CHIPSCOPE(USE_RINGBUF_CHIPSCOPE),
	.TMR(TMR),
	.TMR_Err_Det(TMR_Err_Det)
)
eth_fifo_i(
	// ChipScope Pro signlas
	.LA_CNTRL(rng_eth_la0_c2),
	//
   .WCLK(clk160),
   .RCLK(daq_data_clk),
   .RST_RESYNC(rst_resync),
	.FIFO_RST(daq_fifo_rst),
	.SAMP_MAX(samp_max),
	.WDATA(ff_data),              // 18 bits {movlp,ovrlp,ocnt,ring_out}
	.WREN(ff_push),
	.L1A_EVT_DATA(l1a_evt_data),  // 37 bits {l1a_phs,l1a_mtch_num,l1anum}
	.L1A_WRT_EN(l1a_evt_push),
	.WARN(ring_warn),
	.L1A_HEAD(l1a_head),
	.TXACK(txack),                     // Data acknowledge signal from frame processor
	.TRIG_IN(rng_eth_trg_in),
	.TRIG_OUT(rng_eth_trg_out),
	.EVT_BUF_AMT(eth_evt_buf_amt),
	.EVT_BUF_AFL(eth_evt_buf_afl),
	.TXD(txd),                         // 16-bit data for frame processor
	.TXD_VLD(txd_vld),                 // data valid signal
	.SMPPRC_ERRCNT(smpprc_errcnt)
   );
	
wire [2:0] jdaq_prbs_tst;
wire jdaq_inj_err;
wire daq_op_tx_disable;
wire trg_op_tx_disable;
wire op_tx_disable; // dcfeb_vttx has a tx disable that is common for both DAQ and TRG
wire daq_op_rst;
wire trg_op_rst;

assign op_tx_disable = daq_op_tx_disable || trg_op_tx_disable;

 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  DAQ Path Optical Transceiver signals and GTX signals                   //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////

daq_optical_out #(
	.USE_CHIPSCOPE(USE_DAQ_CHIPSCOPE),
	.SIM_SPEEDUP(Simulation),
	.XDCFEB(xDCFEB),
	.TMR(TMR),
	.TMR_Err_Det(TMR_Err_Det)
)
daq_optical_out_i (
	.DAQ_TX_VIO_CNTRL(DAQ_tx_vio_c3),
	.DAQ_TX_LA_CNTRL(DAQ_tx_la_c4),
	.RST(sys_rst),
	// External signals
	.DAQ_RX_N(DAQ_RX_N),.DAQ_RX_P(DAQ_RX_P), // high speed serial input not connected on hardware 
	.DAQ_TX_N(DAQ_TX_N),.DAQ_TX_P(DAQ_TX_P), // high speed serial output
	// Internal signals
	.DAQ_TX_125REFCLK(daq_tx_125_refclk),    // 125 MHz for 1 GbE
	.DAQ_TX_125REFCLK_DV2(daq_tx_125_refclk_dv2), // 62.5 MHz user clock for 1 GbE
	.DAQ_TX_160REFCLK(trg_tx_160_refclk),    // 160 MHz for  2.56 GbE
	.L1A_MATCH(l1a_match),
	.TXD(txd),                         // 16-bit data for frame processor
	.TXD_VLD(txd_vld),                   // frame data valid signal
	.JDAQ_RATE(jdaq_rate),
	.JDAQ_PRBS_TST(jdaq_prbs_tst),      // PRBS test mode from JTAG interface
	.JDAQ_INJ_ERR(jdaq_inj_err),        // Error injection requested from JTAG interface
	.RATE_1_25(rate_1_25),
	.RATE_3_2(rate_3_2),
	.TX_ACK(txack),
	.CSP_MAN_CTRL(csp_man_ctrl),        // Chip Scope Pro manual control for DAQ rate, L1A, and packet headers;
	.CSP_USE_ANY_L1A(csp_use_any_l1a),     // Flag to send data on any L1A
	.CSP_L1A_HEAD(csp_l1a_head),        // Flag to send L1A number at the begining of the packet
	.CSP_DAQ_TRG_OUT(csp_daq_trg_out),        // Flag to send L1A number at the begining of the packet
	.DAQ_DATA_CLK(daq_data_clk),
	.FRMPRC_ERRCNT(frmprc_errcnt)
  );

//	daq_transceiver_io #(
//		.USE_CHIPSCOPE(USE_DAQ_CHIPSCOPE),
//		.USE_2p56GbE(1),
//		.SIM_SPEEDUP(Simulation)
//	)		
//	daq_xcvr_io1 (
//		.DAQ_TX_VIO_CNTRL(DAQ_tx_vio_c3),
//		.DAQ_TX_LA_CNTRL(DAQ_tx_la_c4),
//	   .RST(sys_rst),
//		// External signals
//		.DAQ_RX_N(DAQ_RX_N),.DAQ_RX_P(DAQ_RX_P), // high speed serial input not connected on hardware 
//		.DAQ_TDIS(DAQ_TDIS),                     // disable optical transmission
//		.DAQ_TX_N(DAQ_TX_N),.DAQ_TX_P(DAQ_TX_P), // high speed serial output
//		// Internal signals 
//		.DAQ_TX_125REFCLK(daq_tx_125_refclk),    // 125 MHz for 1 GbE
//		.DAQ_TX_160REFCLK(trg_tx_160_refclk),    // 160 MHz for 2 or 2.56 GbE
//		.L1A_MATCH(l1a_match),
//		.MACTXD(txd),                         // 16-bit data for MAC processor
//		.MACTXDVLD(txd_vld),                   // MAC data valid signal
//		.TXACK(txack),                           // Data acknowledge signal from MAC processor
//		.DAQ_DATA_CLK(daq_data_clk)
//  );
  


	channel_link_out
	ch_link1 (
	   // External output
		.DATAOUT(DATAOUT),
		.CHAN_LNK_CLK(CHAN_LNK_CLK),
		.MB_FIFO_PUSH_B(MB_FIFO_PUSH_B),
		.MOVLP(MOVLP),
		.OVLPMUX(OVLPMUX),
		.DATAAVAIL(DATAAVAIL),
		.ENDWORD(ENDWORD),
		// Internal input
		.CLK(clk40),
		.L1A_MATCH(l1a_match),
		.LAST_WRD(last_wrd),
		.DVALID(dvalid),
		.OVLP_MUX(ovlp_mux),
		.MLT_OVLP(mlt_ovlp),
		.FRAME_DATA(frm_data)
//Temporary assignments
//		.L1A(1'b0),
//		.LAST_WRD(1'b0),
//		.DVALID(1'b0),
//		.FRAME_DATA(16'h0000)
    );

	
  //
  //Trigger and sync signals
  //

	trigger #(
	.TMR(TMR)
)
	trig_in1(                           // provides synchronus trigger inputs
		.CLK40(clk40),
		.RST(sys_rst),
	 // external connections
		.SKW_L1A_P(\SKW_L1A+ ),.SKW_L1A_N(\SKW_L1A- ),
		.SKW_L1A_MATCH_P(\SKW_L1A_MATCH+ ),.SKW_L1A_MATCH_N(\SKW_L1A_MATCH- ),
		.SKW_RESYNC_P(\SKW_RESYNC+ ),.SKW_RESYNC_N(\SKW_RESYNC- ),
		.SKW_BC0_P(\SKW_BC0+ ),.SKW_BC0_N(\SKW_BC0- ),
	// internal signals
		.TTC_SRC(ttc_src),      		 // Trigger source mode
		.USE_ANY_L1A(use_any_l1a),		//JTAG flag for L1A match source (L1A or L1A_MATCH)
		.CSP_RESYNC(csp_resync),
	 // common signals
		.L1A(l1a),
		.L1A_MATCH(l1a_match),
		.LCT(lct),
		.RESYNC(resync),
		.RST_RESYNC(rst_resync),
		.BC0CNT(bc0cnt),
		.BC0(bc0)
	);
	 
	
  //
  //Calibration signals
  //
	wire cal_mode;
	wire trg_pulse;
	wire [11:0] injplscnt;
	wire [11:0] extplscnt;

	calib_intf #(
	.TMR(TMR)
)
	calib_intf_i(                           // provides multiplexing for calibration i/o
		.CLK40(clk40),
		.RST_RESYNC(rst_resync),
	 // external connections
		.SKW_EXTPLS_P(\SKW_EXTPLS+ ),.SKW_EXTPLS_N(\SKW_EXTPLS- ),
		.SKW_INJPLS_P(\SKW_INJPLS+ ),.SKW_INJPLS_N(\SKW_INJPLS- ),
		.INJPLS_LV(INJPLS_LV),
		.EXTPLS_LV(EXTPLS_LV),
	// internal signals
		.TTC_SRC(ttc_src),       // Trigger source mode
		.CAL_MODE(cal_mode),		 // external or internal calibrations pulses (0: external pulsing, 1: internal pulsing)
	 // common output signals
		.INJPULSE_P(\INJPULSE+ ),.INJPULSE_N(\INJPULSE- ),
		.EXTPULSE_P(\EXTPULSE+ ),.EXTPULSE_N(\EXTPULSE- ),
		.TRG_PULSE(trg_pulse),
	// counters
		.INJPLSCNT(injplscnt),
		.EXTPLSCNT(extplscnt)
	);


	//
	//Comparator signals
	//

 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Comparator I/O and Comparator DAC control signals                      //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////

	wire [7:0]g1c,g2c,g3c,g4c,g5c,g6c;
	wire [1:0]comp_mode;
	wire [2:0]comp_time;
	wire comp_rst;
	
	comparator_io
	comp_io1 (
	   // External I/O
		.G1C_LV(G1C_LV), .G2C_LV(G2C_LV), .G3C_LV(G3C_LV), .G4C_LV(G4C_LV), .G5C_LV(G5C_LV), .G6C_LV(G6C_LV), // Comparator inputs
		.CMODE(CMODE),  // Comparator Mode output
		.CTIME(CTIME),  // Comparator Timing output
		.LCTCLK(LCTCLK), .LCTRST(LCTRST), //Comparator clock and reset
		// Internal signals
		.G1C(g1c), .G2C(g2c), .G3C(g3c), .G4C(g4c), .G5C(g5c), .G6C(g6c), // Encoded Di-Strip signals from Comparator
		.COMP_MODE(comp_mode),
		.COMP_TIME(comp_time),
		.LCT_CLK(comp_clk), .LCT_RST(comp_rst)
	);

 
 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Trigger Path Optical Transceiver signals and GTX signals               //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////

	wire trg_gtxtxreset;
   wire trg_gtxtxreset_csp;
   wire trg_txresetdone;
	wire trg_tx_pllrst;
	reg  trg_rst;
   wire tx_sync_done;
	wire ena_test_pat;
	wire inj_err;
	wire strt_ltncy;
	wire mon_tx_sel;
	wire [3:0] mon_trg_tx_isk;
	wire [31:0] mon_trg_tx_data;
	wire man_rst;
	wire ltncy_trig_strt;
	wire [29:0] lay1_to_6_half_strip;
	wire [5:0] layer_mask;
	
	tmb_fiber_out #(
		.SIM_SPEEDUP(Simulation),
		.XDCFEB(xDCFEB),
		.TMR(TMR)
	)
	tmb_fiber_out1 (
	   .RST(sys_rst),
		.TRG_OP_TX_DISABLE(op_tx_disable),  // common tx disable
		// External signals
//		.TRG_SIGDET(ALT_SIGDET),                 // receiver signal detected (not used on DCFEB and non existant on xDCFEBs
		.TRG_RX_N(TRG_RX_N),.TRG_RX_P(TRG_RX_P), // high speed serial input
		.TRG_TDIS(TRG_TDIS),                     // disable optical transmission
		.TRG_TX_N(TRG_TX_N),.TRG_TX_P(TRG_TX_P), // high speed serial output
		// Internal signals
		.G1C(g1c), .G2C(g2c), .G3C(g3c), .G4C(g4c), .G5C(g5c), .G6C(g6c), // from comparators
		.TRG_TX_REFCLK(trg_tx_160_refclk),       // 160 MHz for comparator data
		.TRG_TXUSRCLK(comp_clk160),              // 160 MHz GTX parallel clock
		.TRG_CLK80(comp_clk80),                  //  80 MHz GTX User interface clock
 		.TRG_GTXTXRST(trg_gtxtxreset | trg_gtxtxreset_csp),           // GTX reset tx side
		.TRG_TX_PLLRST(trg_tx_pllrst),           // Reset Transmit PLL
		.TRG_RST(trg_rst),                       // Reset for Pseudo Random Bit Stream
		.ENA_TEST_PAT(ena_test_pat),             // Enable test with Pseudo Random Bit Stream Chip Scope Pro control only
		.TMB_TX_MODE(tmb_tx_mode),               // Select transmission mode
		.LAY1_TO_6_HALF_STRIP(lay1_to_6_half_strip), //5-bit half strip number (0-31) for each layer for tmb_tx_mode 5 
		.LAYER_MASK(layer_mask),						// indicates which layer to allow active half strips in tmb_tx_mode 5
		.TRG_PULSE(trg_pulse),
		.INJ_ERR(inj_err),                       // Inject error into Pseudo Random Bit Stream
		.TRG_TX_PLL_LOCK(trg_tx_pll_lock),       // tx side pll lock
		.TRG_TXRESETDONE(trg_txresetdone),       // tx side reset done
		.TX_SYNC_DONE(tx_sync_done),             // tx side phase alignment done
		.STRT_LTNCY(strt_ltncy),                 // signal to start latency counter
		.LTNCY_TRIG(ltncy_trig_strt),            // trigger for scope to start latency measurement
		.MON_TX_SEL(mon_tx_sel),
		.MON_TRG_TX_ISK(mon_trg_tx_isk),
		.MON_TRG_TX_DATA(mon_trg_tx_data)
  ); 
  
	always @(posedge comp_clk) begin
		trg_rst <= resync | sys_rst | man_rst | comp_rst;
	end
	

generate
if(USE_CMP_CHIPSCOPE==1) 
begin : chipscope_trg
// chip scope code for trigger tx and latency
//
wire [31:0] cmp_tx_async_in;
wire [7:0]  cmp_tx_async_out;
wire [3:0]  cmp_tx_sync_out;
wire [95:0] cmp_tx_la_data;
wire [7:0]  cmp_tx_la_trig;
wire [95:0] cmp_latency_la_data;
wire [7:0]  cmp_latency_la_trig;

wire [7:0] dummy_asigs;
wire [3:0] dummy_ssigs;


	cmp_tx_vio cmp_tx_vio1 (
		 .CONTROL(cmp_tx_vio_c0), // INOUT BUS [35:0]
		 .CLK(comp_clk), // IN
		 .ASYNC_IN(cmp_tx_async_in), // IN BUS [31:0]
		 .ASYNC_OUT(cmp_tx_async_out), // OUT BUS [7:0]
		 .SYNC_OUT(cmp_tx_sync_out) // OUT BUS [3:0]
	);


//		 ASYNC_IN [31:0]
	assign cmp_tx_async_in[0]     = trg_txresetdone;
	assign cmp_tx_async_in[1]     = trg_tx_pll_lock;
	assign cmp_tx_async_in[2]     = trg_rst;
	assign cmp_tx_async_in[3]     = tx_sync_done;
	assign cmp_tx_async_in[6:4]   = tmb_tx_mode;
	assign cmp_tx_async_in[7]     = 1'b0;
	assign cmp_tx_async_in[12:8]  = lay1_to_6_half_strip[4:0];
	assign cmp_tx_async_in[17:13] = lay1_to_6_half_strip[9:5];
	assign cmp_tx_async_in[22:18] = lay1_to_6_half_strip[14:10];
	assign cmp_tx_async_in[27:23] = lay1_to_6_half_strip[19:15];
	assign cmp_tx_async_in[31:28] = layer_mask[3:0];

		 
//		 ASYNC_OUT [7:0]
	assign ena_test_pat       = cmp_tx_async_out[0];
	assign man_rst            = cmp_tx_async_out[1];
	assign trg_gtxtxreset_csp = cmp_tx_async_out[2];
	assign trg_tx_pllrst      = cmp_tx_async_out[3];
	assign dummy_asigs[7:4]   = cmp_tx_async_out[7:4];
		 
//		 SYNC_OUT [7:0]
	assign inj_err            = cmp_tx_sync_out[0];
	assign dummy_ssigs[3:1]   = cmp_tx_sync_out[3:1];

	cmp_tx_la cmp_tx_la_i (
		 .CONTROL(cmp_tx_la_c1),
		 .CLK(comp_clk80),
		 .DATA(cmp_tx_la_data), // IN BUS [95:0]
		 .TRIG0(cmp_tx_la_trig) // IN BUS [7:0]
	);
	
// LA Data [95:0]
	assign cmp_tx_la_data[7:0]     = g1c;
	assign cmp_tx_la_data[15:8]    = g2c;
	assign cmp_tx_la_data[23:16]   = g3c;
	assign cmp_tx_la_data[31:24]   = g4c;
	assign cmp_tx_la_data[39:32]   = g5c;
	assign cmp_tx_la_data[47:40]   = g6c;
	assign cmp_tx_la_data[79:48]   = mon_trg_tx_data;
	assign cmp_tx_la_data[83:80]   = mon_trg_tx_isk;
	assign cmp_tx_la_data[84]      = mon_tx_sel;
	assign cmp_tx_la_data[85]      = ena_test_pat;
	assign cmp_tx_la_data[86]      = man_rst;
	assign cmp_tx_la_data[87]      = trg_rst;
	assign cmp_tx_la_data[88]      = trg_gtxtxreset_csp;
	assign cmp_tx_la_data[89]      = trg_tx_pllrst;
	assign cmp_tx_la_data[90]      = trg_txresetdone;
	assign cmp_tx_la_data[91]      = trg_tx_pll_lock;
	assign cmp_tx_la_data[92]      = tx_sync_done;
	assign cmp_tx_la_data[93]      = trg_pulse;
	assign cmp_tx_la_data[94]      = inj_err;
	assign cmp_tx_la_data[95]      = 1'b0;


// LA Trigger [7:0]
	assign cmp_tx_la_trig[0]      = man_rst;
	assign cmp_tx_la_trig[1]      = trg_rst;
	assign cmp_tx_la_trig[2]      = trg_pulse;
	assign cmp_tx_la_trig[3]      = trg_gtxtxreset_csp;
	assign cmp_tx_la_trig[4]      = trg_tx_pllrst;
	assign cmp_tx_la_trig[5]      = trg_txresetdone;
	assign cmp_tx_la_trig[6]      = trg_tx_pll_lock;
	assign cmp_tx_la_trig[7]      = tx_sync_done;

end
else
begin : no_chipscope_trg
	assign ena_test_pat       = 1'b0;
	assign inj_err            = 1'b0;
	assign man_rst            = 1'b0;
	assign trg_gtxtxreset_csp = 1'b0;
	assign trg_tx_pllrst      = 1'b0;
end
endgenerate
  
assign CTRL_TDIS = 1'b1; // CTRL Transmitter is unused, keep it disabled
  
/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//  SPI Interface to DACs                                                  //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

wire cdac_enb,caldac_enb,caladc_enb;
wire spi_ck;
wire spi_dat;
wire spi_rtn;
  
spi_port #(
		.USE_CHIPSCOPE(USE_SPI_CHIPSCOPE)
	)		
SPI_PORT_i  (
	//SPI input signals
	.SPI_RTN_LV(SPI_RTN_LV),
	//SPI output signals
	.SPI_CK_LV(SPI_CK_LV),
	.SPI_DAT_LV(SPI_DAT_LV),
	.ADC_CS_LV_B(ADC_CS_LV_B),
	.CAL_DAC_CS_LV_B(CAL_DAC_CS_LV_B),
	.COMP_DAC_CS_LV_B(COMP_DAC_CS_LV_B),
	// internal signals
	.SPI_RTN(spi_rtn),
   .CDAC_ENB(cdac_enb),
   .CALDAC_ENB(caldac_enb),
   .CALADC_ENB(caladc_enb),
	.SPI_CK(spi_ck),
	.SPI_DAT(spi_dat)
);

  
/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//  I2C Interface to Optical transmitters                                  //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////
wire [7:0] I2C_wrt_fifo_data;
wire I2C_we;
wire I2C_rdena;
wire I2C_reset;
wire I2C_start;
wire I2C_clr_start;
wire [7:0] I2C_rbk_fifo_data;
wire [7:0] I2C_status;
wire I2C_at_scope_sync;

	I2C_interfaces #(
		.Simulation(Simulation),
		.USE_CHIPSCOPE(USE_I2C_CHIPSCOPE)
	) 
	I2C_intf1 (
		.CLK40(clk40),
		.CLK1MHZ(clk1mhz),
	   .RST(sys_rst),
		
		.DAQ_LDSDA(DAQ_SDA),
//		.DAQ_LDSDA_RTN(DAQ_SDA_RTN),
		
		.TRG_LDSDA(TRG_SDA),
//		.TRG_LDSDA_RTN(TRG_SDA_RTN),
		.COM_LDSCL(COM_SCK),
		
	// JTAG signals
	// inputs
		.I2C_WRT_FIFO_DATA(I2C_wrt_fifo_data), // Data word for I2C write FIFO
		.I2C_WE(I2C_we),                       // Write enable for I2C Write FIFO
		.I2C_RDENA(I2C_rdena),                 // Read enable for I2C Readback FIFO
		.I2C_RESET(I2C_reset),                 // Reset I2C FIFO
		.I2C_START(I2C_start),                 // Start I2C processing
		.I2C_TEST_ENA_B(I2C_test_ena_b),       // Start Automated I2C testing
	// outputs
		.I2C_RBK_FIFO_DATA(I2C_rbk_fifo_data), // Data read back from I2C device
		.I2C_CLR_START(I2C_clr_start),         // Clear the I2C_START instruction
		.I2C_STATUS(I2C_status),               // STATUS word for I2C interface
		.SCOPE_SYNC(I2C_at_scope_sync),        // Scope sync for I2C auto test
		// Auto I2C test results
		.DAQ_TST_INPRGS(daq_tst_inprgs),
		.DAQ_NACK_ERRS(daq_nack_errs),
		.DAQ_NACK_FLG(daq_nack_flg),
		.DAQ_ERR_FLG(daq_err_flg),
		.DAQ_ERR_REG(daq_err_reg),
		.TRG_TST_INPRGS(trg_tst_inprgs),
		.TRG_NACK_ERRS(trg_nack_errs),
		.TRG_NACK_FLG(trg_nack_flg),
		.TRG_ERR_FLG(trg_err_flg),
		.TRG_ERR_REG(trg_err_reg)
	);



/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//  System Monitor Core                                                    //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////
  
  
  wire sys_mon_rst;
  wire vccaux_alarm,vccint_alarm,ot;
  
generate
if(Simulation==0)
begin : SysMonCode
  sysmon SYS_MON(
      .DCLK_IN(clk40),
      .RESET_IN(sys_mon_rst),
      .VAUXP0(DV4P_3_CUR_P), 
      .VAUXN0(DV4P_3_CUR_N),
      .VAUXP1(DV3P_2_CUR_P),
      .VAUXN1(DV3P_2_CUR_N),
      .VAUXP2(DV3P_25_CUR_P),
      .VAUXN2(DV3P_25_CUR_N),
      .VAUXP3(V3PDCOMP_MONP),
      .VAUXN3(V3PDCOMP_MONN),
      .VAUXP4(AV54P_3_CUR_P),
      .VAUXN4(AV54P_3_CUR_N),
      .VAUXP5(AV54P_5_CUR_P),
      .VAUXN5(AV54P_5_CUR_N),
      .VAUXP6(V3PIO_MONP),
      .VAUXN6(V3PIO_MONN),
      .VAUXP8(V25IO_MONP),
      .VAUXN8(V25IO_MONN),
      .VAUXP9(V5PACOMP_MONP),
      .VAUXN9(V5PACOMP_MONN),
      .VAUXP10(V5PAMP_MONP),
      .VAUXN10(V5PAMP_MONN),
      .VAUXP11(V18PDADC_MONP),
      .VAUXN11(V18PDADC_MONN),
      .VAUXP13(V33PAADC_MONP),
      .VAUXN13(V33PAADC_MONN),
      .VAUXP14(V5PPA_MONP),
      .VAUXN14(V5PPA_MONN),
      .VAUXP15(V5PSUB_MONP),
      .VAUXN15(V5PSUB_MONN),
 
      .VCCAUX_ALARM_OUT(vccaux_alarm),
      .VCCINT_ALARM_OUT(vccint_alarm),
      .USER_TEMP_ALARM_OUT(user_temp_alarm),
      .OT_OUT(ot),
      .VP_IN(1'b0),
      .VN_IN(1'b0)
      );
end
endgenerate


 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  Power on startup proceedure for resets                                 //
 //  and control signals for the QPLL                                       //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////

	wire por_adc_init, jtag_adc_init, csp_adc_init;
	wire adc_init_rst;
	wire jtag_sys_rst;
	wire csp_sys_rst;
	
	assign adc_init = por_adc_init | jtag_adc_init | csp_adc_init;
	assign icap_clk_ena = ~sys_rst;

	reset_manager  #(
		.Strt_dly(Strt_dly),
		.POR_tmo(POR_tmo),
		.ADC_Init_tmo(ADC_Init_tmo),
		.TDIS_pulse_duration(TDIS_pulse_duration),
		.TDIS_on_Startup(TDIS_on_Startup),
		.TMR(TMR)
	)
	rsm1(
		.STUP_CLK(strtup_clk),
		.CLK(clk40),
		.COMP_CLK(comp_clk),
		.CLK1MHZ(clk1mhz),  // 1 MHz Clock
		.CLK100KHZ(clk100khz),
		.RESYNC(resync),
		.RST_RESYNC(rst_resync),
		.EOS(eos),
		.JTAG_SYS_RST(jtag_sys_rst),
		.CSP_SYS_RST(csp_sys_rst),
		.BPI_JRST(bpi_jrst),
		.CSP_BPI_RST(csp_bpi_rst),
		.DAQ_MMCM_LOCK(daq_mmcm_lock),
		.TRG_MMCM_LOCK(trg_mmcm_lock),
		.CMP_PHS_CHANGE(cmp_phs_change),     // Comp Clock Phase Change in progress; Reset TMB path transceiver.
		.TRG_SYNC_DONE(tx_sync_done),
		.QP_ERROR(QP_ERROR),
		.QP_LOCKED(QP_LOCKED),
		.AL_DONE(al_done),
		.ADC_INIT_DONE(adc_init_done),
		.BPI_SEQ_IDLE(bpi_seq_idle),
		.DAQ_OP_RST(daq_op_rst),
		.TRG_OP_RST(trg_op_rst),
		
		.ADC_INIT_RST(adc_init_rst),
		.ADC_INIT(por_adc_init),
		.ADC_RDY(adc_rdy),
		.AL_START(por_al_start),
		.TRG_GTXTXRESET(trg_gtxtxreset),
		.MMCM_RST(mmcm_rst),
		.SYS_MON_RST(sys_mon_rst),
		.ADC_RST(adc_rst),
		.TRG_RST(comp_rst),
		.DSR_RST(dsr_rst),
		.BPI_RST(bpi_rst),
		.SYS_RST(sys_rst),
		.DAQ_FIFO_RST(daq_fifo_rst),
		.BPI_FIFO_RST(bpi_fifo_rst),
		.SLOW_FIFO_RST(slow_fifo_rst),
		.RUN(run),
		.QPLL_LOCK(qpll_lock),
		.QPLL_ERROR(qpll_error),
		.DAQ_OP_TX_DISABLE(daq_op_tx_disable),
		.TRG_OP_TX_DISABLE(trg_op_tx_disable),
		.POR_STATE(por_state)
	);


 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  JTAG Accessible User Registers                                         //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////
 
	wire [25:0] adc_mem;
	wire [11:0] adc_mask;
	wire adc_we;
	wire jc_adc_cnfg;
	wire jtag_tk_ctrl_sem;
	wire jtag_ded_rst;
	wire jtag_rst_sem_cntrs;
	wire jtag_send_cmd;
	wire [7:0] jtag_cmd_data;
	wire [23:0] sem_far_pa;
	wire [23:0] sem_far_la;
	wire [15:0] sem_errcnt;
	wire [15:0] sem_status;

	
	jtag_access  #(
		.TMR(TMR)
	) 
	jtag_acc1(
		
		.CLK1MHZ(clk1mhz),  // 1 MHz Clock
      .CLK20(clk20),      // 20 MHz Clock
      .CLK40(clk40),      // 40 MHz Clock
      .CLK120(clk120),    // 120 MHz Clock
      .FSTCLK(clk160),    // 160 MHz Clock
      .RST(sys_rst),      // Reset default state
      .EOS(eos),          // End Of Startup
		.BKY_RTN(bky_rtn),  // Serial data returned from amplifiers
		.DCFEB_STATUS(dcfeb_status),    // Status word
		.STARTUP_STATUS(startup_status),    // Startup Status word
		.QPLL_CNT(qpll_cnt),    // Count of lossing QPLL locks
		.ADCDATA(doutfifo), // Data out of pipeline
		.BPI_RBK_FIFO_DATA(bpi_rbk_fifo_data), // Data read back from BPI PROM
		.BPI_STATUS(bpi_status),     // STATUS word for BPI interface
		.BPI_TIMER(bpi_timer),     // stop watch timer for BPI commands
      .BPI_AL_REG(bpi_al_reg), // Data from BPI PROM for auto-loading
	   .I2C_RBK_FIFO_DATA(I2C_rbk_fifo_data), // Data read back from I2C device
	   .I2C_STATUS(I2C_status),    // STATUS word for I2C interface
	   .I2C_CLR_START(I2C_clr_start),// Clear the I2C_START instruction
		.SLOW_FIFO_RST(slow_fifo_rst), // Reset for Buckeye auto-load FIFO
	   .AUTO_LOAD(auto_load),         // Auto load pulse for clock enabling registers;
	   .AUTO_LOAD_ENA(auto_load_ena),     // High during Auto load process
	   .AL_CNT(al_cnt),      // Auto load counter
	   .CLR_AL_DONE(clr_al_done),  // Clear Auto Load Done flag
	   .AL_DONE(al_done),          // Auto load process complete
		
		.QP_RST_B(QP_RST_B),         // QPLL reset
		.JTAG_SYS_RST(jtag_sys_rst), // Issue the equivalent of power on reset without reprogramming.
		.RDFIFO(jrdfifo),            // Advance fifo to next word
		.JTAG_RD_MODE(jtag_rd_mode),// JTAG read out mode for FIFO1 
		.COMP_MODE(comp_mode),      // comparator mode bits [1:0]
		.COMP_TIME(comp_time),      // comparator timing bits [2:0]
		.CDAC_ENB(cdac_enb),        // Comparator DAC enable
		.CALDAC_ENB(caldac_enb),    // Calibration DAC enable
		.CALADC_ENB(caladc_enb),    // Calibration ADC enable
		.SPI_CK(spi_ck),            // Calibration DAC clock
		.SPI_DAT(spi_dat),          // Calibration DAC data
		.CAL_MODE(cal_mode),        // Calibration mode (0: external pulsing, 1: internal pulsing)
		.SPI_RTN(spi_rtn),          // Retrun data from SPI devices
		.TO_BKY(to_bky),            // Serial data sent to amplifiers
		.BKY_CLK(bky_clk),          // Shift clock for amplifiers
		.ADC_WE(adc_we),            // Write enable for ADC configuration memory
		.ADC_MEM(adc_mem),          // Data word for ADC configuration memory
		.ADC_MASK(adc_mask),        // Mask for ADCs to configure
		.ADC_INIT(jtag_adc_init),   // ADC initialization signal
      .JC_ADC_CNFG(jc_adc_cnfg),  // JTAG Controll of ADC configuration memory
      .RSTRT_PIPE(jrstrt_pipe),    // Restart pipeline on JTAG command
      .PDEPTH(pdepth),            // Pipeline Depth register (9 bits)
		.DAQ_OP_RST(daq_op_rst),    // Reset DAQ optical link by toggling transmit disable
		.TRG_OP_RST(trg_op_rst),    // Reset TRG optical link by toggling transmit disable
      .TTC_SRC(ttc_src),          // TTC source register (2 bits)
		.BPI_CMD_FIFO_DATA(bpi_cmd_fifo_data),// Data word for BPI command FIFO
		.BPI_WE(bpi_jwe),           // Write enable for BPI Write FIFO
		.BPI_RDENA(bpi_jre),        // Read enable for BPI Readback FIFO
		.BPI_RESET(bpi_jrst),       // Reset signal for BPI interface (does not reset the PROM)
		.BPI_DISABLE(BPI_disable),  // Disable BPI processing
		.BPI_ENABLE(BPI_enable),    // Enable BPI processing
		.SAMP_MAX(samp_max),        // Number of samples to readout minus 1
		.CMP_CLK_PHASE(cmp_clk_phase), // Comparator Clock Phase 5-bits (0-31)
		.SAMP_CLK_PHASE(samp_clk_phase), // Sampling Clock Phase (0-7)
		.CMP_PHS_JTAG_RST(cmp_phs_jtag_rst), // Manual reset of Comp Clock Phase MMCM;
		.SAMP_CLK_PHS_CHNG(samp_clk_phs_chng), // Sampling Clock Phase Change in progress; Reset deserializers.
		.TMB_TX_MODE(tmb_tx_mode),   // TMB transmit mode (3-bits, 0: comparator data, 1: fixed patterns, 2: counters, 3: randoms, 5: half strips).
		.LAY1_TO_6_HALF_STRIP(lay1_to_6_half_strip), //half strips to inject into data stream for each layer
		.LAYER_MASK(layer_mask),     //layer mask to indicate which layers are active.
		.JDAQ_RATE(jdaq_rate),        //DAQ Rate selection: 0 = 1GbE (1.25Gbps line rate), 1 = 2.56GbE (3.2Gbps line rate).
		.JDAQ_PRBS_TST(jdaq_prbs_tst),      // PRBS test mode from JTAG interface
		.JDAQ_INJ_ERR(jdaq_inj_err),        // Error injection requested from JTAG interface
		.USE_ANY_L1A(juse_any_l1a),   //L1A_MATCH source: 0 = L1A_MATCH = skw_rw_l1a_match, 1 = L1A_MATCH = skw_rw_l1a.
		.L1A_HEAD(jl1a_head),         //L1A_HEAD flag: 0 -> l1anum is NOT used as header in data stream, 1 -> l1anum IS used as header in data stream.
		.JTAG_TK_CTRL(jtag_tk_ctrl_sem),        // Sets csp_jtag_b signal
		.JTAG_DED_RST(jtag_ded_rst),            // Reset the double error detected flag
		.JTAG_RST_SEM_CNTRS(jtag_rst_sem_cntrs),// Reset the error counters
		.JTAG_SEND_CMD(jtag_send_cmd),          // single pulse to execute command in JTAG_CMD_DATA
		.JTAG_CMD_DATA(jtag_cmd_data),          //Data for SEM commands
		.I2C_WRT_FIFO_DATA(I2C_wrt_fifo_data),  // Data word for I2C write FIFO
		.I2C_WE(I2C_we),                        // Write enable for I2C Write FIFO
		.I2C_RDENA(I2C_rdena),                  // Read enable for I2C Readback FIFO
		.I2C_RESET(I2C_reset),                  // Reset I2C FIFO
		.I2C_START(I2C_start),                  // Start I2C processing
		.SEM_FAR_PA(sem_far_pa),                //Frame Address Register - Physical Address
		.SEM_FAR_LA(sem_far_la),                //Frame Address Register - Linear Address
		.SEM_ERRCNT(sem_errcnt),                //Error counters - {dbl,sngl} 8 bits each
		.SEM_STATUS(sem_status),                 //Status states, and error flags
		.L1ACNT(l1a_cnt),        //L1A counter value
		.L1AMCNT(l1a_mtch_cnt),       //L1A_MATCH counter value
		.INJPLSCNT(injplscnt),        //INJPLS counter value
		.EXTPLSCNT(extplscnt),        //EXTPLS counter value
		.BC0CNT(bc0cnt),              //BC0 counter value
		.CMP_PHS_ERRCNT(cmp_phs_errcnt),
		.FIFO_LOAD_ERRCNT(fifo_load_errcnt),
		.XF2RB_ERRCNT(xf2rb_errcnt),
		.RGTRNS_ERRCNT(rgtrns_errcnt),
		.SMPPRC_ERRCNT(smpprc_errcnt),
		.FRMPRC_ERRCNT(frmprc_errcnt)
//		.debug_sigs(debug_sigs)
   );
 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  ADC configuration and initialization                                   //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////
	 wire [1:0] memsel;
	 wire [4:0] addr;
	 wire [4:0] wra;

	 wire [3:0] csp_we;
	 wire [23:0] csp_wr_data;
	 wire [23:0] csp_rd_data;
	 wire [4:0] csp_wr_addr;
	 wire [4:0] csp_rd_addr;
	 wire [1:0] csp_msel;
	 wire csp_rd_ctrl;
	 
   adc_config  #(
		.TMR(TMR)
	) 
	adc_config1 (
		.CLK(clk20),         // 20 MHz Clock
		.RST(adc_init_rst),       // Reset
		.INIT(adc_init),     // Command to initialize the ADC's (on power up or on command)
	   .JCTRL(jc_adc_cnfg), // Selects JWE and JDATA as source for writing memory
		.JWE(adc_we),        // Write enable for the memory (from JTAG)
		.JDATA(adc_mem),     // Parallel data to be written to memory from JTAG
	   .CSP_WE(csp_we), // Write enables from chip scope pro control
	   .CSP_WR_DATA(csp_wr_data), // Data to be written to memory from chip scope pro
	   .CSP_WR_ADDR(csp_wr_addr), // Address to write to memory from chip scope pro
	   .CSP_RD_CTRL(csp_rd_ctrl),       // Selects CSP_RD_ADDR as source of address
	   .CSP_RD_DATA(csp_rd_data), // Data read from memory going to chip scope pro
	   .CSP_RD_ADDR(csp_rd_addr), // Address to read memory from chip scope pro
	   .CSP_MSEL(csp_msel), // memory select from chip scope pro
		.MASK(adc_mask),     // Mask for which ADC to talk to
		.CS(adc_cs),         // Chip selects for all 12 ADC's
		.SCLK(adc_sclk),     // Serial clock to ADC's
		.SDATA(adc_sdata),   // Serial data to ADC's
		.DONE(adc_init_done),  // Done signal when initialization is complete
		.la_msel(memsel),
		.la_rd_addr(addr),
		.la_wr_addr(wra)
	);
	
generate
if(USE_DAQ_CHIPSCOPE==1 || USE_DESER_CHIPSCOPE==1)
begin

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//  Chip Scope Pro Virtual I/O module                                      //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////
	wire [17:0] spare;
	wire [1:0] spr2;
	wire spr1;
	
adc_mem_vio vio0_adc_mem (
    .CONTROL(adc_mem_vio_c0), // INOUT BUS [35:0]
    .CLK(clk20),
    .SYNC_IN(csp_rd_data), // IN BUS [23:0]
    .SYNC_OUT({spare,csp_sys_rst,spr2,csp_adc_init,spr1,csp_rd_ctrl,csp_msel,csp_we,csp_wr_data,csp_wr_addr,csp_rd_addr}) // OUT BUS [63:0]
);

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//  Chip Scope Pro Logic Analyzer module                                   //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////
   wire la_trg_out;


adc_cnfg_mem_la la_adc_cnfg_mem (
    .CONTROL(adc_cnfg_mem_la_c1),
    .CLK(clk20),
    .DATA({10'h000,adc_mem,memsel,csp_rd_data,addr,wra,jc_adc_cnfg,adc_init_done,adc_rst,adc_init,1'b0,adc_we,csp_we,adc_cs,adc_sclk,adc_sdata}), // IN BUS [95:0]
    .TRIG0({1'b0,adc_init_done,adc_rst,adc_init,jc_adc_cnfg,adc_we,csp_we,adc_cs,adc_sclk,adc_sdata}), // IN BUS [23:0]
    .TRIG_OUT(la_trg_out)
);

end
else
begin
	assign spare = 18'h00000;
	assign spr2 = 2'b00;
	assign spr1 = 1'b0;
	assign csp_sys_rst = 1'b0;
	assign csp_sys_rst = csp_dsr_sys_rst;
	assign csp_adc_init = 1'b0;
	assign csp_rd_ctrl = 1'b0;
	assign csp_msel = 2'b00;
	assign csp_we = 4'h0;
	assign csp_wr_data = 24'h000000;
	assign csp_wr_addr = 5'h00;
	assign csp_rd_addr = 5'h00;
end
endgenerate

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//  Instantiate module for managing test points                            //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

	test_points
	tp_io1 (
		.CLK(clk40),
		.STUP_CLK(strtup_clk),
		.QPLL_LOCK(qpll_lock),
		.DAQ_DATA_CLK(daq_data_clk),
		.CMS80(cms80),
		.COMP_CLK(comp_clk),
		.COMP_CLK80(comp_clk80),
		.COMP_CLK160(comp_clk160),
		.CLK1MHZ(clk1mhz),
		.CLK100KHZ(clk100khz),
		.CLK20(clk20),
		.ADC_CLK(adc_clk),
		.TIMER(timer),
		.TRG_TX_PLL_LOCK(trg_tx_pll_lock),
		.TRG_GTXTXRESET(trg_gtxtxreset),
		.TRG_TXRESETDONE(trg_txresetdone),
		.TRG_SYNCDONE(tx_sync_done),
		.TRG_MMCM_LOCK(trg_mmcm_lock),
		.COMP_RST(comp_rst),
		.cmp_phs_psen(cmp_phs_psen),
		.cmp_phs_psdone(cmp_phs_psdone),
		.cmp_phs_busy(cmp_phs_busy),
		.CMP_PHS_JTAG_RST(cmp_phs_jtag_rst),
		.CMP_CLK_PHASE(cmp_clk_phase),    // Comparator Clock Phase 5 bits (0-31)
		.cmp_phase(cmp_phase),    // translated comp Phase 11 bits (0-1344)
		.CMP_PHS_CHANGE(cmp_phs_change),     // Comp Clock Phase Change in progress; Reset TMB path transceiver.
		.cmp_phs_rst(cmp_phs_rst),
		.cmp_phs_state(cmp_phs_state),
		.TRG_RST(trg_rst),
		.LCT(lct),
		.RUN(run),
		.EOS(eos),
		.POR_STATE(por_state),
		.DSR_ALGND(dsr_aligned),
		.DSR_RST(dsr_rst),
		//
		.DSR_RESYNC(dsr_resync),
		.RESYNC(resync),
		.SYS_RST(sys_rst),
		.ADC_INIT(adc_init),
		.L1A(l1a),
		.L1A_MATCH(l1a_match),
		.L1A_EVT_PUSH(l1a_evt_push),
		.ALG_GD(alg_gd),
		.I2C_START(I2C_start),
		.I2C_CLR_START(I2C_clr_start),
		.I2C_STATUS(I2C_status),
		.I2C_AT_SCOPE_SYNC(I2C_at_scope_sync),
		.I2C_TEST_ENA_B(I2C_test_ena_b),
		//
//		.SEL_CON_B(SEL_CON_B), // not used
//		.SEL_SKW_B(SEL_SKW_B), // not used
		.TP_B24_(TP_B24_),
		.TP_B25_(TP_B25_),
		.TP_B26_(TP_B26_),
		.TP_B35_(TP_B35_) // bits 9 and 10 are skipped.
	);

 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  SEM module for testing configuration memory error correction           //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////
	
generate
if(Simulation==0)
begin : SEMCode
SEM_module #(
	.USE_CHIPSCOPE(USE_SEM_CHIPSCOPE),
	.TMR(TMR)
	) 
	SEM_module_i (
    .CSP_LA0_CNTRL(sem_la0_c0),
    .CSP_VIO0_CNTRL(sem_vio_in0_c1),
    .CLK40(clk40),                          // Free running 40 MHz Clock after mmcm lock.
    .ICAP_CLK(icap_clk),                    // Clock Enabled 40MHz clock
    .RST(sys_rst),                          // Reset for state machines and FIFO
	 .JTAG_TK_CTRL(jtag_tk_ctrl_sem),        // Sets csp_jtag_b signal
	 .JTAG_DED_RST(jtag_ded_rst),            // Reset the double error detected flag
	 .JTAG_RST_SEM_CNTRS(jtag_rst_sem_cntrs),// Reset the error counters
	 .JTAG_SEND_CMD(jtag_send_cmd),          // single pulse to execute command in JTAG_CMD_DATA
	 .JTAG_CMD_DATA(jtag_cmd_data),          //Data for SEM commands
	 .SEM_FAR_PA(sem_far_pa),                //Frame Address Register - Physical Address
	 .SEM_FAR_LA(sem_far_la),                //Frame Address Register - Linear Address
	 .SEM_ERRCNT(sem_errcnt),                //Error counters - {dbl,sngl} 8 bits each
	 .SEM_STATUS(sem_status)                 //Status states, and error flags
	 );
end
endgenerate

endmodule
