`timescale 1ns / 1ps

module daq_optical_out #(
	parameter USE_CHIPSCOPE = 1,
	parameter SIM_SPEEDUP = 0,
	parameter XDCFEB = 0,
	parameter TMR = 0,
	parameter TMR_Err_Det = 0
)
(
	 inout [35:0] DAQ_TX_VIO_CNTRL, //Chip Scope Pro control signals for virtual I/O
	 inout [35:0] DAQ_TX_LA_CNTRL,  //Chip Scope Pro control signals for logic analyzer
   input RST,
	// External signals
	input DAQ_RX_N,        // GTX receive data in - signal
	input DAQ_RX_P,        // GTX receive data in + signal
	output DAQ_TX_N,       // GTX transmit data out - signal
	output DAQ_TX_P,       // GTX transmit data out + signal
	// Reference clocks ideally straight from the IBUFDS_GTXE1 output 
	input DAQ_TX_125REFCLK,     // 125 MHz for 1 GbE
	input DAQ_TX_125REFCLK_DV2, // 62.5 MHz user clock for 1 GbE
	input DAQ_TX_160REFCLK,     // 160 MHz for  2.56 GbE
	// Internal signals
	input L1A_MATCH,            // Currently only for logic analyzer input
	input [15:0] TXD,           // Data to be transmitted
	input  TXD_VLD,             // Flag for valid data; initiates data transfer
	input JDAQ_RATE,            // requested DAQ rate from JTAG interface
	input [2:0]JDAQ_PRBS_TST,   // PRBS test mode from JTAG interface
	input JDAQ_INJ_ERR,         // Error injection requested from JTAG interface
	output RATE_1_25,           // Flag to indicate 1.25 Gbps line rate operation
	output RATE_3_2,            // Flag to indicate 3.2 Gbps line rate operation
	output TX_ACK,              // Handshake signal indicates preamble has been sent, data flow should start
	output CSP_MAN_CTRL,        // Chip Scope Pro manual control for DAQ rate, L1A, and packet headers;
	output CSP_USE_ANY_L1A,     // Flag to send data on any L1A
	output CSP_L1A_HEAD,        // Flag to send L1A number at the begining of the packet
	output CSP_DAQ_TRG_OUT,     // 
	output DAQ_DATA_CLK,        // Clock that should be used for passing data and controls to this module
	output [15:0] FRMPRC_ERRCNT
  );
  
////////////////////////////////////////////////////////////////////////////////////////////////////////
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //
// ================================= Ethernet Parameters Common to both Receive and Transmit ======== //
// -------------------------------------------------------------------------------------------------- //
////////////////////////////////////////////////////////////////////////////////////////////////////////

// Define Octet constants
localparam
    D2_2  = 8'h42,        
    D5_6  = 8'hC5,        
    D16_2 = 8'h50,        
    D21_5 = 8'hB5,        
    K28_5 = 8'hBC,      
    K23_7 = 8'hF7,     // /R/ Carrier Extend
    K27_7 = 8'hFB,     // /S/ SOP
    K29_7 = 8'hFD,     // /T/ EOP
    K30_7 = 8'hFE,     // /V/ ERROR_Prop
    PRMBL = 8'h55,     // Preamble octet
    SOF_BYTE = 8'hD5;  // Start of Frame octet

localparam
    IDLE1 = {D5_6,K28_5},
    IDLE2 = {D16_2,K28_5},
    SOP_PRE = {PRMBL,K27_7},     // Start of Packet plus first preamble word 
    PREAMBLE = {PRMBL,PRMBL},     // Preamble words 
    SOF_PRE = {SOF_BYTE,PRMBL},  // Preamble plus Start of Frame word 
    Carrier_Extend = {K23_7,K23_7},  // Carrier extend 
    End_of_Packet = {K23_7,K29_7};  // End of Packet plus carrier extend 

////////////////////////////////////////////////////////////////////////////////////////////////////////
// Signals
////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	wire usr_clk_wordwise;
	
// DAQ Rate state machine outputs
	wire cdv_init;
	wire [2:0] ref_clk_sel;
	wire pcs_rst;
	wire [1:0] txrate_sel;
	wire word_clk_sel;
	wire [3:0] dqrt_state;

// Frame Proc state machine outputs
	wire crc_dv;
	wire clr_crc;
	wire [2:0] rom_addr;
	wire [3:0] frm_state;
	
	wire crc_calc;

   // Asynchronous reset signals
	wire arst;
	wire man_rst;
	wire reset;
   wire pma_reset;
	wire txresetdone;
	wire clk_rst_done;
	
    // Physical interface signals
	wire txreset;
	wire div_clk_rst;
	wire [1:0]  txbufstatus_float;
	wire txrate_done;
	wire [12:0] gtxtest;
	
   // Transceiver clocking signals
	wire txoutclk;
	wire plllock_i;
	 
	// DAQ rate control signals
	wire daq_tx_dis;
	wire man_daq_tx_dis;
	wire man_control;
	wire man_daq_rate;
	wire man_use_any_l1a;
	wire man_l1a_head;
	wire daq_rate;
	
	// PRBS signals
	wire force_error;
	reg  inj_err1;
	reg  inj_err2;


	wire [1:0] txcharisk_i;
	wire crc_vld1_i;
	wire crc_vld2_i;
	wire [15:0] mgt_tx_data_i;
	wire [15:0] crc_i;
	reg [9:0] pkt_len;
	reg [9:0] pkt_len_reg;
	
assign CSP_MAN_CTRL = man_control;
assign CSP_USE_ANY_L1A = man_use_any_l1a;
assign CSP_L1A_HEAD = man_l1a_head;


generate
if(USE_CHIPSCOPE==1) 
begin : chipscope_daq_tx
wire [15:0] daq_tx_async_in;
wire [7:0]  daq_tx_async_out;
wire [129:0] daq_tx_la_data;
wire [7:0]  daq_tx_la_trig;
wire [9:0]  daq_tx_la_trig1;
wire [9:0]  daq_tx_la_trig2;

wire [3:0] dummy_asigs;

	daq_tx_vio daq_tx_vio_i (
		 .CONTROL(DAQ_TX_VIO_CNTRL), // INOUT BUS [35:0]
		 .ASYNC_IN(daq_tx_async_in), // IN BUS [15:0]
		 .ASYNC_OUT(daq_tx_async_out) // OUT BUS [7:0]
	);


//		 ASYNC_IN [15:0]
	assign daq_tx_async_in[0]     = reset;
	assign daq_tx_async_in[1]     = pma_reset;
	assign daq_tx_async_in[2]     = arst;
	assign daq_tx_async_in[3]     = txresetdone;
	assign daq_tx_async_in[4]     = txreset;
	assign daq_tx_async_in[5]     = TXD_VLD;
	assign daq_tx_async_in[6]     = daq_tx_dis;
	assign daq_tx_async_in[7]     = man_daq_rate;
	assign daq_tx_async_in[8]     = daq_rate;
	assign daq_tx_async_in[9]     = plllock_i;
	assign daq_tx_async_in[10]     = JDAQ_RATE;
	assign daq_tx_async_in[11]     = RATE_1_25;
	assign daq_tx_async_in[12]     = RATE_3_2;
	assign daq_tx_async_in[13]     = word_clk_sel;
	assign daq_tx_async_in[14]     = txrate_done;
	assign daq_tx_async_in[15]     = 1'b0;

		 
//		 ASYNC_OUT [7:0]
	assign man_daq_tx_dis     = daq_tx_async_out[0];
	assign man_rst            = daq_tx_async_out[1];
	assign man_control        = daq_tx_async_out[2];
	assign man_daq_rate       = daq_tx_async_out[3];
	assign man_use_any_l1a    = daq_tx_async_out[4];
	assign man_l1a_head       = daq_tx_async_out[5];
	assign dummy_asigs[0]     = daq_tx_async_out[6];
	assign dummy_asigs[1]     = daq_tx_async_out[7];
		 

	daq_tx_la daq_tx_la_i (
		 .CONTROL(DAQ_TX_LA_CNTRL),
		 .CLK(usr_clk_wordwise),
		 .DATA(daq_tx_la_data), // IN BUS [119:0]
		 .TRIG0(daq_tx_la_trig), // IN BUS [7:0]
		 .TRIG1(daq_tx_la_trig1), // IN BUS [9:0]
		 .TRIG2(daq_tx_la_trig2), // IN BUS [9:0]
		 .TRIG_OUT(CSP_DAQ_TRG_OUT) // OUT
	);
	
// LA Data [109:0]
	assign daq_tx_la_data[15:0]    = TXD;
	assign daq_tx_la_data[31:16]   = crc_i;
	assign daq_tx_la_data[35:32]   = 4'h0;
	assign daq_tx_la_data[39:36]   = 4'h0;
	assign daq_tx_la_data[40]      = man_rst;
	assign daq_tx_la_data[41]      = arst;
	assign daq_tx_la_data[42]      = reset;
	assign daq_tx_la_data[43]      = pma_reset;
	assign daq_tx_la_data[44]      = man_daq_tx_dis;
	assign daq_tx_la_data[45]      = daq_tx_dis;
	assign daq_tx_la_data[46]      = txreset;
	assign daq_tx_la_data[47]      = TXD_VLD;
	assign daq_tx_la_data[48]      = TX_ACK;
	assign daq_tx_la_data[49]      = pcs_rst;
	assign daq_tx_la_data[50]      = man_control;
	assign daq_tx_la_data[51]      = txrate_done;
	assign daq_tx_la_data[52]      = man_daq_rate;
	assign daq_tx_la_data[54:53]   = txrate_sel;
	assign daq_tx_la_data[57:55]   = ref_clk_sel;
	assign daq_tx_la_data[59:58]   =  txcharisk_i;
	assign daq_tx_la_data[60]      = word_clk_sel;
	assign daq_tx_la_data[61]      = plllock_i;
	assign daq_tx_la_data[62]      = 1'b0;
	assign daq_tx_la_data[63]      = 1'b0;
	assign daq_tx_la_data[64]      = L1A_MATCH;
	assign daq_tx_la_data[65]      = 1'b0;
	assign daq_tx_la_data[66]      = JDAQ_RATE;
	assign daq_tx_la_data[67]      = RATE_1_25;
	assign daq_tx_la_data[68]      = RATE_3_2;
	assign daq_tx_la_data[69]      = daq_rate;
	assign daq_tx_la_data[73:70]   = 4'h0;
	assign daq_tx_la_data[74]      = crc_dv;
	assign daq_tx_la_data[75]      = clr_crc;
	assign daq_tx_la_data[76]      = crc_calc;
	assign daq_tx_la_data[77]      =  crc_vld1_i;
	assign daq_tx_la_data[78]      =  crc_vld2_i;
	assign daq_tx_la_data[79]      = 1'b0;
	assign daq_tx_la_data[80]      = 1'b0;
	assign daq_tx_la_data[83:81]   = rom_addr;
	assign daq_tx_la_data[87:84]   = frm_state;
	assign daq_tx_la_data[88]      = cdv_init;
	assign daq_tx_la_data[89]      = div_clk_rst;
	assign daq_tx_la_data[105:90]  = mgt_tx_data_i;
	assign daq_tx_la_data[109:106]  = dqrt_state;
	assign daq_tx_la_data[119:110]  = pkt_len_reg;
	assign daq_tx_la_data[129:120]  = pkt_len;

// LA Trigger [7:0]
	assign daq_tx_la_trig[0]      = man_rst;
	assign daq_tx_la_trig[1]      = man_daq_tx_dis;
	assign daq_tx_la_trig[2]      = TXD_VLD;
	assign daq_tx_la_trig[3]      = TX_ACK;
	assign daq_tx_la_trig[4]      = L1A_MATCH;
	assign daq_tx_la_trig[5]      = txrate_done;
	assign daq_tx_la_trig[6]      = plllock_i;
	assign daq_tx_la_trig[7]      = daq_rate;

// LA Trigger1 [9:0]
	assign daq_tx_la_trig1      = pkt_len_reg;

// LA Trigger2 [9:0]
	assign daq_tx_la_trig2      = pkt_len;

end
else
begin : no_chipscope_daq_tx
	assign man_rst = 0;
	assign man_daq_tx_dis = 0;
	assign man_control  = 0;
	assign man_daq_rate = 1;
	assign man_use_any_l1a = 0;
	assign man_l1a_head = 1;
	assign CSP_DAQ_TRG_OUT = 0;
end
endgenerate

	assign DAQ_DATA_CLK = usr_clk_wordwise;
//	assign daq_tx_dis = man_daq_tx_dis || DAQ_OP_TX_DISABLE;
	assign daq_tx_dis = 1'b0;
	assign daq_rate = man_control ? man_daq_rate : JDAQ_RATE;
	assign force_error = inj_err1 & ~inj_err2;
	assign crc_calc = crc_dv & TXD_VLD;
  
// DAQ_TDIS was reassigned in dcfeb_vttx
//generate
//if(XDCFEB==1) 
//begin : xdcfeb_daq_tx
//  assign DAQ_TDIS = daq_tx_dis;
//end
//else
//begin : dcfeb_daq_tx
//  OBUF  #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) OBUF_DAQ_TDIS (.O(DAQ_TDIS),.I(daq_tx_dis));
//end
//endgenerate

BUFGMUX daq_clk_mux_i (.O(usr_clk_wordwise),.I0(DAQ_TX_125REFCLK_DV2),.I1(DAQ_TX_160REFCLK),.S(word_clk_sel));
  
//-----------------------------------------------------------------------------
// Main body of code
//-----------------------------------------------------------------------------
	
assign arst = RST | man_rst;

generate
if(TMR==1) 
begin : DAQOP_RST_TMR

	// ASYNC_REG attribute added to simulate actual behavior under
	// asynchronous operating conditions.
	(* syn_preserve = "true" *) reg [3:0]  reset_1;
	(* syn_preserve = "true" *) reg [3:0]  reset_2;
	(* syn_preserve = "true" *) reg [3:0]  reset_3;
   (* syn_preserve = "true" *) reg [ 3:0] pma_reset_1;
   (* syn_preserve = "true" *) reg [ 3:0] pma_reset_2;
   (* syn_preserve = "true" *) reg [ 3:0] pma_reset_3;

	(* syn_keep = "true" *) wire rstout_1;
	(* syn_keep = "true" *) wire rstout_2;
	(* syn_keep = "true" *) wire rstout_3;
   (* syn_keep = "true" *) wire pma_rstout_1;
   (* syn_keep = "true" *) wire pma_rstout_2;
   (* syn_keep = "true" *) wire pma_rstout_3;

   //--------------------------------------------------------------------
   // GTX PMA reset circuitry
   //--------------------------------------------------------------------
	
   always@(posedge usr_clk_wordwise or posedge arst)
	begin
      if (arst == 1'b1) begin
         pma_reset_1 <= 4'b1111;
         pma_reset_2 <= 4'b1111;
         pma_reset_3 <= 4'b1111;
			reset_1 <= 4'b1111;
			reset_2 <= 4'b1111;
			reset_3 <= 4'b1111;
		end
      else begin
         pma_reset_1 <= {pma_reset_1[2:0], arst}; // do not use voted version here in order to maintain usage of SRL
         pma_reset_2 <= {pma_reset_2[2:0], arst};
         pma_reset_3 <= {pma_reset_3[2:0], arst};
			reset_1 <= plllock_i ? {reset_1[2:0], arst} : reset_1;
			reset_2 <= plllock_i ? {reset_2[2:0], arst} : reset_2;
			reset_3 <= plllock_i ? {reset_3[2:0], arst} : reset_3;
		end
	end

   assign pma_rstout_1 = pma_reset_1[3];
   assign pma_rstout_2 = pma_reset_2[3];
   assign pma_rstout_3 = pma_reset_3[3];
	assign rstout_1     = reset_1[3];
	assign rstout_2     = reset_2[3];
	assign rstout_3     = reset_3[3];
	
	assign pma_reset = (pma_rstout_1 & pma_rstout_2) | (pma_rstout_2 & pma_rstout_3) | (pma_rstout_1 & pma_rstout_3); // Majority logic	
	assign reset     = (rstout_1     & rstout_2    ) | (rstout_2     & rstout_3    ) | (rstout_1     & rstout_3    ); // Majority logic	

end
else 
begin : DAQOP_RST

	// ASYNC_REG attribute added to simulate actual behavior under
	// asynchronous operating conditions.
	(* ASYNC_REG = "TRUE" *)
	reg [3:0]  reset_r;
   (* ASYNC_REG = "TRUE" *)
   reg [ 3:0] pma_reset_r;

   //--------------------------------------------------------------------
   // GTX PMA reset circuitry
   //--------------------------------------------------------------------
	
   always@(posedge usr_clk_wordwise or posedge arst)
	begin
      if (arst == 1'b1) begin
         pma_reset_r <= 4'b1111;
			reset_r     <= 4'b1111;
		end
      else begin
         pma_reset_r <= {pma_reset_r[2:0], arst};
         reset_r     <= plllock_i ? {reset_r[2:0], arst} : reset_r;
		end
	end

   assign pma_reset   = pma_reset_r[3];
	assign reset       = reset_r[3];
	
end
endgenerate

generate
if(TMR==1) 
begin : DRSel_FSM_TMR
	DAQ_Rate_Sel_FSM_TMR 
	DAQ_Rate_Sel_FSM_i(
	  .CDV_INIT(cdv_init),
	  .CLK_SEL(ref_clk_sel),
	  .PCSRST(pcs_rst),
	  .RATE_1_25(RATE_1_25),
	  .RATE_3_2(RATE_3_2),
	  .RATE_SEL(txrate_sel),
	  .WRDCLKSEL(word_clk_sel),
	  .DQRT_STATE(dqrt_state),
	  .CDV_DONE(clk_rst_done),
	  .CLK(usr_clk_wordwise),
	  .DAQ_RATE(daq_rate),
	  .RST(arst),
	  .TXRATEDONE(txrate_done)
	);
end
else 
begin : DRSel_FSM
	DAQ_Rate_Sel_FSM 
	DAQ_Rate_Sel_FSM_i(
	  .CDV_INIT(cdv_init),
	  .CLK_SEL(ref_clk_sel),
	  .PCSRST(pcs_rst),
	  .RATE_1_25(RATE_1_25),
	  .RATE_3_2(RATE_3_2),
	  .RATE_SEL(txrate_sel),
	  .WRDCLKSEL(word_clk_sel),
	  .DQRT_STATE(dqrt_state),
	  .CDV_DONE(clk_rst_done),
	  .CLK(usr_clk_wordwise),
	  .DAQ_RATE(daq_rate),
	  .RST(arst),
	  .TXRATEDONE(txrate_done)
	);
end
endgenerate


//////////////////////////////////////////////////////////////////////
//                                                                  //
// Dual rate GTX transmitter                                        //
// Set TXPLLREFSELDY == 3'b000 for MGTREFCLKTX0 (DAQ_TX_125REFCLK)  //
// Set TXPLLREFSELDY == 3'b001 for MGTREFCLKTX1 (DAQ_TX_160REFCLK)  //
// Set TXRATE == 2'b10 for Divider = 2 (1.25Gbps line rate)         //
// Set TXRATE == 2'b11 for Divider = 1 ( 3.2Gbps line rate)         //
// Set word_clk_sel == 0 for 62.5MHz usr_clk_wordwise               //
// Set word_clk_sel == 1 for 160 MHz usr_clk_wordwise               //
//                                                                  //
//////////////////////////////////////////////////////////////////////

clk_div_reset #(
	.TMR(TMR)
)
clk_div_reset_i
(
	.CLK(usr_clk_wordwise),
	.PLLLKDET(plllock_i),
	.TX_RATE(txrate_sel[0]),
	.INIT(cdv_init),
   .GTXTEST_DONE(clk_rst_done),
	.GTXTEST_BIT1(div_clk_rst)
);


assign txreset = pma_reset | pcs_rst;
assign gtxtest = {11'h400,div_clk_rst,1'b0};

    daq_gtx_dual_rate_custom #
    (
        .WRAPPER_SIM_GTXRESET_SPEEDUP   (SIM_SPEEDUP)      // Set this to 1 for simulation
    )
    daq_gtx_dual_rate_custom_i
    (
        //_____________________________________________________________________
        //_____________________________________________________________________
        //GTX0  (X0Y12)

        //----------------- Receive Ports - RX Data Path interface -----------------
        .GTX0_RXRESET_IN                (pma_reset),
        //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        .GTX0_RXN_IN                    (DAQ_RX_N),
        .GTX0_RXP_IN                    (DAQ_RX_P),
        //---------------------- Receive Ports - RX PLL Ports ----------------------
        .GTX0_GREFCLKRX_IN              (1'b0),
        .GTX0_NORTHREFCLKRX_IN          (2'b00),
        .GTX0_PERFCLKRX_IN              (1'b0),
        .GTX0_RXPLLREFSELDY_IN          (3'b000),
        .GTX0_SOUTHREFCLKRX_IN          (2'b00),
        //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
        .GTX0_TXCHARISK_IN              ( txcharisk_i),
        //----------------------- Transmit Ports - GTX Ports -----------------------
        .GTX0_GTXTEST_IN                (gtxtest),
        //---------------- Transmit Ports - TX Data Path interface -----------------
        .GTX0_TXDATA_IN                 (mgt_tx_data_i),
        .GTX0_TXOUTCLK_OUT              (txoutclk),
        .GTX0_TXRESET_IN                (txreset),
        .GTX0_TXUSRCLK2_IN              (usr_clk_wordwise),
        //-------------- Transmit Ports - TX Driver and OOB signaling --------------
        .GTX0_TXN_OUT                   (DAQ_TX_N),
        .GTX0_TXP_OUT                   (DAQ_TX_P),
        //--------- Transmit Ports - TX Elastic Buffer and Phase Alignment ---------
        .GTX0_TXBUFSTATUS_OUT           (txbufstatus_float),
        //--------------------- Transmit Ports - TX PLL Ports ----------------------
        .GTX0_GREFCLKTX_IN              (1'b0),
        .GTX0_GTXTXRESET_IN             (pma_reset),
        .GTX0_MGTREFCLKTX_IN            ({DAQ_TX_160REFCLK,DAQ_TX_125REFCLK}),
        .GTX0_NORTHREFCLKTX_IN          (2'b00),
        .GTX0_PERFCLKTX_IN              (1'b0),
        .GTX0_PLLTXRESET_IN             (pma_reset),
        .GTX0_SOUTHREFCLKTX_IN          (2'b00),
        .GTX0_TXPLLLKDET_OUT            (plllock_i),
        .GTX0_TXPLLREFSELDY_IN          (ref_clk_sel),
        .GTX0_TXRATE_IN                 (txrate_sel),
        .GTX0_TXRATEDONE_OUT            (txrate_done),
        .GTX0_TXRESETDONE_OUT           (txresetdone),
         //------------------- Transmit Ports - TX PRBS Generator -------------------
        .GTX0_TXENPRBSTST_IN            (JDAQ_PRBS_TST),
        .GTX0_TXPRBSFORCEERR_IN         (force_error)

   );
    

//////////////////////////////////////////////////////////////
//                                                          //
// Force error in PRBS tests.                               //
// One per command input.                                   //
//                                                          //
//////////////////////////////////////////////////////////////

always @(posedge usr_clk_wordwise)
begin
	inj_err1 <= JDAQ_INJ_ERR;
	inj_err2 <= inj_err1;
end

always @(posedge usr_clk_wordwise)
begin
	if (clr_crc || arst) begin
		pkt_len <= 10'h000;
	end
	else begin
	   if(crc_calc)
			pkt_len <= pkt_len+1;
		else
			pkt_len <= pkt_len;
	end
end
always @(posedge usr_clk_wordwise)
begin
	if (arst) begin
		pkt_len_reg <= 10'd800;
	end
	else begin
	   if(crc_vld1_i)
			pkt_len_reg <= pkt_len;
		else
			pkt_len_reg <= pkt_len_reg;
	end
end


generate
if(TMR==1) 
begin : DAQ_Pkt_TMR

	(* syn_preserve = "true" *) reg [15:0] cnst_1;
	(* syn_preserve = "true" *) reg [15:0] cnst_2;
	(* syn_preserve = "true" *) reg [15:0] cnst_3;
	(* syn_preserve = "true" *) reg [1:0] kcnst_1;
	(* syn_preserve = "true" *) reg [1:0] kcnst_2;
	(* syn_preserve = "true" *) reg [1:0] kcnst_3;
	(* syn_preserve = "true" *) reg [1:0] txcharisk_1;
	(* syn_preserve = "true" *) reg [1:0] txcharisk_2;
	(* syn_preserve = "true" *) reg [1:0] txcharisk_3;
	(* syn_preserve = "true" *) reg txd_vld1_1;
	(* syn_preserve = "true" *) reg txd_vld1_2;
	(* syn_preserve = "true" *) reg txd_vld1_3;
	(* syn_preserve = "true" *) reg crc_vld1_1;
	(* syn_preserve = "true" *) reg crc_vld1_2;
	(* syn_preserve = "true" *) reg crc_vld1_3;
	(* syn_preserve = "true" *) reg crc_vld2_1;
	(* syn_preserve = "true" *) reg crc_vld2_2;
	(* syn_preserve = "true" *) reg crc_vld2_3;
	(* syn_preserve = "true" *) reg [15:0] data1_1;
	(* syn_preserve = "true" *) reg [15:0] data1_2;
	(* syn_preserve = "true" *) reg [15:0] data1_3;
	(* syn_preserve = "true" *) reg crc_calc1_1;
	(* syn_preserve = "true" *) reg crc_calc1_2;
	(* syn_preserve = "true" *) reg crc_calc1_3;
	(* syn_preserve = "true" *) reg [15:0] crc1_1;
	(* syn_preserve = "true" *) reg [15:0] crc1_2;
	(* syn_preserve = "true" *) reg [15:0] crc1_3;
	(* syn_preserve = "true" *) reg [15:0] mgt_tx_data_1;
	(* syn_preserve = "true" *) reg [15:0] mgt_tx_data_2;
	(* syn_preserve = "true" *) reg [15:0] mgt_tx_data_3;

	(* syn_keep = "true" *) wire [15:0] vt_cnst_1;
	(* syn_keep = "true" *) wire [15:0] vt_cnst_2;
	(* syn_keep = "true" *) wire [15:0] vt_cnst_3;
	(* syn_keep = "true" *) wire [1:0] vt_kcnst_1;
	(* syn_keep = "true" *) wire [1:0] vt_kcnst_2;
	(* syn_keep = "true" *) wire [1:0] vt_kcnst_3;
	(* syn_keep = "true" *) wire [1:0] vt_txcharisk_1;
	(* syn_keep = "true" *) wire [1:0] vt_txcharisk_2;
	(* syn_keep = "true" *) wire [1:0] vt_txcharisk_3;
	(* syn_keep = "true" *) wire vt_txd_vld1_1;
	(* syn_keep = "true" *) wire vt_txd_vld1_2;
	(* syn_keep = "true" *) wire vt_txd_vld1_3;
	(* syn_keep = "true" *) wire vt_crc_vld1_1;
	(* syn_keep = "true" *) wire vt_crc_vld1_2;
	(* syn_keep = "true" *) wire vt_crc_vld1_3;
	(* syn_keep = "true" *) wire vt_crc_vld2_1;
	(* syn_keep = "true" *) wire vt_crc_vld2_2;
	(* syn_keep = "true" *) wire vt_crc_vld2_3;
	(* syn_keep = "true" *) wire [15:0] vt_data1_1;
	(* syn_keep = "true" *) wire [15:0] vt_data1_2;
	(* syn_keep = "true" *) wire [15:0] vt_data1_3;
	(* syn_keep = "true" *) wire vt_crc_calc1_1;
	(* syn_keep = "true" *) wire vt_crc_calc1_2;
	(* syn_keep = "true" *) wire vt_crc_calc1_3;
	(* syn_keep = "true" *) wire [15:0] vt_crc1_1;
	(* syn_keep = "true" *) wire [15:0] vt_crc1_2;
	(* syn_keep = "true" *) wire [15:0] vt_crc1_3;
	(* syn_keep = "true" *) wire [15:0] vt_mgt_tx_data_1;
	(* syn_keep = "true" *) wire [15:0] vt_mgt_tx_data_2;
	(* syn_keep = "true" *) wire [15:0] vt_mgt_tx_data_3;
	
	(* syn_keep = "true" *) wire [15:0] crc_1;
	(* syn_keep = "true" *) wire [15:0] crc_2;
	(* syn_keep = "true" *) wire [15:0] crc_3;
	(* syn_keep = "true" *) wire crc_vld_1;
	(* syn_keep = "true" *) wire crc_vld_2;
	(* syn_keep = "true" *) wire crc_vld_3;
	
	assign vt_cnst_1        = (cnst_1        & cnst_2       ) | (cnst_2        & cnst_3       ) | (cnst_1        & cnst_3       ); // Majority logic
	assign vt_cnst_2        = (cnst_1        & cnst_2       ) | (cnst_2        & cnst_3       ) | (cnst_1        & cnst_3       ); // Majority logic
	assign vt_cnst_3        = (cnst_1        & cnst_2       ) | (cnst_2        & cnst_3       ) | (cnst_1        & cnst_3       ); // Majority logic
	assign vt_kcnst_1       = (kcnst_1       & kcnst_2      ) | (kcnst_2       & kcnst_3      ) | (kcnst_1       & kcnst_3      ); // Majority logic
	assign vt_kcnst_2       = (kcnst_1       & kcnst_2      ) | (kcnst_2       & kcnst_3      ) | (kcnst_1       & kcnst_3      ); // Majority logic
	assign vt_kcnst_3       = (kcnst_1       & kcnst_2      ) | (kcnst_2       & kcnst_3      ) | (kcnst_1       & kcnst_3      ); // Majority logic
	assign vt_txcharisk_1   = (txcharisk_1   & txcharisk_2  ) | (txcharisk_2   & txcharisk_3  ) | (txcharisk_1   & txcharisk_3  ); // Majority logic
	assign vt_txcharisk_2   = (txcharisk_1   & txcharisk_2  ) | (txcharisk_2   & txcharisk_3  ) | (txcharisk_1   & txcharisk_3  ); // Majority logic
	assign vt_txcharisk_3   = (txcharisk_1   & txcharisk_2  ) | (txcharisk_2   & txcharisk_3  ) | (txcharisk_1   & txcharisk_3  ); // Majority logic
	assign vt_txd_vld1_1    = (txd_vld1_1    & txd_vld1_2   ) | (txd_vld1_2    & txd_vld1_3   ) | (txd_vld1_1    & txd_vld1_3       ); // Majority logic
	assign vt_txd_vld1_2    = (txd_vld1_1    & txd_vld1_2   ) | (txd_vld1_2    & txd_vld1_3   ) | (txd_vld1_1    & txd_vld1_3       ); // Majority logic
	assign vt_txd_vld1_3    = (txd_vld1_1    & txd_vld1_2   ) | (txd_vld1_2    & txd_vld1_3   ) | (txd_vld1_1    & txd_vld1_3       ); // Majority logic
	assign vt_crc_vld1_1    = (crc_vld1_1    & crc_vld1_2   ) | (crc_vld1_2    & crc_vld1_3   ) | (crc_vld1_1    & crc_vld1_3       ); // Majority logic
	assign vt_crc_vld1_2    = (crc_vld1_1    & crc_vld1_2   ) | (crc_vld1_2    & crc_vld1_3   ) | (crc_vld1_1    & crc_vld1_3       ); // Majority logic
	assign vt_crc_vld1_3    = (crc_vld1_1    & crc_vld1_2   ) | (crc_vld1_2    & crc_vld1_3   ) | (crc_vld1_1    & crc_vld1_3       ); // Majority logic
	assign vt_crc_vld2_1    = (crc_vld2_1    & crc_vld2_2   ) | (crc_vld2_2    & crc_vld2_3   ) | (crc_vld2_1    & crc_vld2_3       ); // Majority logic
	assign vt_crc_vld2_2    = (crc_vld2_1    & crc_vld2_2   ) | (crc_vld2_2    & crc_vld2_3   ) | (crc_vld2_1    & crc_vld2_3       ); // Majority logic
	assign vt_crc_vld2_3    = (crc_vld2_1    & crc_vld2_2   ) | (crc_vld2_2    & crc_vld2_3   ) | (crc_vld2_1    & crc_vld2_3       ); // Majority logic
	assign vt_data1_1       = (data1_1       & data1_2      ) | (data1_2       & data1_3      ) | (data1_1       & data1_3      ); // Majority logic
	assign vt_data1_2       = (data1_1       & data1_2      ) | (data1_2       & data1_3      ) | (data1_1       & data1_3      ); // Majority logic
	assign vt_data1_3       = (data1_1       & data1_2      ) | (data1_2       & data1_3      ) | (data1_1       & data1_3      ); // Majority logic
	assign vt_crc_calc1_1   = (crc_calc1_1   & crc_calc1_2  ) | (crc_calc1_2   & crc_calc1_3  ) | (crc_calc1_1   & crc_calc1_3  ); // Majority logic
	assign vt_crc_calc1_2   = (crc_calc1_1   & crc_calc1_2  ) | (crc_calc1_2   & crc_calc1_3  ) | (crc_calc1_1   & crc_calc1_3  ); // Majority logic
	assign vt_crc_calc1_3   = (crc_calc1_1   & crc_calc1_2  ) | (crc_calc1_2   & crc_calc1_3  ) | (crc_calc1_1   & crc_calc1_3  ); // Majority logic
	assign vt_crc1_1        = (crc1_1        & crc1_2       ) | (crc1_2        & crc1_3       ) | (crc1_1        & crc1_3       ); // Majority logic
	assign vt_crc1_2        = (crc1_1        & crc1_2       ) | (crc1_2        & crc1_3       ) | (crc1_1        & crc1_3       ); // Majority logic
	assign vt_crc1_3        = (crc1_1        & crc1_2       ) | (crc1_2        & crc1_3       ) | (crc1_1        & crc1_3       ); // Majority logic
	assign vt_mgt_tx_data_1 = (mgt_tx_data_1 & mgt_tx_data_2) | (mgt_tx_data_2 & mgt_tx_data_3) | (mgt_tx_data_1 & mgt_tx_data_3); // Majority logic
	assign vt_mgt_tx_data_2 = (mgt_tx_data_1 & mgt_tx_data_2) | (mgt_tx_data_2 & mgt_tx_data_3) | (mgt_tx_data_1 & mgt_tx_data_3); // Majority logic
	assign vt_mgt_tx_data_3 = (mgt_tx_data_1 & mgt_tx_data_2) | (mgt_tx_data_2 & mgt_tx_data_3) | (mgt_tx_data_1 & mgt_tx_data_3); // Majority logic

	assign crc_vld_1 = !TXD_VLD & vt_txd_vld1_1; // trailing edge of valid data
	assign crc_vld_2 = !TXD_VLD & vt_txd_vld1_2; // trailing edge of valid data
	assign crc_vld_3 = !TXD_VLD & vt_txd_vld1_3; // trailing edge of valid data

	assign txcharisk_i   = vt_txcharisk_1;
	assign crc_vld1_i    = vt_crc_vld1_1;
	assign crc_vld2_i    = vt_crc_vld2_1;
	assign mgt_tx_data_i = vt_mgt_tx_data_1;
	
	assign crc_i         = (crc_1 & crc_2) | (crc_2 & crc_3) | (crc_1 & crc_3); // Majority logic
	
//////////////////////////////////////////////////////////////
//                                                          //
// ROM for Idles, Preamble, Data Fill, Carrier Extend,      //
// and inter packet spacing.                                //
//                                                          //
//////////////////////////////////////////////////////////////


always @(posedge usr_clk_wordwise)
begin: Frame_ROM
   case(rom_addr)
      3'd0: cnst_1 <= IDLE2;
      3'd1: cnst_1 <= SOP_PRE;
      3'd2: cnst_1 <= PREAMBLE;
      3'd3: cnst_1 <= SOF_PRE;
      3'd4: cnst_1 <= 16'h0000;
      3'd5: cnst_1 <= End_of_Packet;
      3'd6: cnst_1 <= Carrier_Extend;
      default: cnst_1 <= IDLE2;
   endcase
   case(rom_addr)
      3'd0: cnst_2 <= IDLE2;
      3'd1: cnst_2 <= SOP_PRE;
      3'd2: cnst_2 <= PREAMBLE;
      3'd3: cnst_2 <= SOF_PRE;
      3'd4: cnst_2 <= 16'h0000;
      3'd5: cnst_2 <= End_of_Packet;
      3'd6: cnst_2 <= Carrier_Extend;
      default: cnst_2 <= IDLE2;
   endcase
   case(rom_addr)
      3'd0: cnst_3 <= IDLE2;
      3'd1: cnst_3 <= SOP_PRE;
      3'd2: cnst_3 <= PREAMBLE;
      3'd3: cnst_3 <= SOF_PRE;
      3'd4: cnst_3 <= 16'h0000;
      3'd5: cnst_3 <= End_of_Packet;
      3'd6: cnst_3 <= Carrier_Extend;
      default: cnst_3 <= IDLE2;
   endcase
end
// Matching ROM for CHAR_IS_K tags. 
always @(posedge usr_clk_wordwise)
begin: Frame_ROM_KWORD
   case(rom_addr)
      3'd0: kcnst_1 <= 2'b01;
      3'd1: kcnst_1 <= 2'b01;
      3'd2: kcnst_1 <= 2'b00;
      3'd3: kcnst_1 <= 2'b00;
      3'd4: kcnst_1 <= 2'b00;
      3'd5: kcnst_1 <= 2'b11;
      3'd6: kcnst_1 <= 2'b11;
      default: kcnst_1 <= 2'b01;
   endcase
   case(rom_addr)
      3'd0: kcnst_2 <= 2'b01;
      3'd1: kcnst_2 <= 2'b01;
      3'd2: kcnst_2 <= 2'b00;
      3'd3: kcnst_2 <= 2'b00;
      3'd4: kcnst_2 <= 2'b00;
      3'd5: kcnst_2 <= 2'b11;
      3'd6: kcnst_2 <= 2'b11;
      default: kcnst_2 <= 2'b01;
   endcase
   case(rom_addr)
      3'd0: kcnst_3 <= 2'b01;
      3'd1: kcnst_3 <= 2'b01;
      3'd2: kcnst_3 <= 2'b00;
      3'd3: kcnst_3 <= 2'b00;
      3'd4: kcnst_3 <= 2'b00;
      3'd5: kcnst_3 <= 2'b11;
      3'd6: kcnst_3 <= 2'b11;
      default: kcnst_3 <= 2'b01;
   endcase
end 

// Pipeline signals for timing

	always @(posedge usr_clk_wordwise)
	begin
		txcharisk_1 <= vt_kcnst_1;
		txcharisk_2 <= vt_kcnst_2;
		txcharisk_3 <= vt_kcnst_3;
		txd_vld1_1 <= TXD_VLD;
		txd_vld1_2 <= TXD_VLD;
		txd_vld1_3 <= TXD_VLD;
		crc_vld1_1 <= crc_vld_1;
		crc_vld1_2 <= crc_vld_2;
		crc_vld1_3 <= crc_vld_3;
		crc_vld2_1 <= vt_crc_vld1_1;
		crc_vld2_2 <= vt_crc_vld1_2;
		crc_vld2_3 <= vt_crc_vld1_3;
		data1_1 <= TXD;
		data1_2 <= TXD;
		data1_3 <= TXD;
		crc_calc1_1 <= crc_calc;
		crc_calc1_2 <= crc_calc;
		crc_calc1_3 <= crc_calc;
		crc1_1 <= crc_1;
		crc1_2 <= crc_2;
		crc1_3 <= crc_3;
	end
	always @(posedge usr_clk_wordwise)
	begin
		if (reset) begin
			mgt_tx_data_1 <= IDLE2;
			mgt_tx_data_2 <= IDLE2;
			mgt_tx_data_3 <= IDLE2;
		end
		else begin
			mgt_tx_data_1 <= (vt_crc_vld1_1 || vt_crc_vld2_1) ? vt_crc1_1 : (vt_crc_calc1_1 ? vt_data1_1 : vt_cnst_1);
			mgt_tx_data_2 <= (vt_crc_vld1_2 || vt_crc_vld2_2) ? vt_crc1_2 : (vt_crc_calc1_2 ? vt_data1_2 : vt_cnst_2);
			mgt_tx_data_3 <= (vt_crc_vld1_3 || vt_crc_vld2_3) ? vt_crc1_3 : (vt_crc_calc1_3 ? vt_data1_3 : vt_cnst_3);
		end
	end

	crc_gen_tmr crc_gen_tmr_i(
		.CRC1(crc_1),
		.CRC2(crc_2),
		.CRC3(crc_3),
		.D(TXD),
		.CALC(crc_calc),
		.INIT(clr_crc),
		.D_VALID(crc_dv),
		.CLK(usr_clk_wordwise),
		.RESET(reset)
	);
	
end
else 
begin : DAQ_Pkt

	reg [15:0] cnst;
	reg [1:0] kcnst;
	reg [1:0] txcharisk_r;
	reg txd_vld1;
	reg crc_vld1;
	reg crc_vld2;
	reg [15:0] data1;
	reg crc_calc1;
	reg [15:0] crc1;
	reg [15:0] mgt_tx_data_r;

	wire [15:0] crc;
	wire crc_vld;

	assign crc_vld = !TXD_VLD & txd_vld1; // trailing edge of valid data

	assign txcharisk_i   = txcharisk_r;
	assign crc_vld1_i    = crc_vld1;
	assign crc_vld2_i    = crc_vld2;
	assign mgt_tx_data_i = mgt_tx_data_r;
	assign crc_i         = crc;
	
//////////////////////////////////////////////////////////////
//                                                          //
// ROM for Idles, Preamble, Data Fill, Carrier Extend,      //
// and inter packet spacing.                                //
//                                                          //
//////////////////////////////////////////////////////////////


always @(posedge usr_clk_wordwise)
begin: Frame_ROM
   case(rom_addr)
      3'd0: cnst <= IDLE2;
      3'd1: cnst <= SOP_PRE;
      3'd2: cnst <= PREAMBLE;
      3'd3: cnst <= SOF_PRE;
      3'd4: cnst <= 16'h0000;
      3'd5: cnst <= End_of_Packet;
      3'd6: cnst <= Carrier_Extend;
      default: cnst <= IDLE2;
   endcase
end
// Matching ROM for CHAR_IS_K tags. 
always @(posedge usr_clk_wordwise)
begin: Frame_ROM_KWORD
   case(rom_addr)
      3'd0: kcnst <= 2'b01;
      3'd1: kcnst <= 2'b01;
      3'd2: kcnst <= 2'b00;
      3'd3: kcnst <= 2'b00;
      3'd4: kcnst <= 2'b00;
      3'd5: kcnst <= 2'b11;
      3'd6: kcnst <= 2'b11;
      default: kcnst <= 2'b01;
   endcase
end 

// Pipeline signals for timing

	always @(posedge usr_clk_wordwise)
	begin
		txcharisk_r <= kcnst;
		txd_vld1 <= TXD_VLD;
		crc_vld1 <= crc_vld;
		crc_vld2 <= crc_vld1;
		data1 <= TXD;
		crc_calc1 <= crc_calc;
		crc1 <= crc;
	end
	always @(posedge usr_clk_wordwise)
	begin
		if (reset) begin
			mgt_tx_data_r <= IDLE2;
		end
		else begin
			mgt_tx_data_r <= (crc_vld1 || crc_vld2) ? crc1 : (crc_calc1 ? data1 : cnst);
		end
	end

	crc_gen crc_gen_i(
		.crc(crc),
		.d(TXD),
		.calc(crc_calc),
		.init(clr_crc),
		.d_valid(crc_dv),
		.clk(usr_clk_wordwise),
		.reset(reset)
	);
end
endgenerate

generate
if(TMR==1 && TMR_Err_Det==1) 
begin : Frm_Proc_FSM_TMR_Err_Det
	Frame_Proc_FSM_TMR_Err_Det
	Frame_Proc_FSM_i (
	  .CLR_CRC(clr_crc),
	  .CRC_DV(crc_dv),
	  .ROM_ADDR(rom_addr),
	  .TX_ACK(TX_ACK),
	  .FRM_STATE(frm_state),
	  .TMR_ERR_COUNT(FRMPRC_ERRCNT),
	  .CLK(usr_clk_wordwise),
	  .RST(arst),
	  .VALID(TXD_VLD) 
	);
end
else if(TMR==1) 
begin : Frm_Proc_FSM_TMR
	Frame_Proc_FSM_TMR
	Frame_Proc_FSM_i (
	  .CLR_CRC(clr_crc),
	  .CRC_DV(crc_dv),
	  .ROM_ADDR(rom_addr),
	  .TX_ACK(TX_ACK),
	  .FRM_STATE(frm_state),
	  .CLK(usr_clk_wordwise),
	  .RST(arst),
	  .VALID(TXD_VLD) 
	);
assign FRMPRC_ERRCNT = 0;
end
else 
begin : Frm_Proc_FSM
	Frame_Proc_FSM
	Frame_Proc_FSM_i (
	  .CLR_CRC(clr_crc),
	  .CRC_DV(crc_dv),
	  .ROM_ADDR(rom_addr),
	  .TX_ACK(TX_ACK),
	  .FRM_STATE(frm_state),
	  .CLK(usr_clk_wordwise),
	  .RST(arst),
	  .VALID(TXD_VLD) 
	);
assign FRMPRC_ERRCNT = 0;
end
endgenerate

endmodule
