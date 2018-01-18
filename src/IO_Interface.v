`include "divide16.v"
module IO_Interface(
  input CLK,
  input RSTB,
  input [7:0]DIN,
  input [6:0]ADDR,
  input WR,
  input START,
  output reg OK,
  output reg [7:0]DOUT,
  //above are ports defined for the host
  input [127:0]Ciphertext,   //Encrypted Data
  input Core_Full,    //Being 1 means Encrypt Core is already fully occupied and do not feed any more data.
  input c_ready,    //indicate Ciphertext is ready.
  output reg[127:0]Plain_text,
  output reg[3:0]Nr,   //number of encryption rounds, 10, 12, 14 for 128, 192, 256 keys seperately
  output reg t_ready,   //indicate Plain_text data is ready
  output t_reset,   //reset Encrypt Core
  output reg op,        //indicate operations, 0 for decryption and 1 for encryption
  //above are interactions with Encrypt Core.
  output reg [255:0]CipherKey,  //CipherKey, fill unused bits with 0.
  output reg [3:0]Nk_val, //value of Nk, 4 for 128 bits key, 6 for 192 and 8 for 256
  output reg k_ready,   //indicate CipherKey data is ready
  output k_reset,   //reset key expansion Core
  //above are interactions with key expansion core.
  output clk_slow   //divided slow clock
);
  reg inter_ok;
  divide16 div_16(CLK,clk_slow);
  wire [127:0] Plain_text_w;
  wire [255:0] CipherKey_w;

  reg operation;
  reg [7:0]Data_reg[63:0];
  reg [2:0]NK;
  reg CORE_FULL;

  generate
    genvar k;
    for (k = 0; k < 16; k = k + 1) begin : assign_Plain_text_w
      assign Plain_text_w[8*k+7:8*k] = (Data_reg[k]);
    end
    for (k = 0; k < 32; k = k + 1) begin : assign_CipherKey_w
      assign CipherKey_w[8*k+7:8*k] = (Data_reg[k+32]);
    end
  endgenerate

  generate
    genvar i;
    for (i = 0; i < 64; i = i + 1)begin: gen_reg
      if(i < 16 || (i > 31)) begin
        always @ (posedge CLK or negedge RSTB) begin
          if (~RSTB) begin
            Data_reg[i] <= 0;
          end
          else begin
            if (WR && ~ADDR[6] && ADDR[5:0] == i[5:0]) begin
              Data_reg[i] <= DIN;
            end else begin
              Data_reg[i] <= Data_reg[i];
            end
          end
        end
      end
      else begin
        always @ (posedge CLK or negedge RSTB) begin
          if(c_ready) begin
            Data_reg[i] <= Ciphertext[8*(i-16)+7:8*(i-16)];
          end
          else begin
            Data_reg[i] <= Data_reg[i];
          end
        end
      end
    end
  endgenerate

  always @ (posedge CLK or negedge RSTB) begin
    if(~RSTB) begin
      operation <= 0;
      NK <=3'h0;
    end
    else begin
      if(WR && ADDR[6]) begin
        if(ADDR[0]) begin
          NK <= DIN[2:0];
          operation <= operation;
        end
        else begin
          NK <= NK;
          operation <= DIN[0];
        end
      end
    end
  end

  always @ (posedge CLK or negedge RSTB) begin
    if(~RSTB) begin
      DOUT <= 8'h00;
    end
    else begin
      if(~WR) begin
        if(ADDR[6]) begin
          if(ADDR[1]) begin
            DOUT <= {7'h00,CORE_FULL};
          end
          else begin
            if(ADDR[0]) begin
              DOUT <= {4'h0,NK};
            end
            else begin
              DOUT <= {7'h00,operation};
            end
          end
        end
        else begin
          DOUT <= Data_reg[ADDR[5:0]];
        end
      end
      else begin
        DOUT <= 8'h00;
      end
    end
  end

  always @ (posedge CLK or negedge RSTB) begin
    if(~RSTB) begin
      inter_ok <= 0;
    end
    else begin
      if(START && ~CORE_FULL) begin
        inter_ok <= 1;
      end
      else begin
        if(t_ready && k_ready) begin
          inter_ok <= 0;
        end
        else begin
          inter_ok <= inter_ok;
        end
      end
    end
  end

  always @ (posedge CLK or negedge RSTB) begin
    if(~RSTB) begin
      inter_ok <= 0;
      OK <= 0;
    end
    else begin
      if(c_ready) begin
        OK <= 1;
      end
      else begin
        if(START) begin
          OK <= 0;
        end
        else begin
          OK <= OK;
        end
      end
    end
  end

  always @ (posedge CLK or negedge RSTB) begin
    if(~RSTB) begin
      CORE_FULL <= 0;
    end
    else begin
      CORE_FULL <= Core_Full;
    end
  end

  always @ (posedge clk_slow or negedge RSTB) begin
    if(~RSTB) begin
      Nr <= 4'h0;
      t_ready <= 0;
      Plain_text <= 127'h0;
      op <= 0;
      k_ready <= 0;
      CipherKey <= 256'h0;
      Nk_val <= 4'h0;
    end
    else begin
      if(inter_ok) begin
        case (NK)
          3'b011: Nr <= 4'd10;
          3'b101: Nr <= 4'd12;
          3'b111: Nr <= 4'd14;
          default: Nr <= 4'd0;
        endcase
        Nk_val <= {1'b0,NK};
        Plain_text <= Plain_text_w;
        CipherKey <= CipherKey_w;
        k_ready <= 1;
        t_ready <= 1;
        op <= operation;
      end
      else begin
        Nr <= 4'h0;
        t_ready <= 0;
        Plain_text <= 127'h0;
        op <= 0;
        k_ready <= 0;
        CipherKey <= 256'h0;
        Nk_val <= 4'h0;
      end
    end
  end

  assign t_reset = (RSTB);
  assign k_reset = (RSTB);
endmodule
/*
reg [2:0]c;
reg ED;
reg [2:0]NK;
reg [7:0]TX0;
reg [7:0]TX1;
reg [7:0]TX2;
reg [7:0]TX3;
reg [7:0]TX4;
reg [7:0]TX5;
reg [7:0]TX6;
reg [7:0]TX7;
reg [7:0]TX8;
reg [7:0]TX9;
reg [7:0]TX10;
reg [7:0]TX11;
reg [7:0]TX12;
reg [7:0]TX13;
reg [7:0]TX14;
reg [7:0]TX15;
reg [7:0]RT0;
reg [7:0]RT1;
reg [7:0]RT2;
reg [7:0]RT3;
reg [7:0]RT4;
reg [7:0]RT5;
reg [7:0]RT6;
reg [7:0]RT7;
reg [7:0]RT8;
reg [7:0]RT9;
reg [7:0]RT10;
reg [7:0]RT11;
reg [7:0]RT12;
reg [7:0]RT13;
reg [7:0]RT14;
reg [7:0]RT15;
reg [7:0]KY0;
reg [7:0]KY01;
reg [7:0]KY02;
reg [7:0]KY03;
reg [7:0]KY04;
reg [7:0]KY05;
reg [7:0]KY06;
reg [7:0]KY07;
reg [7:0]KY08;
reg [7:0]KY09;
reg [7:0]KY10;
reg [7:0]KY11;
reg [7:0]KY12;
reg [7:0]KY13;
reg [7:0]KY14;
reg [7:0]KY15;
reg [7:0]KY16;
reg [7:0]KY17;
reg [7:0]KY18;
reg [7:0]KY19;
reg [7:0]KY20;
reg [7:0]KY21;
reg [7:0]KY22;
reg [7:0]KY23;
reg [7:0]KY24;
reg [7:0]KY25;
reg [7:0]KY26;
reg [7:0]KY27;
reg [7:0]KY28;
reg [7:0]KY29;
reg [7:0]KY30;
reg [7:0]KY31;
initial
begin
ED<=1'd0;
NK<=3'd0;
TX0<=8'd0;
TX1<=8'd0;
TX2<=8'd0;
TX3<=8'd0;
TX4<=8'd0;
TX5<=8'd0;
TX6<=8'd0;
TX7<=8'd0;
TX8<=8'd0;
TX9<=8'd0;
TX10<=8'd0;
TX11<=8'd0;
TX12<=8'd0;
TX13<=8'd0;
TX14<=8'd0;
TX15<=8'd0;
RT0<=8'd0;
RT1<=8'd0;
RT3<=8'd0;
RT4<=8'd0;
RT5<=8'd0;
RT6<=8'd0;
RT7<=8'd0;
RT8<=8'd0;
RT9<=8'd0;
RT10<=8'd0;
RT11<=8'd0;
RT12<=8'd0;
RT13<=8'd0;
RT14<=8'd0;
RT15<=8'd0;
KY0<=8'd0;
KY01<=8'd0;
KY02<=8'd0;
KY04<=8'd0;
KY03<=8'd0;
KY05<=8'd0;
KY06<=8'd0;
KY07<=8'd0;
KY08<=8'd0;
KY09<=8'd0;
KY10<=8'd0;
KY11<=8'd0;
KY12<=8'd0;
KY13<=8'd0;
KY14<=8'd0;
KY15<=8'd0;
KY16<=8'd0;
KY17<=8'd0;
KY18<=8'd0;
KY19<=8'd0;
KY20<=8'd0;
KY21<=8'd0;
KY22<=8'd0;
KY23<=8'd0;
KY24<=8'd0;
KY25<=8'd0;
KY26<=8'd0;
KY27<=8'd0;
KY28<=8'd0;
KY29<=8'd0;
KY30<=8'd0;
KY31<=8'd0;
DOUT<=8'd0;
OK<=0;
end
always @(posedge CLK or negedge RSTB)
begin
if(~RSTB)
  begin
ED<=1'd0;
NK<=3'd0;
TX0<=8'd0;
TX1<=8'd0;
TX2<=8'd0;
TX3<=8'd0;
TX4<=8'd0;
TX5<=8'd0;
TX6<=8'd0;
TX7<=8'd0;
TX8<=8'd0;
TX9<=8'd0;
TX10<=8'd0;
TX11<=8'd0;
TX12<=8'd0;
TX13<=8'd0;
TX14<=8'd0;
TX15<=8'd0;
RT0<=8'd0;
RT1<=8'd0;
RT3<=8'd0;
RT4<=8'd0;
RT5<=8'd0;
RT6<=8'd0;
RT7<=8'd0;
RT8<=8'd0;
RT9<=8'd0;
RT10<=8'd0;
RT11<=8'd0;
RT12<=8'd0;
RT13<=8'd0;
RT14<=8'd0;
RT15<=8'd0;
KY0<=8'd0;
KY01<=8'd0;
KY02<=8'd0;
KY04<=8'd0;
KY03<=8'd0;
KY05<=8'd0;
KY06<=8'd0;
KY07<=8'd0;
KY08<=8'd0;
KY09<=8'd0;
KY10<=8'd0;
KY11<=8'd0;
KY12<=8'd0;
KY13<=8'd0;
KY14<=8'd0;
KY15<=8'd0;
KY16<=8'd0;
KY17<=8'd0;
KY18<=8'd0;
KY19<=8'd0;
KY20<=8'd0;
KY21<=8'd0;
KY22<=8'd0;
KY23<=8'd0;
KY24<=8'd0;
KY25<=8'd0;
KY26<=8'd0;
KY27<=8'd0;
KY28<=8'd0;
KY29<=8'd0;
KY30<=8'd0;
KY31<=8'd0;
DOUT<=8'd0;
OK<=0;
end
else
  begin
if(WR==1)
  begin
    case(ADDR)
      6'h08 : ED<=DIN[0];
      6'h09 : NK<=DIN[2:0];
      6'h00 : TX0<=DIN;
      6'h01 : TX1<=DIN;
      6'h02 : TX2<=DIN;
      6'h03 : TX3<=DIN;
      6'h04 : TX4<=DIN;
      6'h05 : TX5<=DIN;
      6'h06 : TX6<=DIN;
      6'h07 : TX7<=DIN;
      6'h08 : TX8<=DIN;
      6'h09 : TX9<=DIN;
      6'h0A : TX10<=DIN;
      6'h0B : TX11<=DIN;
      6'h0C : TX12<=DIN;
      6'h0D : TX13<=DIN;
      6'h0E : TX14<=DIN;
      6'h0F : TX15<=DIN;
      6'h10 : RT0<=DIN;
      6'h11 : RT1<=DIN;
      6'h12 : RT2<=DIN;
      6'h13 : RT3<=DIN;
      6'h14 : RT4<=DIN;
      6'h15 : RT5<=DIN;
      6'h16 : RT6<=DIN;
      6'h17 : RT7<=DIN;
      6'h18 : RT8<=DIN;
      6'h19 : RT9<=DIN;
      6'h1A : RT10<=DIN;
      6'h1B : RT11<=DIN;
      6'h1C : RT12<=DIN;
      6'h1D : RT13<=DIN;
      6'h1E : RT14<=DIN;
      6'h1F : RT15<=DIN;
      6'h20 : KY0<=DIN;
      6'h21 : KY01<=DIN;
      6'h22 : KY02<=DIN;
      6'h23 : KY03<=DIN;
      6'h24 : KY04<=DIN;
      6'h25 : KY05<=DIN;
      6'h26 : KY06<=DIN;
      6'h27 : KY07<=DIN;
      6'h28 : KY08<=DIN;
      6'h29 : KY09<=DIN;
      6'h2A : KY10<=DIN;
      6'h2B : KY11<=DIN;
      6'h2C : KY12<=DIN;
      6'h2D : KY13<=DIN;
      6'h2E : KY14<=DIN;
      6'h2F : KY15<=DIN;
      6'h30 : KY16<=DIN;
      6'h31 : KY17<=DIN;
      6'h32 : KY18<=DIN;
      6'h33 : KY19<=DIN;
      6'h34 : KY20<=DIN;
      6'h35 : KY21<=DIN;
      6'h36 : KY22<=DIN;
      6'h37 : KY23<=DIN;
      6'h38 : KY24<=DIN;
      6'h39 : KY25<=DIN;
      6'h3A : KY26<=DIN;
      6'h3B : KY27<=DIN;
      6'h3C : KY28<=DIN;
      6'h3D : KY29<=DIN;
      6'h3E : KY30<=DIN;
      6'h3F : KY31<=DIN;
    endcase
  end
else
  begin
    case(ADDR)
      6'h08 : DOUT[0]<=ED;
      6'h09 : DOUT[2:0]<=NK;
      6'h00 : DOUT<=TX0;
      6'h01 : DOUT<=TX1;
      6'h02 : DOUT<=TX2;
      6'h03 : DOUT<=TX3;
      6'h04 : DOUT<=TX4;
      6'h05 : DOUT<=TX5;
      6'h06 : DOUT<=TX6;
      6'h07 : DOUT<=TX7;
      6'h08 : DOUT<=TX8;
      6'h09 : DOUT<=TX9;
      6'h0A : DOUT<=TX10;
      6'h0B : DOUT<=TX11;
      6'h0C : DOUT<=TX12;
      6'h0D : DOUT<=TX13;
      6'h0E : DOUT<=TX14;
      6'h0F : DOUT<=TX15;
      6'h10 : DOUT<=RT0;
      6'h11 : DOUT<=RT1;
      6'h12 : DOUT<=RT2;
      6'h13 : DOUT<=RT3;
      6'h14 : DOUT<=RT4;
      6'h15 : DOUT<=RT5;
      6'h16 : DOUT<=RT6;
      6'h17 : DOUT<=RT7;
      6'h18 : DOUT<=RT8;
      6'h19 : DOUT<=RT9;
      6'h1A : DOUT<=RT10;
      6'h1B : DOUT<=RT11;
      6'h1C : DOUT<=RT12;
      6'h1D : DOUT<=RT13;
      6'h1E : DOUT<=RT14;
      6'h1F : DOUT<=RT15;
      6'h20 : DOUT<=KY0;
      6'h21 : DOUT<=KY01;
      6'h22 : DOUT<=KY02;
      6'h23 : DOUT<=KY03;
      6'h24 : DOUT<=KY04;
      6'h25 : DOUT<=KY05;
      6'h26 : DOUT<=KY06;
      6'h27 : DOUT<=KY07;
      6'h28 : DOUT<=KY08;
      6'h29 : DOUT<=KY09;
      6'h2A : DOUT<=KY10;
      6'h2B : DOUT<=KY11;
      6'h2C : DOUT<=KY12;
      6'h2D : DOUT<=KY13;
      6'h2E : DOUT<=KY14;
      6'h2F : DOUT<=KY15;
      6'h30 : DOUT<=KY16;
      6'h31 : DOUT<=KY17;
      6'h32 : DOUT<=KY18;
      6'h33 : DOUT<=KY19;
      6'h34 : DOUT<=KY20;
      6'h35 : DOUT<=KY21;
      6'h36 : DOUT<=KY22;
      6'h37 : DOUT<=KY23;
      6'h38 : DOUT<=KY24;
      6'h39 : DOUT<=KY25;
      6'h3A : DOUT<=KY26;
      6'h3B : DOUT<=KY27;
      6'h3C : DOUT<=KY28;
      6'h3D : DOUT<=KY29;
      6'h3E : DOUT<=KY30;
      6'h3F : DOUT<=KY31;
    endcase
  end
end
end
always @(posedge clk_slow)
begin
  if(START)
    begin
      OK<=0;
      case(NK)
        3'b011 :
        begin
        Nk_val<=4'b0100;
        Nr<=4'b1010;
        CipherKey[127:0]<= {KY15,KY14,KY13,KY12,KY11,KY10,KY09,KY08,KY07,KY06,KY05,KY04,KY03,KY02,KY01,KY0};
        CipherKey[255:128]<=0;
        k_ready<=1;
        k_reset<=1;
        end
        3'b101 :
        begin
        Nk_val<=4'b0110;
        Nr<=4'b1100;
        CipherKey[191:0]<= {KY23,KY22,KY21,KY20,KY19,KY18,KY17,KY16,KY15,KY14,KY13,KY12,KY11,KY10,KY09,KY08,KY07,KY06,KY05,KY04,KY03,KY02,KY01,KY0};
        CipherKey[255:191]<=0;
        k_ready<=1;
        k_reset<=1;
        end
        3'b111 :
        begin
        Nk_val<=4'b1000;
        Nr<=4'b1110;
        CipherKey[255:0]<= {KY31,KY30,KY29,KY28,KY27,KY26,KY25,KY24,KY23,KY22,KY21,KY20,KY19,KY18,KY17,KY16,KY15,KY14,KY13,KY12,KY11,KY10,KY09,KY08,KY07,KY06,KY05,KY04,KY03,KY02,KY01,KY0};
        k_ready<=1;
        k_reset<=1;
        end
      endcase
      case(ED)
      1'b1: op<=1;
      1'b0: op<=0;
      endcase
      if(c_ready && !(Core_Full))
        begin
      Plain_text[127:0]<={TX15,TX14,TX13,TX12,TX11,TX10,TX9,TX8,TX7,TX6,TX5,TX4,TX3,TX2,TX1,TX0};
      {RT15,RT14,RT13,RT12,RT11,RT10,RT9,RT8,RT7,RT6,RT5,RT4,RT3,RT2,RT1,RT0}<=Ciphertext[127:0];
      t_ready<=1;
      t_reset<=1;
    end
    if(t_ready)
    OK<=1;
    end

    end

endmodule

*/
