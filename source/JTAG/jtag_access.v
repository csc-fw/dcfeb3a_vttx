`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:02:31 02/24/2011 
// Design Name: 
// Module Name:    jtag_access 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
//    JTAG functionality, instantiate shift registers for capture and settings,
//    also contains serial interfaces to off chip devices
//
// Function  Description
// ---------------------------------------
//   0     | No Op 
//   1     | JTAG System Reset (JTAG_SYS_RST), Equivalent to power on reset without reprogramming. Instruction only, (Auto reset)
//   2     | DCFEB status reg (32 bits) shift only for reading back without updating
//   3     | DCFEB status reg (32 bits) capture and shift for updated information.
//   4     | Program Comparator DAC -- same as in old CFEB
//   5     | Set Extra L1a Delay (2 bits) -- not used on DCFEB, exist for compatability with old DMB
//   6     | Read FIFO 1 -- ADC data (16 channels x 12 bits = 192 bits) wide X (6 chips x 8 sample)/event deep
//   7     | Set F5, F8, and F9 in one serial loop (daisy chained) for compatability with old DMB
//   8     | Set Pre Block End (4 bits) (not needed in DCFEB) -- not used on DCFEB, exist for compatability with old DMB
//   9     | Set Comparator Mode and Timing (5 bits) same format as old CFEB
//  10     | Set Buckeye Mask for shifting (6 bits) (default 6'b111111) same format as old CFEB, one bit for each chip
//  11     | Shift data to/from Buckeye chips (48 bits/chip)
//  12     | Set ADC configuration MASK (12 bits)
//  13     | Command to initialize ADC -- Instruction only, (Auto reset)
//  14     | Shift data and write to ADC configuration memory (26 bits)
//  15     | Command to restart pipeline -- Instruction only, (Auto reset)
//  16     | Set pipeline depth (9 bits)
//  17     | Set TTC source (2 bits) Selects 0:FF_EMU_mode, 1:FF_EEM_mode, or 2:Skew_Clr_mode
//  18     | Set calibration mode to external. (only for optical modes) -- Instruction only
//  19     | Set calibration mode to internal. (only for optical modes) -- Instruction only
//  20     | Set number of samples to readout (7 bits).
//  21     | Write word to BPI interface write FIFO (16 bits).
//  22     | Read word from BPI readback FIFO (16 bits).
//  23     | Read status word from BPI interface (16 bits).
//  24     | Read BPI timer (32 bits).
//  25     | Reset BPI interface. -- Instruction only, (Auto reset)
//  26     | Disable BPI processing. -- Instruction only, persisting
//  27     | Enable BPI processing. -- Instruction only, persisting
//  28     | Comparator Clock phase register (5-bits, 0-31).
//  29     | TMB transmit mode (2-bits, 0: comparator data, 1: fixed patterns, 2: counters, 3: randoms, 4: comparator data, 5: half strip patterns).
//  30     | TMB half strips for injecting patterns into the optical serial data stream for transmit mode 5. (30-bits, 5 per layer) {ly6,...ly1}
//  31     | TMB layer mask to indicat the active layers for half strip patterns in transmit mode 5. (6-bits, 1 per layer)
//  32     | Set DAQ rate to 1 GbE (1.25Gbps line rate) -- Instruction only
//  33     | Set DAQ rate to 2.56 GbE (3.2Gbps line rate) -- Instruction only
//  34     | Program Calibration DAC -- same style as Comparator DAC
//  35     | Send Control Byte to the MAX 1271 ADC (and conversion clocks)
//  36     | Read back the MAX 1271 ADC conversion stored in the SPI return register.
//  37     | Read the SEM status (10 bits).
//  38     | Reset the configuration ECC error counters. -- Instruction only, (Auto reset)
//  39     | Read the ECC error counters (16-bits total, {8-bits for multi-bit error count, 8-bits for single-bit error counts})
//  40     | Set L1A_MATCH source to use only matched L1A's (skw_rw_l1a_match). Clear the USE_ANY_L1A flag. -- Instruction only
//  41     | Set L1A_MATCH source to use any L1A to send data (skw_rw_l1a). Set the USE_ANY_L1A flag. -- Instruction only
//  42     | Disable l1anum use in data to ODMB. Clear the L1A_HEAD flag. -- Instruction only
//  43     | Enable l1anum use in data to ODMB. Set the L1A_HEAD flag.  This is the default -- Instruction only
//  44     | Sampling Clock phase register (3-bits, 0-7).
//  45     | PRBS test mode for DAQ optical path (3-bits, 0-7).
//  46     | Inject error into PRBS test for DAQ optical path.
//  47     | Take control of the SEM command interface (only needs to be set after ChipScope Pro has been in control).
//  48     | Reset the double error detected flag (SEM module).
//  49     | Send ASCII command to the SEM controller (8-bits). 
//  50     | Frame Address Register (FAR) in Linear Address format indicating the frame containing the error (24-bits). 
//  51     | Frame Address Register (FAR) in Physical Address format indicating the frame containing the error (24-bits). 
//  52     | Register Selection Word (Reg_Sel_Wrd) for selecting which register to independently capture and readback (8-bits). 
//  53     | Readback Select Register: Register to capture selected register indicated in Reg_Sel_Wrd (16-bits). 
//  54     | QPLL reset: This requires a NoOp afterwards to clear the reset then a Hard reset.  All clocks stop while active. QPLL takes 0.5 seconds to lock. 
//  55     | QPLL lock lost counter (8-bits). 
//  56     | Startup Status register (16-bits).  {qpll_lock,qpll_error,qpll_cnt_ovrflw,1'b0,eos,trg_mmcm_lock,daq_mmcm_lock,adc_rdy,run,al_status[2:0],por_state[3:0]};
//  57     | Read L1A counter (24 bits).
//  58     | Read L1A_MATCH counter (12 bits).
//  59     | Read INJPLS counter (12 bits).
//  60     | Read EXTPLS counter (12 bits).
//  61     | Read BC0 counter (12 bits).
//  62     | Comparator Clock Phase Reset (CMP_PHS_JTAG_RST),  Instruction only, (Auto reset)
//  63     | Toggle transmit disable on DAQ optical transceiver
//  64     | Toggle transmit disable on TRG optical transceiver
//  65     | Enable  ECC for parameters storage in XCF08P PROM Set   the ECC flag. -- Instruction only, persisting  This is the default 
//  66     | Disable ECC for parameters storage in XCF08P PROM Clear the ECC flag. -- Instruction only, persisting
//  67     | Enable  CRC for parameters storage in XCF08P PROM Set   the CRC flag. -- Instruction only, persisting
//  68     | Disable CRC for parameters storage in XCF08P PROM Clear the CRC flag. -- Instruction only, persisting  This is the default 
//  69     | Enable  ECC Decoding for parameters readback of XCF08P PROM Set   the DECODE flag. -- Instruction only, persisting  This is the default 
//  70     | Disable ECC Decoding for parameters readback of XCF08P PROM Clear the DECODE flag. -- Instruction only, persisting
//  71     | Initiate transfer of parameters from XCF08P PROM to readback FIFO -- Instruction only,  (Auto reset)
//  72     | Read word from XCF08P PROM readback FIFO (16 bits).
//  73     | Enable  GBT Testing mode -- Instruction only, persisting 
//  74     | Disable GBT Testing mode -- Instruction only, persisting  This is the default
//  75     | Enable power to GBT -- Instruction only, persisting  This is the default 
//  76     | Disable power to GBT -- Instruction only, persisting
//  77     | Write Byte to I2C write FIFO (8 bits).
//  78     | Read Byte from I2C readback FIFO (8 bits).
//  79     | Read I2C status word from I2C interface (8 bits).
//  80     | Reset I2C interface. -- Instruction only, (Auto reset)
//  81     | Start I2C processing. -- Instruction only, persisting until new command or processing completed

//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module jtag_access #(
	parameter TMR = 0
)(
	 
    input CLK1MHZ,           // 1 MHz Clock
    input CLK20,             // 20 MHz Clock
    input CLK40,             // 40 MHz Clock
    input CLK120,            // 120 MHz Clock
    input FSTCLK,            // Fast Clock
    input RST,               // Reset default state
    input EOS,               // End Of Startup
    input [6:1] BKY_RTN,     // Serial data returned from amplifiers
    input [15:0] DCFEB_STATUS, // Status word
    input [15:0] STARTUP_STATUS, // Startup Status word
    input [7:0] QPLL_CNT,    // Count of lossing QPLL lock
    input [191:0] ADCDATA,   // Data out of pipeline
    input [15:0] BPI_RBK_FIFO_DATA, // Data read back from BPI PROM
    input [15:0] BPI_STATUS, // STATUS word for BPI interface
    input [31:0] BPI_TIMER,  // Timer for BPI commands
    input [15:0] BPI_AL_REG, // Data from BPI PROM for auto-loading
	 input [7:0] I2C_RBK_FIFO_DATA, // Data read back from I2C device
	 input [7:0] I2C_STATUS,  // STATUS word for I2C interface
	 input I2C_CLR_START,     // Clear the I2C_START instruction
	 input SLOW_FIFO_RST,     // Reset for Buckeye auto-load FIFO
	 input AUTO_LOAD,         // Auto load pulse for clock enabling registers;
	 input AUTO_LOAD_ENA,     // High during Auto load process
	 input [5:0] AL_CNT,      // Auto load counter
	 input CLR_AL_DONE,       // Clear Auto Load Done flag
	 output reg AL_DONE,      // Auto load process complete
    output QP_RST_B,         // QPLL reset signal external connection
	 output JTAG_SYS_RST,     // JTAG initiated system reset 
    output reg RDFIFO,       // Advance fifo to next word
	 output JTAG_RD_MODE,     // JTAG read out mode for FIFO1 
//    output [1:0] XL1DLYSET,  // Extra L1A delay setting [1:0]
//    output [3:0] LOADPBLK,   // Pre-blockend bits [3:0] not used in DCFEB
    output [1:0] COMP_MODE,  // comparator mode bits [1:0]
    output [2:0] COMP_TIME,  // comparator timing bits [2:0]
	 output CDAC_ENB,         // Comparator DAC enable
	 output CALDAC_ENB,       // Calibration DAC enable
	 output CALADC_ENB,       // Calibration ADC enable
	 output SPI_CK,           // SPI clock
	 output SPI_DAT,          // SPI data
	 input  SPI_RTN,          // Return data from SPI devices
	 output reg CAL_MODE,     // Calibration mode (0: external pulsing, 1: internal pulsing)
    output [6:1] TO_BKY,     // Serial data sent to amplifiers
    output [6:1] BKY_CLK,    // Shift clock for amplifiers
    output reg ADC_WE,       // Write enable for ADC configuration memory
    output [25:0] ADC_MEM,   // Data word for ADC configuration memory
    output [11:0] ADC_MASK,  // Mask for ADCs to configure
    output ADC_INIT,         // ADC initialization signal
    output JC_ADC_CNFG,      // JTAG Controll of ADC configuration memory
	 output RSTRT_PIPE,       // Restart pipeline on JTAG command
    output [8:0] PDEPTH,     // Pipeline Depth register (9 bits)
	 output DAQ_OP_RST,       // Reset DAQ optical link by toggling transmit disable
	 output TRG_OP_RST,       // Reset TRG optical link by toggling transmit disable
    output [1:0] TTC_SRC,    // TTC source register (2 bits)
    output [15:0] BPI_CMD_FIFO_DATA,   // Data word for BPI command FIFO
    output reg BPI_WE,       // Write enable for BPI Write FIFO
    output reg BPI_RDENA,    // Read enable for BPI Readback FIFO
    output BPI_RESET,        // Reset signal for BPI interface (does not reset the PROM)
    output BPI_DISABLE,      // Disable BPI processing
    output BPI_ENABLE,       // Enable BPI processing
	 output [6:0] SAMP_MAX,   // Number of samples to readout minus 1
	 output [4:0] CMP_CLK_PHASE,  // Comparator Clock Phase register value (0-15).
	 output [2:0] SAMP_CLK_PHASE, // Sampling Clock Phase register value (0-7).
	 output CMP_PHS_JTAG_RST,  // Comparator Clock manual Phase reset,
	 output SAMP_CLK_PHS_CHNG,    // Sampling Clock Phase Change in progress; Reset deserializers.
	 output [2:0] TMB_TX_MODE,    // TMB transmit mode (2-bits, 0: comparator data, 1: fixed patterns, 2: counters, 3: randoms).
	 output [29:0] LAY1_TO_6_HALF_STRIP, // TMB half strips for injecting patterns into the optical serial data stream
	 output [5:0] LAYER_MASK, // layer mask to indicate which layers to use for active half strips.
	 output reg JDAQ_RATE,    //DAQ Rate selection: 0 = 1GbE (1.25Gbps line rate), 1 = 2.56GbE (3.2Gbps line rate).
	 output [2:0]JDAQ_PRBS_TST,   // PRBS test mode from JTAG interface
	 output JDAQ_INJ_ERR,         // Error injection requested from JTAG interface
	 output reg USE_ANY_L1A,   //L1A_MATCH source: 0 -> L1A_MATCH = skw_rw_l1a_match, 1 -> L1A_MATCH = skw_rw_l1a.
	 output reg L1A_HEAD,      //L1A_HEAD flag: 0 -> l1anum is NOT used as header in data stream, 1 -> l1anum IS used as header in data stream.
	 output JTAG_TK_CTRL,            // Sets csp_jtag_b signal
	 output JTAG_DED_RST,            // Reset the double error detected flag
	 output JTAG_RST_SEM_CNTRS,      // Reset the error counters
	 output reg JTAG_SEND_CMD,       // single pulse to execute command in JTAG_CMD_DATA
	 output [7:0] JTAG_CMD_DATA, //Data for SEM commands
	 output [7:0] I2C_WRT_FIFO_DATA,  // Data word for I2C write FIFO
	 output reg I2C_WE,               // Write enable for I2C Write FIFO
	 output reg I2C_RDENA,            // Read enable for I2C Readback FIFO
	 output I2C_RESET,                // Reset I2C FIFO
	 output I2C_START,                // Start I2C processing
	 input [23:0] SEM_FAR_PA,    //Frame Address Register - Physical Address
	 input [23:0] SEM_FAR_LA,    //Frame Address Register - Linear Address
	 input [15:0] SEM_ERRCNT,    //Error counters - {dbl,sngl} 8 bits each
	 input [15:0] SEM_STATUS,     //Status states, and error flags
	 input [23:0] L1ACNT,        //L1A counter value
	 input [11:0] L1AMCNT,       //L1A_MATCH counter value
	 input [11:0] INJPLSCNT,     //INJPLS counter value
	 input [11:0] EXTPLSCNT,     //EXTPLS counter value
	 input [11:0] BC0CNT,        //BC0 counter value
	 input [15:0] CMP_PHS_ERRCNT,   //TMR error counters
	 input [15:0] FIFO_LOAD_ERRCNT,
	 input [15:0] XF2RB_ERRCNT,
	 input [15:0] RGTRNS_ERRCNT,
	 input [15:0] SMPPRC_ERRCNT,
	 input [15:0] FRMPRC_ERRCNT
	 //	 output [20:0] debug_sigs
	 );


	// temp la output
//	wire [18:0] al_cdac_dbg;
//	assign debug_sigs = {al_cth_sdata, al_cth_shck, al_cdac_dbg};
   //
    wire [1:0] XL1DLYSET;  // Extra L1A delay setting [1:0]
    wire [3:0] LOADPBLK;   // Pre-blockend bits [3:0] not used in DCFEB

   reg dshift;
   reg we,pre_we,pre_rd;
   reg we21,pre_we21,pre_rd22;
   reg we49,pre_we49;
   reg we77,pre_we77,pre_rd78;
	
//
// BSCAN signals
//
   wire capture1;
   wire drck1;
   wire jreset1;
   wire runtest1;
   wire jsel1;
   wire jshift1;
   wire tck1;
   wire tdi1;
   wire tms1;
   wire update1;
   wire tdo1;
   wire capture2;
   wire drck2;
   wire jreset2;
   wire runtest2;
   wire jsel2;
   wire jshift2;
   wire tck2;
   wire tdi2;
   wire tms2;
   wire update2;
   wire tdo2;
	wire clrf;
	wire p_in;
	wire tck2_raw;
	wire mixclk;
	

	wire [95:0] f; //JTAG functions (one hot);
	wire lxdlyout,prbout,dsy7,dmy2,dmy3,dmy4,dmy5,dmy6,dmy7,dmy8,dmy9,dmy10,dmy11,dmy12,dmy13,dmy14,dmy15,dmy16;
	wire tdof2a3,tdof5,tdof6,tdof8,tdof9,tdofa,tdofc,tdofe,tdof10,tdof11,tdof14,tdof15;
	wire tdof16,tdof17,tdof18,tdof1c,tdof1d,tdof1e,tdof1f,tdof24,tdof25,tdof27,tdof2c,tdof2d,tdof31;
	wire tdof32,tdof33,tdof34,tdof35,tdof37,tdof38,tdof39,tdof3a,tdof3b,tdof3c,tdof3d;
	wire tdof4d,tdof4e,tdof4f;
	wire [31:16] status_h;
   wire [6:1] bky_mask;
	wire [6:0] nsamp;
	reg [11:0] clr_pip;
	reg f18dly, f19dly;
	reg f32dly, f33dly;
	reg clr_cal_mode, set_cal_mode;
	reg f40dly, f41dly;
	reg clr_use_any_l1a, set_use_any_l1a;
	reg f42dly, f43dly;
	reg clr_l1a_head, set_l1a_head;
	reg set_rate_1_25, set_rate_3_2;
	reg [15:0] spi_rtn_reg;
	wire [7:0] reg_sel_wrd;
	reg [15:0] sel_reg;

// Auto Load constants
	wire al_bshift_done;
	wire al_bky_shck;
	wire al_bky_shck_ena;
	wire al_bky_ena;
	wire al_bky_sdata;
	wire al_bky_shift;
	
	wire al_cthresh_done;
	wire al_cth_shck;
	wire al_cth_shck_ena;
	wire al_cth_sdata;
	wire al_dac_enb;
	
	reg [1:0] cmode_hold;
	wire al_abort;
	wire al_cthresh;
	wire al_cmode;
	wire al_ctime;
	wire al_cmp_clk_phase;
	wire al_samp_clk_phase;
	wire al_nsamp;
	wire al_pdepth;

	wire not_eos;
	wire rst_qpll;
	
// clock synchronizing signals

   reg p_in_s1;
   reg f18_s1;
   reg f19_s1;
   reg f21_up2_s1;
   reg f22_up2_s1;
   reg f32_s1;
   reg f33_s1;
   reg f40_s1;
   reg f41_s1;
   reg f42_s1;
   reg f43_s1;
   reg f49_up2_s1;
   reg f77_up2_s1;
   reg f78_up2_s1;

   reg p_in_s2;
   reg f18_s2;
   reg f19_s2;
   reg f21_up2_s2;
   reg f22_up2_s2;
   reg f32_s2;
   reg f33_s2;
   reg f40_s2;
   reg f41_s2;
   reg f42_s2;
   reg f43_s2;
   reg f49_up2_s2;
   reg f77_up2_s2;
   reg f78_up2_s2;

 
	assign rst_qpll = f[54];
	OBUF  #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) OBUF_QP_RST (.O(QP_RST_B),.I(~rst_qpll));

	assign not_eos = !EOS;
	assign SAMP_MAX = nsamp-1;
	assign JC_ADC_CNFG = f[14];
	
	
	assign tdo2 = (tdof2a3 | tdof5 |  tdof6 | dsy7 | tdof8 | tdof9 | tdofa | tdofb | tdofc | tdofe | 
						tdof10 | tdof11 | tdof14 | tdof15 | tdof16 | tdof17 | tdof18 | tdof1c | tdof1d | tdof1e | tdof1f |
						tdof24 | tdof25 | tdof27 | tdof2c | tdof2d |
						tdof31 | tdof32 | tdof33 | tdof34 | tdof35 | tdof37 | tdof38 | tdof39 | tdof3a | tdof3b | tdof3c | tdof3d |
						tdof4d | tdof4e | tdof4f);
						
	assign status_h[31:16] = {5'b10110,XL1DLYSET,LOADPBLK,COMP_TIME,COMP_MODE};
	
	assign JTAG_SYS_RST        = f[1];   // System Reset JTAG command (like power on reset without reprogramming)
	assign JTAG_RD_MODE        = f[6];   // JTAG readout mode when reading ADC data
	assign ADC_INIT            = f[13];  // ADC init JTAG command
	assign RSTRT_PIPE          = f[15];  // Restart pipeline JTAG command
	assign BPI_RESET           = f[25];  // Reset BPI interface JTAG command
	assign BPI_DISABLE         = f[26];  // Disable BPI processing
	assign BPI_ENABLE          = f[27];  // Enable BPI processing
	assign JTAG_RST_SEM_CNTRS  = f[38];  // reset ECC error counters
	assign SAMP_CLK_PHS_CHNG   = f[44] & update2;  // Initiate a deserializer reset at end of changing sampling clock phase change.
	assign JDAQ_INJ_ERR        = f[46];  // JTAG request for error injection in PRBS test
	assign JTAG_TK_CTRL        = f[47];  // Take control of the SEM command interface (only needs to be set after ChipScope Pro has been in control).
	assign JTAG_DED_RST        = f[48];  // Reset the double error detected flag (SEM module).
	assign CMP_PHS_JTAG_RST    = f[62];  // Comparator Clock Phase Reset 
	assign DAQ_OP_RST          = f[63];  // Reset DAQ optical link by toggling transmit disable
	assign TRG_OP_RST          = f[64];  // Reset TRG optical link by toggling transmit disable
	assign I2C_RESET           = f[80];  // Reset I2C interface JTAG command
	assign I2C_START           = f[81];  // Start I2C processing
	assign p_in = f[1] | f[13] | f[15] | f[25] | f[38] | f[47] | f[48] | f[62] | f[63] | f[64] | f[80];  // JTAG_SYS_RST, ADC_Init, Restart pipeline, BPI_Reset, and SEM JTAG commands are to be auto reset;
	assign clrf = (clr_pip[10] & p_in_s2) || I2C_CLR_START; // auto reset functions last 11 25ns clocks then clear
	
//
//
// JTAG to SPI interface for Comparator DAC, Calibration DAC and MAX 1271 ADC
//
	assign CDAC_ENB = (dshift & jsel2 & f[4]) | al_dac_enb;
	assign CALDAC_ENB = (dshift & jsel2 & f[34]);
	assign CALADC_ENB = (dshift & jsel2 & f[35]);
	assign SPI_CK = (AUTO_LOAD_ENA ? al_cth_shck : tck2) & (CDAC_ENB | CALDAC_ENB | CALADC_ENB);
	assign SPI_DAT = ((AUTO_LOAD_ENA ? al_cth_sdata : tdi2) & (CDAC_ENB | CALDAC_ENB | CALADC_ENB));
	assign al_cth_shck = CLK1MHZ & al_cth_shck_ena;
	assign al_bky_shck = CLK1MHZ & al_bky_shck_ena;
	
	assign al_abort          = AUTO_LOAD & (AL_CNT == 6'h00);
	assign al_cthresh        = AUTO_LOAD & (AL_CNT == 6'h01);
	assign al_cmode          = AUTO_LOAD & (AL_CNT == 6'h02);
	assign al_ctime          = AUTO_LOAD & (AL_CNT == 6'h03);
	assign al_cmp_clk_phase  = AUTO_LOAD & (AL_CNT == 6'h04);
	assign al_samp_clk_phase = AUTO_LOAD & (AL_CNT == 6'h05);
	assign al_nsamp          = AUTO_LOAD & (AL_CNT == 6'h06);
	assign al_pdepth         = AUTO_LOAD & (AL_CNT == 6'h07);
	assign al_bky_shift      = AUTO_LOAD & ((AL_CNT >= 6'h10) && (AL_CNT <= 6'h21));
	
 /////////////////////////////////////////////////////////////////////////////
 //                                                                         //
 //  JTAG Access Ports for user function in the fabric (up to 4 interfaces) //
 //                                                                         //
 /////////////////////////////////////////////////////////////////////////////
 
 
   BSCAN_VIRTEX6 #(.DISABLE_JTAG("FALSE"),.JTAG_CHAIN(1))  // User 1 for instruction decodes
   BSCAN_user1 (
      .CAPTURE(capture1), // 1-bit output CAPTURE output from TAP controller
      .DRCK(drck1),       // 1-bit output Data register output for USER functions
      .RESET(jreset1),    // 1-bit output Reset output for TAP controller
      .RUNTEST(runtest1), // 1-bit output State output asserted when TAP controller is in Run Test Idle state.
      .SEL(jsel1),        // 1-bit output USER active output
      .SHIFT(jshift1),    // 1-bit output SHIFT output from TAP controller
      .TCK(tck1),         // 1-bit output Scan Clock output. Fabric connection to TAP Clock pin.
      .TDI(tdi1),         // 1-bit output TDI output from TAP controller
      .TMS(tms1),         // 1-bit output Test Mode Select input. Fabric connection to TAP.
      .UPDATE(update1),   // 1-bit output UPDATE output from TAP controller
      .TDO(tdo1)          // 1-bit input Data input for USER function
   );
  
   BSCAN_VIRTEX6 #(.DISABLE_JTAG("FALSE"),.JTAG_CHAIN(2))  // User 2 for data I/O
   BSCAN_user2 (
      .CAPTURE(capture2), // 1-bit output CAPTURE output from TAP controller
      .DRCK(drck2),       // 1-bit output Data register output for USER functions
      .RESET(jreset2),    // 1-bit output Reset output for TAP controller
      .RUNTEST(runtest2), // 1-bit output State output asserted when TAP controller is in Run Test Idle state.
      .SEL(jsel2),        // 1-bit output USER active output
      .SHIFT(jshift2),    // 1-bit output SHIFT output from TAP controller
      .TCK(tck2_raw),     // 1-bit output Scan Clock output. Fabric connection to TAP Clock pin.
      .TDI(tdi2),         // 1-bit output TDI output from TAP controller
      .TMS(tms2),         // 1-bit output Test Mode Select input. Fabric connection to TAP.
      .UPDATE(update2),   // 1-bit output UPDATE output from TAP controller
      .TDO(tdo2)          // 1-bit input Data input for USER function
   );

  BUFG tclk2_buf
   (.O   (tck2),
	 .I   (tck2_raw)
	 );

  BUFGMUX mixclk_buf
   (.O   (mixclk),
	 .I0   (tck2_raw),
	 .I1   (CLK40),
	 .S   (AUTO_LOAD_ENA)
	 );



	
	always @(posedge FSTCLK) dshift <= jshift2;  // Shift state delayed by 6.25ns
//
// JTAG Instruction decode Uses User 1 BSCAN signals
//
   instr_dcd
	instr_dcd1(
	   .TCK(tck1),         // TCK for update register
      .DRCK(drck1),       // Data Reg Clock
      .SEL(jsel1),        // User 1 mode active
      .TDI(tdi1),         // Serial Test Data In
      .UPDATE(update1),   // Update state
      .SHIFT(jshift1),    // Shift state
      .RST(not_eos),      // Reset default state
      .CLR(clrf),          // Clear the current function
      .F(f),              // Function decode output (one hot)
      .TDO(tdo1));        // Serial Test Data Out

//
// synchronize some signals to 40 MHz clock
//
   always @(posedge CLK40) begin
	   p_in_s1 <= p_in;
		f18_s1 <= f[18];
		f19_s1 <= f[19];
		f21_up2_s1 <= f[21] & jsel2 & update2;
		f22_up2_s1 <= f[22] & jsel2 & update2;
		f32_s1 <= f[32];
		f33_s1 <= f[33];
		f40_s1 <= f[40];
		f41_s1 <= f[41];
		f42_s1 <= f[42];
		f43_s1 <= f[43];
		f49_up2_s1 <= f[49] & jsel2 & update2;
		f77_up2_s1 <= f[77] & jsel2 & update2;
		f78_up2_s1 <= f[78] & jsel2 & update2;
//
	   p_in_s2 <= p_in_s1;
		f18_s2 <= f18_s1;
		f19_s2 <= f19_s1;
		f21_up2_s2 <= f21_up2_s1;
		f22_up2_s2 <= f22_up2_s1;
		f32_s2 <= f32_s1;
		f33_s2 <= f33_s1;
		f40_s2 <= f40_s1;
		f41_s2 <= f41_s1;
		f42_s2 <= f42_s1;
		f43_s2 <= f43_s1;
		f49_up2_s2 <= f49_up2_s1;
		f77_up2_s2 <= f77_up2_s1;
		f78_up2_s2 <= f78_up2_s1;
	end
		
//
// pipline to set length of auto reset signals
//
   always @(posedge CLK40) begin
	    clr_pip <= {clr_pip[10:0],p_in_s2};
	end
  
//
// JTAG User Functions  Uses User 2 BSCAN signals
//
//
// JTAG Extra L1A Delay Register
//		for compatibility with old DMBs only
   user_wr_reg #(.width(2), .def_value(2'b01), .TMR(TMR))
   load_xl1dly(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[5]),        // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(tdi2),       // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(f[7]),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(2'b01),         // Parallel input
      .PO(XL1DLYSET),     // Parallel output
      .TDO(tdof5),        // Serial Test Data Out
      .DSY_OUT(lxdlyout));// Daisy chained serial data out

//
// JTAG Pre block end register  (Not needed in DCFEB -- should remove but it is part of daisy chain for F7)
//		for compatibility with old DMBs only
  user_wr_reg #(.width(4), .def_value(4'h9), .TMR(TMR))
   load_preblk(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[8]),        // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),         // Serial Test Data In
      .DSY_IN(lxdlyout),  // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(f[7]),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(4'h9),          // Parallel input
      .PO(LOADPBLK),      // Parallel output
      .TDO(tdof8),        // Serial Test Data Out
      .DSY_OUT(prbout));  // Daisy chained serial data out
//
// JTAG Comparator Mode and Timing bits Register
//

always @(posedge CLK40 or posedge RST) begin
	if(RST)
		AL_DONE <= 0;
	else
		if(CLR_AL_DONE)
			AL_DONE <= 0;
		else if(al_abort)
			AL_DONE <= (BPI_AL_REG != 16'h4321);
		else if(al_cthresh_done && al_bshift_done)
			AL_DONE <= 1;
		else
			AL_DONE <= AL_DONE;
end

	al_cdac #(
		.TMR(TMR)
	)
	al_cdac_i (
		.CLK40(CLK40),
		.CLK1MHZ(CLK1MHZ),
		.RST(RST),
		.CLR_AL_DONE(CLR_AL_DONE),
		.CAPTURE(al_cthresh),
		.BPI_AL_REG(BPI_AL_REG[11:0]),
		.SHCK_ENA(al_cth_shck_ena),
		.SDATA(al_cth_sdata),
		.DAC_ENB(al_dac_enb),
		.CDAC_DONE(al_cthresh_done)
//		.al_cdac_dbg(al_cdac_dbg)  // composite signals for logic analyzer
	);

always @(posedge CLK40 or posedge RST) begin
	if(RST)
		cmode_hold <= 2'b00;
	else
		if(al_cmode)
			cmode_hold <= BPI_AL_REG[1:0];
		else
			cmode_hold <= cmode_hold;
end

   user_wr_reg #(.width(5), .def_value(5'b01010), .TMR(TMR))
   comparator(
	   .TCK(mixclk),         // TCK for update register
      .DRCK(mixclk),        // Data Reg Clock
      .FSEL(f[9]),        // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),         // Serial Test Data In
      .DSY_IN(prbout),    // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(f[7]),   // Daisy chain mode
		.LOAD(al_ctime),   // Load parallel input
		.PI({BPI_AL_REG[2:0],cmode_hold}),          // Parallel input
      .PO({COMP_TIME,COMP_MODE}), // Parallel output
      .TDO(tdof9),        // Serial Test Data Out
      .DSY_OUT(dsy7));    // Daisy chained serial data out
		
//
// Calibration mode
//
   always @(posedge CLK40) begin
		 f18dly <= f18_s2;
		 f19dly <= f19_s2;
		 clr_cal_mode <= f18_s2 & ~f18dly;  // leading edge of function being set (after update1)
		 set_cal_mode <= f19_s2 & ~f19dly;  // leading edge of function being set (after update1)
		 if(clr_cal_mode || RST)
			CAL_MODE <= 1'b0;
		 else if(set_cal_mode)
			CAL_MODE <= 1'b1;
		 else
			CAL_MODE <= CAL_MODE;
	end
		
//
// L1A_MATCH source flag
//
   always @(posedge CLK40) begin
		 f40dly <= f40_s2;
		 f41dly <= f41_s2;
		 clr_use_any_l1a <= f40_s2 & ~f40dly;  // leading edge of function being set (after update1)
		 set_use_any_l1a <= f41_s2 & ~f41dly;  // leading edge of function being set (after update1)
		 if(clr_use_any_l1a || RST)
			USE_ANY_L1A <= 1'b0;
		 else if(set_use_any_l1a)
			USE_ANY_L1A <= 1'b1;
		 else
			USE_ANY_L1A <= USE_ANY_L1A;
	end
		
//
// L1A_HEAD flag; controls use of l1anum as the header in the data stream
//
   always @(posedge CLK40) begin
		 f42dly <= f42_s2;
		 f43dly <= f43_s2;
		 clr_l1a_head <= f42_s2 & ~f42dly;  // leading edge of function being set (after update1)
		 set_l1a_head <= f43_s2 & ~f43dly;  // leading edge of function being set (after update1)
		 if(set_l1a_head || RST)
			L1A_HEAD <= 1'b1;
		 else if(clr_l1a_head)
			L1A_HEAD <= 1'b0;
		 else
			L1A_HEAD <= L1A_HEAD;
	end
	
//
// JTAG Buckeye mask register for which amplifiers are in the shift loop.
//
	
   user_wr_reg #(.width(6), .def_value(6'b111111), .TMR(TMR))
   buckeye_mask(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[10]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),         // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(6'b111111),          // Parallel input
      .PO(bky_mask),      // Parallel output
      .TDO(tdofa),        // Serial Test Data Out
      .DSY_OUT(dmy2));    // Daisy chained serial data out

//
// JTAG Buckeye shift clocks data mutiplexers
//
   bky_shift 
	bky_shift1 (
		.DRCK(tck2),        // Data Reg Clock
		.CLK1MHZ(CLK1MHZ),  // 1MHz clock for auto loading
		.SEL(jsel2),         // User 2 mode active
		.F(f[11]),          // Function select
		.TDI(tdi2),         // Serial Test Data In
		.MASK(bky_mask),    // Mask of which amplifiers to include in shift loop
		.SHIFT(dshift),     // Shift state
		.AL_BKY_ENA(al_bky_ena), // Autoload process active
		.AL_SHCK_ENA(al_bky_shck_ena), // Autoload shift clock
		.AL_SDATA(al_bky_sdata), // Autoload serial data
		.DRTN(BKY_RTN),     // Serial data returned from amplifiers
		.DSND(TO_BKY),      // Serial data sent to amplifiers
		.BCLK(BKY_CLK),     // Shift clock for amplifiers
		.TDO(tdofb)        // Test data out of the complete loop
		);
		
	al_buckeye_load #(
		.TMR(TMR)
	)
	al_buckeye_load_i(
		.CLK40(CLK40),
		.CLK1MHZ(CLK1MHZ),
		.RST(RST),
		.SLOW_FIFO_RST(SLOW_FIFO_RST),
		.CLR_AL_DONE(CLR_AL_DONE),
		.CAPTURE(al_bky_shift),
		.BPI_AL_REG(BPI_AL_REG),
		.AL_BKY_ENA(al_bky_ena),
		.SHCK_ENA(al_bky_shck_ena),
		.SDATA(al_bky_sdata),
		.AL_DONE(al_bshift_done)
	);
	
//
// Status capture and shift
//
   user_cap_reg #(.width(32))
   status1(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(f[2]),         // Shift Function
      .FCAP(f[3]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),       // Reset default state
		.BUS({status_h,DCFEB_STATUS}), // Bus to capture
      .TDO(tdof2a3));      // Serial Test Data Out

//
// ADC Mask register
//
   user_wr_reg #(.width(12), .def_value(12'hFFF), .TMR(TMR))
   adc_mask1(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[12]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(12'hFFF),          // Parallel input
      .PO(ADC_MASK),      // Parallel output
      .TDO(tdofc),        // Serial Test Data Out
      .DSY_OUT(dmy3));    // Daisy chained serial data out

//
// ADC Memory word register (data to write to ADC configuration memory)
//
   user_wr_reg #(.width(26), .def_value(26'h0000000), .TMR(TMR))
   adc_mem1(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[14]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(26'h0000000),          // Parallel input
      .PO(ADC_MEM),       // Parallel output
      .TDO(tdofe),        // Serial Test Data Out
      .DSY_OUT(dmy4));    // Daisy chained serial data out
		
//
// Pipeline Depth register
//
   user_wr_reg #(.width(9), .def_value(9'd100), .TMR(TMR))
   pipe_depth1(
	   .TCK(mixclk),         // TCK for update register
      .DRCK(mixclk),        // Data Reg Clock
      .FSEL(f[16]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(al_pdepth),   // Load parallel input
		.PI(BPI_AL_REG[8:0]),          // Parallel input
      .PO(PDEPTH),        // Parallel output
      .TDO(tdof10),        // Serial Test Data Out
      .DSY_OUT(dmy5));    // Daisy chained serial data out
		
		
//
// TTC source register
//
//  FF_EMU_mode    = 2'b00, 
//  FF_EEM_mode    = 2'b01, 
//  Skew_Clr_mode  = 2'b10;

   user_wr_reg #(.width(2), .def_value(2'b10), .TMR(TMR)) // default is Skewclear mode
   ttc_src1(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[17]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(2'b10),          // Parallel input
      .PO(TTC_SRC),        // Parallel output
      .TDO(tdof11),        // Serial Test Data Out
      .DSY_OUT(dmy6));    // Daisy chained serial data out
		
		
		
//
// ADC Write enable for configuration memory
//
   always @(posedge CLK20) begin
		 pre_we <= f[14] & jsel2 & update2;              // only at update2
		 we     <= ~(f[14] & jsel2 & update2) & pre_we;  // generate trailing edge pulse one clock long
		 ADC_WE <= we;                                 // delay write enable one clock cycle
	end

//
// ADC Data readback  capture and shift
//
   user_cap_reg #(.width(192))
   ADCread1(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[6]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),          // Reset default state
		.BUS(ADCDATA), // Bus to capture
      .TDO(tdof6));      // Serial Test Data Out
	
//
// Read enable for ADC data FIFO -- advance on each JTAG read.
//
   always @(posedge CLK120) begin
		 pre_rd <= f[6] & jsel2 & update2;              // only at update2
		 RDFIFO <= (f[6] & jsel2 & update2) & ~pre_rd;  // generate leading edge pulse one clock long
	end
	
//
// Number of samples to read register
//
   user_wr_reg #(.width(7), .def_value(7'd8), .TMR(TMR))
   nsamples1(
	   .TCK(mixclk),         // TCK for update register
      .DRCK(mixclk),        // Data Reg Clock
      .FSEL(f[20]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(al_nsamp),   // Load parallel input
		.PI(BPI_AL_REG[6:0]),          // Parallel input
      .PO(nsamp),        // Parallel output
      .TDO(tdof14),        // Serial Test Data Out
      .DSY_OUT(dmy7));    // Daisy chained serial data out

//
// BPI interface FIFO word (16 bit word to be writting into the FIFO)
// The write enable for the FIFO is generated automatically
//
   user_wr_reg #(.width(16), .def_value(16'h0000), .TMR(TMR))
   BPI_wrt_FIFO_Jreg(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[21]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(16'h0000),          // Parallel input
      .PO(BPI_CMD_FIFO_DATA),       // Parallel output
      .TDO(tdof15),        // Serial Test Data Out
      .DSY_OUT(dmy8));    // Daisy chained serial data out
		
//
// BPI  Write enable for BPI write FIFO
//
   always @(posedge CLK40) begin
		 pre_we21 <= f21_up2_s2;              // only at update2
		 we21     <= ~f21_up2_s2 & pre_we21;  // generate tailing edge pulse one clock long
		 BPI_WE <= we21;                      // delay write enable one clock cycle
	end

//
// BPI Data readback  capture and shift from BPI_RBK_FIFO_DATA
//
   user_cap_reg #(.width(16))
   BPI_rbk_FIFO_Jreg(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[22]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),          // Reset default state
		.BUS(BPI_RBK_FIFO_DATA), // Bus to capture
      .TDO(tdof16));      // Serial Test Data Out
	
//
// Read enable for BPI data FIFO -- advance on each JTAG read.
//
   always @(posedge CLK40) begin
		 pre_rd22 <= f22_up2_s2;              // only at update2
		 BPI_RDENA <= f22_up2_s2 & ~pre_rd22;  // generate leading edge pulse one clock long
	end
		
//
// BPI status register capture and shift
//
   user_cap_reg #(.width(16))
   BPI_status_Jreg(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[23]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),          // Reset default state
		.BUS(BPI_STATUS), // Bus to capture
      .TDO(tdof17));      // Serial Test Data Out
		
		
//
// BPI timer register capture and shift
//
   user_cap_reg #(.width(32))
   BPI_timer_Jreg(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[24]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),          // Reset default state
		.BUS(BPI_TIMER), // Bus to capture
      .TDO(tdof18));      // Serial Test Data Out

//
// Comparator Clock phase register
//

   user_wr_reg #(.width(5), .def_value(5'd0), .TMR(TMR)) // default is no phase shift
   cmp_clock_phase(
	   .TCK(mixclk),         // TCK for update register
      .DRCK(mixclk),        // Data Reg Clock
      .FSEL(f[28]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(al_cmp_clk_phase),   // Load parallel input
		.PI(BPI_AL_REG[4:0]),          // Parallel input
      .PO(CMP_CLK_PHASE),        // Parallel output
      .TDO(tdof1c),        // Serial Test Data Out
      .DSY_OUT(dmy9));    // Daisy chained serial data out
		
//
// Sampling Clock phase register
//
   user_wr_reg #(.width(3), .def_value(3'd0), .TMR(TMR)) // default is no phase shift
   samp_clock_phase(
	   .TCK(mixclk),         // TCK for update register
      .DRCK(mixclk),        // Data Reg Clock
      .FSEL(f[44]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(al_samp_clk_phase),   // Load parallel input
		.PI(BPI_AL_REG[2:0]),          // Parallel input
      .PO(SAMP_CLK_PHASE),  // Parallel output
      .TDO(tdof2c),        // Serial Test Data Out
      .DSY_OUT(dmy13));    // Daisy chained serial data out
		

//
// TMB optical path transmit mode register
// mode: function
// -----------------
// 0: comapator data
// 1: fixed patterns
// 2: counters
// 3: randoms
// 4: comapator data
// 5: half strips
//

   user_wr_reg #(.width(3), .def_value(3'b000), .TMR(TMR)) // default is comparator data
   tmb_tx_mode(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[29]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(3'b000),          // Parallel input
      .PO(TMB_TX_MODE),    // Parallel output
      .TDO(tdof1d),        // Serial Test Data Out
      .DSY_OUT(dmy10));    // Daisy chained serial data out
		
//
// TMB half strip settings for injecting patterns into serial data stream
// 

   user_wr_reg #(.width(30), .def_value(30'h00000000), .TMR(TMR)) // default is no half strips
   tmb_half_strip(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[30]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(30'h00000000),          // Parallel input
      .PO(LAY1_TO_6_HALF_STRIP),    // Parallel output
      .TDO(tdof1e),        // Serial Test Data Out
      .DSY_OUT(dmy11));    // Daisy chained serial data out
		
		
//
// TMB layer mask for indicating active layers for injecting patterns into serial data stream
// 

   user_wr_reg #(.width(6), .def_value(6'b111111), .TMR(TMR)) // default is all layers active
   tmb_layer_mask(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[31]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(6'b111111),          // Parallel input
      .PO(LAYER_MASK),    // Parallel output
      .TDO(tdof1f),        // Serial Test Data Out
      .DSY_OUT(dmy12));    // Daisy chained serial data out
		
//
// DAQ rate selection
//
   always @(posedge CLK40) begin
		 f32dly <= f32_s2;
		 f33dly <= f33_s2;
		 set_rate_1_25 <= f32_s2 & ~f32dly;  // leading edge of function being set (after update1)
		 set_rate_3_2  <= f33_s2 & ~f33dly;  // leading edge of function being set (after update1)
		 if(set_rate_1_25)
			JDAQ_RATE <= 1'b0;
		 else if(set_rate_3_2 || RST)
			JDAQ_RATE <= 1'b1;
		 else
			JDAQ_RATE <= JDAQ_RATE;
	end
	
//
// SPI Return data register
//
  
  always @(posedge tck2 or posedge RST) begin // intermediate shift register
    if(RST)
	   spi_rtn_reg <= 16'h0000;           // default
    else
	   if(dshift & jsel2 & f[35])
	     spi_rtn_reg <= {spi_rtn_reg[14:0],SPI_RTN}; // Shift left
		else
		  spi_rtn_reg <= spi_rtn_reg;                  // Hold
  end
//
// SPI Return data register capture and shift
//
   user_cap_reg #(.width(16))
   SPI_Rtn_Reg(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[36]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),          // Reset default state
		.BUS(spi_rtn_reg), // Bus to capture
      .TDO(tdof24));      // Serial Test Data Out


//
// Function 37:
//
// SEM Status capture and shift

//	[0] = status_initialization;
//	[1] = status_observation;
//	[2] = status_correction;
//	[3] = status_classification;
//	[4] = status_injection;
//	[5] = status_essential;
//	[6] = status_uncorrectable;
//	[7] = 1'b0;
//	[8] = CRC error;
//	[9] = double error detected;

   user_cap_reg #(.width(10))
   SEM_Status_Reg(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[37]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),          // Reset default state
		.BUS(SEM_STATUS[9:0]), // Bus to capture //  bit 9 is double error detected, bit 8 is crc error
      .TDO(tdof25));      // Serial Test Data Out

//
// Function 39:
//
// ECC Error counters capture and shift
// 16 bit word
//	[15:8] = multi_bit_err_cnt;
//	[7:0]  = sngl_bit_err_cnt;

   user_cap_reg #(.width(16))
   ECC_Error_Counts(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[39]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),          // Reset default state
		.BUS(SEM_ERRCNT), // Bus to capture //[bits 15:8 are multi-bit error counts, bits 7:0 are single-bit error counts
      .TDO(tdof27));      // Serial Test Data Out
		
//
// PRBS testing mode for DAQ optical path
//      Modes are 
//      000: Standard operation
//      001: PRBS-7
//      010: PRBS-15
//      011: PRBS-23
//      100: PRBS-31
//      101: PCI Express pattern
//      110: Square wave with 2 UI
//      111: Square wave with 16 UI (or 20 UI)

   user_wr_reg #(.width(3), .def_value(3'b000), .TMR(TMR)) // default is normal mode, no PRBS testing
   PRBS_tst_mode(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[45]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(3'b000),          // Parallel input
      .PO(JDAQ_PRBS_TST),    // Parallel output
      .TDO(tdof2d),        // Serial Test Data Out
      .DSY_OUT(dmy14));    // Daisy chained serial data out
		
//
// Function 49:
//
// SEM command interface data word
//       8 bit word to be written to the SEM controller (ASCII commands)
// The write enable for the SEM controller is generated automatically
//
// Valid commands are:
// Char  ASCII     Function
//-----------------------------------
// 'I'   0x49    Go to Idle state
// 'O'   0x4F    Go to Observation state
// 'S'   0x53    Request status
// 'N {9digit hex}'   0x4E,0x20,0x43,0x30... 
//       Error injection request (followed by a space and 9 digit location)
// ' '   0x20    Space
// <cr>  0x0D    carraige return
// '0'   0x30
// '1'   0x31
//  .
//  .
// '9'   0x39
//
// Injection address format for linear addresses:
// bit 35                                          0
//      1100_000L_LLLL_LLLL_LLLL_LLLL_WWWW_WWWB_BBBB
// where:
//        LLLLLLLLLLLLLLLLL = linera frame address 17-bits
//                  WWWWWWW = word address 7-bits
//                    BBBBB = bit address b-bits
//
// Injection address format for physical addresses:
// bit 35                                          0
//      0TTH_RRRR_RCCC_CCCC_CMMM_MMMM_WWWW_WWWB_BBBB
// where:
//                       TT = block type 2-bits
//                        H = half address 1-bits
//                    RRRRR = row address 5-bits
//                 CCCCCCCC = column address 8-bits
//                  MMMMMMM = minor address 7-bits
//                  WWWWWWW = word address 7-bits
//                    BBBBB = bit address b-bits
//
   user_wr_reg #(.width(8), .def_value(8'h00), .TMR(TMR))
   SEM_cmd_data_reg(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[49]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(8'h00),          // Parallel input
      .PO(JTAG_CMD_DATA),       // Parallel output
      .TDO(tdof31),        // Serial Test Data Out
      .DSY_OUT(dmy15));    // Daisy chained serial data out
		
//
// BPI  Write enable for BPI write FIFO
//
   always @(posedge CLK40) begin
		 pre_we49 <= f49_up2_s2;              // only at update2
		 we49     <= ~f49_up2_s2 & pre_we49;  // generate tailing edge pulse one clock long
		 JTAG_SEND_CMD <= we49;                                 // delay write enable one clock cycle
	end

//
// Function 50:
//
// SEM Frame Address Register (FAR) Linear address format capture and shift

   user_cap_reg #(.width(24))
   Frame_ECC_LA_Reg(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[50]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),          // Reset default state
		.BUS(SEM_FAR_LA),   // Bus to capture // 
      .TDO(tdof32));      // Serial Test Data Out
//
// Function 51:
//
// SEM Frame Address Register (FAR) Physical address format capture and shift

   user_cap_reg #(.width(24))
   Frame_ECC_PA_Reg(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[51]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),          // Reset default state
		.BUS(SEM_FAR_PA),   // Bus to capture // 
      .TDO(tdof33));      // Serial Test Data Out
		
//
// Function 52:
//
// Register Selection Word
//       8 bit word specifying which register to be read back independently
//
// RegSel  Register                  Bits
//------------------------------------------
//   0     Xtra L1a                  2 bits
//   1     Pre Block End             4 bits
//   2     CmpTim[2:0],CompMode[1:0] 5 bits
//   3     Buckeye Mask              6 bits
//   4     ADC Maslk                12 bits
//   5     ADC Cnfg Mem Wrd         26 bits
//   6     Pipeline Depth            9 bits
//   7     TTC Source                2 bits
//   8     # Samples                 7 bits
//   9     BPI Write FIFO           16 bits
//  10     Comp Clock Phase          4 bits
//  11     Sampling Clock Phase      3 bits
//  12     TMB Transmit Mode         3 bits
//  13     HS Settings              30 bits
//  14     TMB Layer Mask            6 bits
//  15     PRBS Test Mode            3 bits
//  16     SEM Command               8 bits
//  17     Registrer Sel Word        8 bits
//  18     Comp phase TMR err cnt   16 bits
//  19     fifo load TMR err cnt    16 bits
//  20     xfer2ringbuf TMR err cnt 16 bits
//  21     ring trans TMR err cnt   16 bits
//  22     sample proc TMR err cnt  16 bits
//  23     frame proc TMR err cnt   16 bits
//
 
   user_wr_reg #(.width(8), .def_value(8'h00), .TMR(TMR))
   Reg_Sel_Wrd_reg(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[52]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(8'h00),          // Parallel input
      .PO(reg_sel_wrd),       // Parallel output
      .TDO(tdof34),        // Serial Test Data Out
      .DSY_OUT(dmy16));    // Daisy chained serial data out


//
// Function 53:
//
// Select Readback Register.
//       16 bit word
//       Registers with more than 16 bits are truncated.
//
   user_cap_reg #(.width(16))
   Select_Readback_Reg(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[53]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),          // Reset default state
		.BUS(sel_reg),   // Bus to capture // 
      .TDO(tdof35));      // Serial Test Data Out

always @*
begin
	case (reg_sel_wrd)
		8'd0 : sel_reg = {14'h0000,XL1DLYSET};
		8'd1 : sel_reg = {12'h000,LOADPBLK};
		8'd2 : sel_reg = {11'h000,COMP_TIME,COMP_MODE};
		8'd3 : sel_reg = {10'h000,bky_mask};
		8'd4 : sel_reg = {4'h0,ADC_MASK};
		8'd5 : sel_reg = ADC_MEM[15:0];
		8'd6 : sel_reg = {7'h00,PDEPTH};
		8'd7 : sel_reg = {14'h0000,TTC_SRC};
		8'd8 : sel_reg = {9'h000,nsamp};
		8'd9 : sel_reg = BPI_CMD_FIFO_DATA;
		8'd10 : sel_reg = {11'h000,CMP_CLK_PHASE};
		8'd11 : sel_reg = {13'h0000,SAMP_CLK_PHASE};
		8'd12 : sel_reg = {13'h0000,TMB_TX_MODE};
		8'd13 : sel_reg = LAY1_TO_6_HALF_STRIP[15:0];
		8'd14 : sel_reg = {10'h000,LAYER_MASK};
		8'd15 : sel_reg = {13'h0000,JDAQ_PRBS_TST};
		8'd16 : sel_reg = {8'h00,JTAG_CMD_DATA};
		8'd17 : sel_reg = {8'h00,reg_sel_wrd};
		8'd18 : sel_reg = CMP_PHS_ERRCNT;
		8'd19 : sel_reg = FIFO_LOAD_ERRCNT;
		8'd20 : sel_reg = XF2RB_ERRCNT;
		8'd21 : sel_reg = RGTRNS_ERRCNT;
		8'd22 : sel_reg = SMPPRC_ERRCNT;
		8'd23 : sel_reg = FRMPRC_ERRCNT;
		default :  sel_reg = {8'h00,reg_sel_wrd};
	endcase
end		
	
//
// Function 55:
//
//
// QPLL Lock Lost Counter
//
   user_cap_reg #(.width(8))
   QPLL_LLC1(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[55]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),       // Reset default state
		.BUS(QPLL_CNT),      // Bus to capture
      .TDO(tdof37));       // Serial Test Data Out
//
// Function 56:
//
// Startup Status Word
//       {qpll_lock,qpll_error,qpll_cnt_ovrflw,1'b0,trg_mmcm_lock,daq_mmcm_lock,adc_rdy,run,al_status[2:0],eos,por_state[3:0]};
//
//
   user_cap_reg #(.width(16))
   startup1(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[56]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),       // Reset default state
		.BUS(STARTUP_STATUS), // Bus to capture
      .TDO(tdof38));       // Serial Test Data Out

//
// Function 57:
//
// Read L1A counter (24 bits)
//
//
   user_cap_reg #(.width(24))
   L1A_counter(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[57]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),       // Reset default state
		.BUS(L1ACNT),        // Bus to capture
      .TDO(tdof39));       // Serial Test Data Out

//
// Function 58:
//
// Read L1A_MATCH counter (12 bits)
//
//
   user_cap_reg #(.width(12))
   L1A_match_counter(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[58]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),       // Reset default state
		.BUS(L1AMCNT),        // Bus to capture
      .TDO(tdof3a));       // Serial Test Data Out

//
// Function 59:
//
// Read INJPLS counter (12 bits)
//
//
   user_cap_reg #(.width(12))
   Inj_pulse_counter(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[59]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),       // Reset default state
		.BUS(INJPLSCNT),     // Bus to capture
      .TDO(tdof3b));       // Serial Test Data Out

//
// Function 60:
//
// Read EXTPLS counter (12 bits)
//
//
   user_cap_reg #(.width(12))
   Ext_pulse_counter(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[60]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),       // Reset default state
		.BUS(EXTPLSCNT),     // Bus to capture
      .TDO(tdof3c));       // Serial Test Data Out

//
// Function 61:
//
// Read BC0 counter (12 bits)
//
//
   user_cap_reg #(.width(12))
   BC0_counter(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[61]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),       // Reset default state
		.BUS(BC0CNT),        // Bus to capture
      .TDO(tdof3d));       // Serial Test Data Out


//  77     | Write Byte to I2C write FIFO (8 bits).
//  78     | Read Byte from I2C readback FIFO (8 bits).
//  79     | Read I2C status word from I2C interface (8 bits).
//  80     | Reset I2C interface. -- Instruction only, (Auto reset)
//  81     | Start I2C processing. -- Instruction only, persisting until new command or processing completed
//
// Function 77:
//
//
// I2C interface FIFO Byte (8 bit word to be writting into the FIFO)
// The write enable for the FIFO is generated automatically
//
   user_wr_reg #(.width(8), .def_value(8'h00), .TMR(TMR))
   I2C_wrt_FIFO_Jreg(
	   .TCK(tck2),         // TCK for update register
      .DRCK(tck2),        // Data Reg Clock
      .FSEL(f[77]),       // Function select
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .DSY_IN(1'b0),      // Serial Daisy chained data in
      .SHIFT(jshift2),      // Shift state
      .UPDATE(update2),    // Update state
      .RST(not_eos),          // Reset default state
      .DSY_CHAIN(1'b0),   // Daisy chain mode
		.LOAD(1'b0),        // Load parallel input
		.PI(8'h00),          // Parallel input
      .PO(I2C_WRT_FIFO_DATA),       // Parallel output
      .TDO(tdof4d),        // Serial Test Data Out
      .DSY_OUT(dmy8));    // Daisy chained serial data out

//
// I2C Write enable for I2C write FIFO
//
   always @(posedge CLK40) begin
		 pre_we77 <= f77_up2_s2;              // only at update2
		 we77     <= ~f77_up2_s2 & pre_we77;  // generate tailing edge pulse one clock long
		 I2C_WE <= we77;                      // delay write enable one clock cycle
	end

//
// Function 78:
//
//
// I2C Data readback  capture and shift from I2C_RBK_FIFO_DATA
//
   user_cap_reg #(.width(8))
   I2C_rbk_FIFO_Jreg(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[78]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),          // Reset default state
		.BUS(I2C_RBK_FIFO_DATA), // Bus to capture
      .TDO(tdof4e));      // Serial Test Data Out
	
//
// Read enable for I2C readback data FIFO -- advance on each JTAG read.
//
   always @(posedge CLK40) begin
		 pre_rd78 <= f78_up2_s2;               // only at update2
		 I2C_RDENA <= f78_up2_s2 & ~pre_rd78;  // generate leading edge pulse one clock long
	end
		
//
// Function 79:
//
//
// I2C status register capture and shift
//
   user_cap_reg #(.width(8))
   I2C_status_Jreg(
      .DRCK(tck2),        // Data Reg Clock
      .FSH(1'b0),         // Shift Function
      .FCAP(f[79]),        // Capture Function
      .SEL(jsel2),        // User 2 mode active
      .TDI(tdi2),          // Serial Test Data In
      .SHIFT(jshift2),      // Shift state
      .CAPTURE(capture2),  // Capture state
      .RST(not_eos),          // Reset default state
		.BUS(I2C_STATUS), // Bus to capture
      .TDO(tdof4f));      // Serial Test Data Out
		


endmodule
