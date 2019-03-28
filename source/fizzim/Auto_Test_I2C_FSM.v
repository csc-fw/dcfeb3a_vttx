
// Created by fizzim_tmr.pl version $Revision: 4.44 on 2019:03:28 at 14:28:10 (www.fizzim.com)

module Auto_Test_I2C_FSM (
  output reg CLR_ADDR,
  output reg DAQ_CHK,
  output reg INCR,
  output reg START_TEST,
  output reg SYNC,
  output reg TRG_CHK,
  output reg UPDATE,
  output reg USE_TEST_DATA,
  input CLK,
  input RST,
  input SEQ_DONE,
  input TEST_MODE 
);

  // state bits
  parameter 
  Idle        = 4'b0000, 
  Chk_Rbk     = 4'b0001, 
  Clr_Addr    = 4'b0010, 
  Inc_Addr    = 4'b0011, 
  Inc_Seq     = 4'b0100, 
  Next_Seq    = 4'b0101, 
  Pause_1     = 4'b0110, 
  Pause_2     = 4'b0111, 
  Rst_Seq     = 4'b1000, 
  Start_Test  = 4'b1001, 
  Sync        = 4'b1010, 
  Update_Errs = 4'b1011; 

  reg [3:0] state;


  reg [3:0] nextstate;


  reg [15:0] gcnt;
  reg [2:0] seq_cnt;

  // comb always block
  always @* begin
    nextstate = 4'bxxxx; // default to x because default_state_is_x is set
    case (state)
      Idle       : if      (TEST_MODE)                       nextstate = Pause_1;
                   else                                      nextstate = Idle;
      Chk_Rbk    : if      (gcnt == 16'd9)                   nextstate = Update_Errs;
                   else                                      nextstate = Chk_Rbk;
      Clr_Addr   :                                           nextstate = Inc_Addr;
      Inc_Addr   : if      (gcnt == 16'd2)                   nextstate = Chk_Rbk;
                   else                                      nextstate = Inc_Addr;
      Inc_Seq    :                                           nextstate = Inc_Addr;
      Next_Seq   :                                           nextstate = Start_Test;
      Pause_1    : if      (!TEST_MODE)                      nextstate = Idle;
                   else if (gcnt == 16'hFFFF)                nextstate = Sync;
                   else                                      nextstate = Pause_1;
      Pause_2    : if      (!TEST_MODE && gcnt == 16'hFFFF)  nextstate = Idle;
                   else if (TEST_MODE && gcnt == 16'hFFFF)   nextstate = Sync;
                   else                                      nextstate = Pause_2;
      Rst_Seq    :                                           nextstate = Clr_Addr;
      Start_Test : if      (SEQ_DONE && seq_cnt == 3'd4)     nextstate = Rst_Seq;
                   else if (SEQ_DONE)                        nextstate = Next_Seq;
                   else                                      nextstate = Start_Test;
      Sync       :                                           nextstate = Start_Test;
      Update_Errs: if      (seq_cnt == 3'd1)                 nextstate = Pause_2;
                   else                                      nextstate = Inc_Seq;
    endcase
  end

  // Assign reg'd outputs to state bits

  // sequential always block
  always @(posedge CLK or posedge RST) begin
    if (RST)
      state <= Idle;
    else
      state <= nextstate;
  end

  // datapath sequential always block
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      CLR_ADDR <= 0;
      DAQ_CHK <= 0;
      INCR <= 0;
      START_TEST <= 0;
      SYNC <= 0;
      TRG_CHK <= 0;
      UPDATE <= 0;
      USE_TEST_DATA <= 0;
      gcnt <= 16'h0000;
      seq_cnt <= 3'd0;
    end
    else begin
      CLR_ADDR <= 0; // default
      DAQ_CHK <= 0; // default
      INCR <= 0; // default
      START_TEST <= 0; // default
      SYNC <= 0; // default
      TRG_CHK <= 0; // default
      UPDATE <= 0; // default
      USE_TEST_DATA <= 1; // default
      gcnt <= 16'h0000; // default
      seq_cnt <= seq_cnt; // default
      case (nextstate)
        Idle       : begin
                            CLR_ADDR <= 1;
                            USE_TEST_DATA <= 0;
        end
        Chk_Rbk    : begin
                            DAQ_CHK <= seq_cnt == 3'd0;
                            INCR <= 1;
                            TRG_CHK <= seq_cnt == 3'd1;
                            gcnt <= gcnt + 1;
        end
        Clr_Addr   :        CLR_ADDR <= 1;
        Inc_Addr   : begin
                            INCR <= 1;
                            gcnt <= gcnt + 1;
        end
        Inc_Seq    :        seq_cnt <= seq_cnt + 1;
        Next_Seq   :        seq_cnt <= seq_cnt + 1;
        Pause_1    : begin
                            CLR_ADDR <= 1;
                            USE_TEST_DATA <= 0;
                            gcnt <= gcnt + 1;
        end
        Pause_2    : begin
                            CLR_ADDR <= 1;
                            gcnt <= gcnt + 1;
                            seq_cnt <= 3'd0;
        end
        Rst_Seq    :        seq_cnt <= 3'd0;
        Start_Test :        START_TEST <= 1;
        Sync       :        SYNC <= 1;
        Update_Errs: begin
                            DAQ_CHK <= seq_cnt == 3'd0;
                            TRG_CHK <= seq_cnt == 3'd1;
                            UPDATE <= 1;
        end
      endcase
    end
  end

  // This code allows you to see state names in simulation
  `ifndef SYNTHESIS
  reg [87:0] statename;
  always @* begin
    case (state)
      Idle       : statename = "Idle";
      Chk_Rbk    : statename = "Chk_Rbk";
      Clr_Addr   : statename = "Clr_Addr";
      Inc_Addr   : statename = "Inc_Addr";
      Inc_Seq    : statename = "Inc_Seq";
      Next_Seq   : statename = "Next_Seq";
      Pause_1    : statename = "Pause_1";
      Pause_2    : statename = "Pause_2";
      Rst_Seq    : statename = "Rst_Seq";
      Start_Test : statename = "Start_Test";
      Sync       : statename = "Sync";
      Update_Errs: statename = "Update_Errs";
      default    : statename = "XXXXXXXXXXX";
    endcase
  end
  `endif

endmodule

