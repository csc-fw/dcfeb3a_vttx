`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:58:40 10/30/2017 
// Design Name: 
// Module Name:    I2C_interfaces 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module I2C_interfaces #(
	parameter Simulation = 0,
	parameter USE_CHIPSCOPE = 0
)(
	input	CLK40,
	input	CLK1MHZ,
	input	RST,
	
	inout DAQ_LDSDA,
//	input DAQ_LDSDA_RTN,
	
	inout TRG_LDSDA,
//	input TRG_LDSDA_RTN,
	output COM_LDSCL,
	
	// JTAG signals
	input [7:0] I2C_WRT_FIFO_DATA,  // Data word for I2C write FIFO
	input I2C_WE,               // Write enable for I2C Write FIFO
	input I2C_RDENA,            // Read enable for I2C Readback FIFO
	input I2C_RESET,                // Reset I2C FIFO
	input I2C_START,                // Start I2C processing
	input I2C_TEST_ENA_B,           // Start Automated I2C testing

	output [7:0] I2C_RBK_FIFO_DATA, // Data read back from I2C device
	output I2C_CLR_START,           // Clear the I2C_START instruction
	output [7:0] I2C_STATUS,         // STATUS word for I2C interface
	output SCOPE_SYNC,
	output DAQ_TST_INPRGS,
	output reg DAQ_NACK_ERRS,
	output  DAQ_NACK_FLG,
	output reg DAQ_ERR_FLG,
	output reg [3:0] DAQ_ERR_REG,
	output TRG_TST_INPRGS,
	output reg TRG_NACK_ERRS,
	output  TRG_NACK_FLG,
	output reg TRG_ERR_FLG,
	output reg [3:0] TRG_ERR_REG
	
);

wire daq_ldsda_dir;
wire daq_ldsda_in;
wire daq_ldsda_rtn;
wire daq_ldsda_out;
wire daq_ldscl_out;

wire trg_ldsda_dir;
wire trg_ldsda_in;
wire trg_ldsda_rtn;
wire trg_ldsda_out;
wire trg_ldscl_out;

wire nvio_i2c_enb; //output of parser state machine but not used in dcfeb_vttx
wire com_ldscl_out;

//wire trg_tristate_sda;
//wire daq_tristate_sda;

wire rst_fifo;
wire wrt_full;
wire wrt_empty;
wire rd_full;
wire rd_empty;
wire read_ff;
wire load_dev;
wire load_n_byte;
wire load_addr;
wire wrt_ena;
wire [7:0] ff_dout;
wire [7:0] gen_data;
reg [3:0] n_bytes;
reg I2C_read;
wire execute;
reg [3:0] wrt_addr;
wire clr_wrt_addr;

wire [3:0] I2C_parser_state;

wire rbk_we;
wire daq_rbk_we;
wire trg_rbk_we;
wire nvio_rbk_we;

wire [7:0] rbk_data;
wire [7:0] daq_rbk_data;
wire [7:0] trg_rbk_data;

wire gbl_ready;
wire daq_ready;
wire trg_ready;
wire daq_s_nack;
wire trg_s_nack;

reg  trg_sel;
reg  daq_sel;


// signal for I2C auto testing

reg [4:0] rom_addr;
reg [7:0] tdata;
wire test_mode;
wire use_test_data;
wire rst_rom_addr;
wire inc_rom_addr;
wire clr_addr;
wire start_parser;
wire empty_parser;
wire start_test;
wire update_errors;
wire daq_check;
wire trg_check;
wire daq_check_vld;
wire trg_check_vld;
wire rbk_ff_rd_en;
wire read_rbk_ff;
wire mismatch;
reg daq_error;
reg trg_error;
reg [3:0] daq_err_cnt;
reg [3:0] trg_err_cnt;


assign daq_ldsda_dir = daq_ldsda_out;
//assign daq_ldsda_dir = daq_tristate_sda;

assign trg_ldsda_dir = trg_ldsda_out;
//assign trg_ldsda_dir = trg_tristate_sda;

assign com_ldscl_out = daq_sel ? daq_ldscl_out : (trg_sel ? trg_ldscl_out : 1'b1);


  IOBUF #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) IOBUF_DAQ_LDSDA (.O(daq_ldsda_in),.IO(DAQ_LDSDA),.I(daq_ldsda_out),.T(daq_ldsda_dir));
//  IBUF  #(.IBUF_LOW_PWR("TRUE"),.IOSTANDARD("DEFAULT"))    IBUF_DAQ_LDSDA_RTN (.O(daq_ldsda_rtn),.I(DAQ_LDSDA_RTN));

  IOBUF #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) IOBUF_TRG_LDSDA (.O(trg_ldsda_in),.IO(TRG_LDSDA),.I(trg_ldsda_out),.T(trg_ldsda_dir));
//  IBUF  #(.IBUF_LOW_PWR("TRUE"),.IOSTANDARD("DEFAULT"))    IBUF_TRG_LDSDA_RTN (.O(trg_ldsda_rtn),.I(TRG_LDSDA_RTN));

  OBUFT #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) OBUFT_COM_LDSCL (.O(COM_LDSCL),.I(com_ldscl_out),.T(com_ldscl_out));


assign clr_wrt_addr = RST || load_addr;
assign gbl_ready = (daq_sel || trg_sel) && ((!daq_sel || (daq_sel && daq_ready)) && (!trg_sel || (trg_sel && trg_ready)));
assign rbk_data  =  daq_sel ? daq_rbk_data : (trg_sel ? trg_rbk_data : 8'h00);
assign rbk_we    =  daq_sel ? daq_rbk_we   : (trg_sel ? trg_rbk_we   : 1'b0);

assign rst_fifo = RST || I2C_RESET;

assign I2C_STATUS ={n_bytes[0],I2C_read,wrt_empty,gbl_ready,I2C_parser_state};
//assign I2C_STATUS ={update_errors,inc_rom_addr,start_test,gbl_ready,I2C_parser_state};

generate
if(Simulation==1)
begin : Sim_I2C_FIFOs
	// I2C write FIFO
	reg [4:0] I2C_wrt_waddr;
	reg [4:0] I2C_wrt_raddr;
	reg [7:0] I2C_wrt_fifo [31:0];
	
	always @(posedge CLK40 or posedge rst_fifo) begin
		if(rst_fifo) begin
			I2C_wrt_waddr <= 5'h00;
		end
		else
			if(I2C_WE) begin
				I2C_wrt_waddr <= I2C_wrt_waddr + 1;
			end
	end
	always @(posedge CLK40) begin
		if(I2C_WE) I2C_wrt_fifo[I2C_wrt_waddr] <= I2C_WRT_FIFO_DATA;
	end
	
	always @(posedge CLK40 or posedge rst_fifo) begin
		if(rst_fifo) begin
			I2C_wrt_raddr <= 5'h00;
		end
		else
			if (read_ff) begin
				I2C_wrt_raddr <= I2C_wrt_raddr + 1;
			end
	end
	assign ff_dout = I2C_wrt_fifo[I2C_wrt_raddr];
	assign wrt_full = (I2C_wrt_waddr-I2C_wrt_raddr)==5'h1F;
	assign wrt_empty   = I2C_wrt_waddr==I2C_wrt_raddr;
	
	// I2C readback FIFO
	reg [4:0] I2C_rbk_waddr;
	reg [4:0] I2C_rbk_raddr;
	reg [7:0] I2C_rbk_fifo [31:0];
	
	always @(posedge CLK40 or posedge rst_fifo) begin
		if(rst_fifo) begin
			I2C_rbk_waddr <= 5'h00;
		end
		else
			if(rbk_we) begin
				I2C_rbk_waddr <= I2C_rbk_waddr + 1;
			end
	end
	always @(posedge CLK40) begin
		if(rbk_we) I2C_rbk_fifo[I2C_rbk_waddr] <= rbk_data;
	end
	
	always @(posedge CLK40 or posedge rst_fifo) begin
		if(rst_fifo) begin
			I2C_rbk_raddr <= 5'h00;
		end
		else
			if (rbk_ff_rd_en) begin
				I2C_rbk_raddr <= I2C_rbk_raddr + 1;
			end
	end
	assign I2C_RBK_FIFO_DATA = I2C_rbk_fifo[I2C_rbk_raddr];
	assign rd_full    = (I2C_rbk_waddr-I2C_rbk_raddr)==5'h1F;
	assign rd_empty   = I2C_rbk_waddr==I2C_rbk_raddr;
	
end
else
begin : builtin_I2C_FIFOs

I2C_write_FIFO
I2C_write_FIFO_i (
  .clk(CLK40), // input clk
  .rst(rst_fifo), // input rst
  .din(I2C_WRT_FIFO_DATA), // input [7 : 0] din
  .wr_en(I2C_WE), // input wr_en
  .rd_en(read_ff), // input rd_en
  .dout(ff_dout), // output [7 : 0] dout
  .full(wrt_full), // output full
  .empty(wrt_empty) // output empty
);

I2C_rbk_FIFO
I2C_rbk_FIFO_i (
  .clk(CLK40), // input clk
  .rst(rst_fifo), // input rst
  .din(rbk_data), // input [7 : 0] din
  .wr_en(rbk_we), // input wr_en
  .rd_en(rbk_ff_rd_en), // input rd_en
  .dout(I2C_RBK_FIFO_DATA), // output [7 : 0] dout
  .full(rd_full), // output full
  .empty(rd_empty) // output empty
);
	
end
endgenerate

always @(posedge CLK40 or posedge clr_wrt_addr) begin
	if(clr_wrt_addr) begin
		wrt_addr = 4'h0;
	end
	else begin
	   if(wrt_ena) begin
		   wrt_addr = wrt_addr +1;
		end
	end
end

always @(posedge CLK40 or posedge rst_fifo) begin
	if(rst_fifo) begin
		daq_sel  <= 1'b0;
		trg_sel  <= 1'b0;
	end
	else begin
		if(load_dev) begin
			trg_sel  <= gen_data[2];
			daq_sel  <= gen_data[1];
		end
	end
end

always @(posedge CLK40 or posedge rst_fifo) begin
	if(rst_fifo) begin
		n_bytes <= 4'h0;
		I2C_read <= 1'b0;
	end
	else begin
		if(load_n_byte) begin
			n_bytes <= gen_data[7:4];
			I2C_read <= gen_data[3];
		end
	end
end

I2C_cmd_parser_FSM
I2C_parser_i (
   // outputs
	.CLR_START(I2C_CLR_START),
	.EXECUTE(execute),
	.LD_ADDR(load_addr),
	.LD_DEV(load_dev),
	.LD_N_BYTE(load_n_byte),
	.NVIO_ENA(nvio_i2c_enb),
	.READ_FF(read_ff),
	.WRT_ENA(wrt_ena),
	.I2C_PARSER_STATE(I2C_parser_state),
   // inputs
	.CLK(CLK40),
	.I2C_START(start_parser),
	.MT(empty_parser),
	.N_BYTES(n_bytes),
	.READ(I2C_read),
	.READY(gbl_ready),
	.RST(rst_fifo)
);

//
// TRG laser driver optical transmitter
//

I2C_intrf #(
		.USE_CHIPSCOPE(0),
		.Dev_Addr(8'hFC)
	)		
I2C_TRG_LD_i  (
	//Inputs
	.CLK40(CLK40),
	.CLK1MHZ(CLK1MHZ),
	.RST(rst_fifo),
	.RTN_DATA(trg_ldsda_in),
	.DEV_SEL(trg_sel),
	.LOAD_N_BYTE(load_n_byte),
	.LOAD_ADDR(load_addr),
	.WRT_ADDR(wrt_addr),
	.WRT_DATA(gen_data),
	.WRT_ENA(wrt_ena),
	.EXECUTE(execute),
	//Outputs
	.READY(trg_ready),
	.RBK_WE(trg_rbk_we),
	.S_NACK(trg_s_nack),
	.RBK_DATA(trg_rbk_data),
//	.TRISTATE_SDA(trg_tristate_sda),
	.SCL(trg_ldscl_out),
	.SDA(trg_ldsda_out)
);

//
// DAQ laser driver optical transmitter
//

I2C_intrf #(
		.USE_CHIPSCOPE(0),
		.Dev_Addr(8'hFC)
	)		
I2C_DAQ_LD_i  (
	//Inputs
	.CLK40(CLK40),
	.CLK1MHZ(CLK1MHZ),
	.RST(rst_fifo),
	.RTN_DATA(daq_ldsda_in),
	.DEV_SEL(daq_sel),
	.LOAD_N_BYTE(load_n_byte),
	.LOAD_ADDR(load_addr),
	.WRT_ADDR(wrt_addr),
	.WRT_DATA(gen_data),
	.WRT_ENA(wrt_ena),
	.EXECUTE(execute),
	//Outputs
	.READY(daq_ready),
	.RBK_WE(daq_rbk_we),
	.S_NACK(daq_s_nack),
	.RBK_DATA(daq_rbk_data),
//	.TRISTATE_SDA(daq_tristate_sda),
	.SCL(daq_ldscl_out),
	.SDA(daq_ldsda_out)
);

//
// code for auto testing I2C communications
//

assign test_mode      = ~I2C_TEST_ENA_B;
assign DAQ_TST_INPRGS = use_test_data;
assign TRG_TST_INPRGS = use_test_data;
assign rst_rom_addr   = RST || clr_addr;
assign read_rbk_ff    = inc_rom_addr && (daq_check || trg_check);
assign gen_data       = use_test_data ? tdata : ff_dout;
assign start_parser   = use_test_data ? start_test : I2C_START;
assign empty_parser   = use_test_data ? 1'b0 : wrt_empty;
assign rbk_ff_rd_en   = use_test_data ? read_rbk_ff : I2C_RDENA;
assign daq_check_vld  = inc_rom_addr && daq_check;
assign trg_check_vld  = inc_rom_addr && trg_check;
assign mismatch       = (I2C_RBK_FIFO_DATA != tdata);


always @*
begin: I2C_ROM
   case(rom_addr)
      5'd0: tdata = 8'h72;  // n_bytes 7, write, DAQ
      5'd1: tdata = 8'h00;  // Register address
      5'd2: tdata = 8'h64;  // DAQ data reg 0
      5'd3: tdata = 8'h55;  // DAQ data reg 1
      5'd4: tdata = 8'h33;  // DAQ data reg 2
      5'd5: tdata = 8'hE7;  // DAQ data reg 3
      5'd6: tdata = 8'h1C;  // DAQ data reg 4
      5'd7: tdata = 8'h73;  // DAQ data reg 5
      5'd8: tdata = 8'h02;  // DAQ data reg 6
      5'd9: tdata = 8'h74;  // n_bytes 7, write, TRG
      5'd10: tdata = 8'h00; // Register address
      5'd11: tdata = 8'h93; // TRG data reg 0
      5'd12: tdata = 8'h6B; // TRG data reg 1
      5'd13: tdata = 8'hC6; // TRG data reg 2
      5'd14: tdata = 8'h3D; // TRG data reg 3
      5'd15: tdata = 8'h85; // TRG data reg 4
      5'd16: tdata = 8'hAE; // TRG data reg 5
      5'd17: tdata = 8'h07; // TRG data reg 6
      5'd18: tdata = 8'h7A; // n_bytes 7, read, DAQ
      5'd19: tdata = 8'h00; // Register address
      5'd20: tdata = 8'h7C; // n_bytes 7, read, TRG
      5'd21: tdata = 8'h00; // Register address
      5'd22: tdata = 8'h76; // n_bytes 7, write, DAQ & TRG
      5'd23: tdata = 8'h00; // Register address
      5'd24: tdata = 8'h87; // Default data ror reg 0
      5'd25: tdata = 8'h80; // Default data ror reg 1
      5'd26: tdata = 8'h00; // Default data ror reg 2
      5'd27: tdata = 8'h88; // Default data ror reg 3
      5'd38: tdata = 8'hFF; // Default data ror reg 4
      5'd29: tdata = 8'hFF; // Default data ror reg 5
      5'd30: tdata = 8'h04; // Default data ror reg 6
      default: tdata = 8'h00;
   endcase
end

always @(posedge CLK40 or posedge rst_rom_addr) begin
	if(rst_rom_addr) begin
		rom_addr <= 5'h00;
	end
	else begin
		if(read_ff || inc_rom_addr) begin
			rom_addr <= rom_addr +1;
		end
	end
end


Auto_Test_I2C_FSM 
Auto_Test_I2C_i
(
	// outputs
	.CLR_ADDR(clr_addr),
	.DAQ_CHK(daq_check),
	.INCR(inc_rom_addr),
	.START_TEST(start_test),
	.SYNC(SCOPE_SYNC),
	.TRG_CHK(trg_check),
	.UPDATE(update_errors),
	.USE_TEST_DATA(use_test_data),
	// inputs
	.CLK(CLK40),
	.RST(RST),
	.SEQ_DONE(I2C_CLR_START),
	.TEST_MODE(test_mode)
);

always @(posedge CLK40 or posedge RST) begin
	if(RST) begin
		daq_error   <= 1'b0;
		trg_error   <= 1'b0;
		daq_err_cnt <= 4'h0;
		trg_err_cnt <= 4'h0;
	end
	else begin
		if(start_test) begin
			daq_error   <= 1'b0;
			trg_error   <= 1'b0;
			daq_err_cnt <= 4'h0;
			trg_err_cnt <= 4'h0;
		end
		else begin
			if(daq_check_vld && mismatch) begin
				daq_error <= 1'b1;
				daq_err_cnt <= daq_err_cnt + 1;
			end
			if(trg_check_vld && mismatch) begin
				trg_error <= 1'b1;
				trg_err_cnt <= trg_err_cnt + 1;
			end
		end
	end
end


always @(posedge CLK40 or posedge RST) begin
	if(RST) begin
		DAQ_ERR_FLG <= 1'b0;
		DAQ_ERR_REG <= 4'h0;
		TRG_ERR_FLG <= 1'b0;
		TRG_ERR_REG <= 4'h0;
	end
	else begin
		if(daq_check && update_errors) begin
			DAQ_ERR_FLG <= daq_error;
			DAQ_ERR_REG <= daq_err_cnt;
		end
		if(trg_check && update_errors) begin
			TRG_ERR_FLG <= trg_error;
			TRG_ERR_REG <= trg_err_cnt;
		end
	end
end
always @(posedge CLK40 or posedge RST) begin
	if(RST) begin
		DAQ_NACK_ERRS <= 1'b0;
		TRG_NACK_ERRS <= 1'b0;
	end
	else begin
		if(!use_test_data) begin
			DAQ_NACK_ERRS <= 1'b0;
		end
		else if(daq_s_nack) begin
			DAQ_NACK_ERRS <= 1'b1;
		end
		if(!use_test_data) begin
			TRG_NACK_ERRS <= 1'b0;
		end
		if(trg_s_nack) begin
			TRG_NACK_ERRS <= 1'b1;
		end
	end
end
assign DAQ_NACK_FLG = daq_s_nack;
assign TRG_NACK_FLG = trg_s_nack;

endmodule
