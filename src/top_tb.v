`include "TOP.v"
`timescale 1ns/1ns
module top_tb ();
  reg [127:0]Plain;
  reg [256:0]Key;
  reg [7:0]DIN;
  reg CLK;
  reg RSTB;
  reg [6:0]ADDR;
  reg WR;
  reg START;
  wire OK;
  wire [7:0]DOUT;
  integer i,j;
  reg [7:0]Data_reg[0:63];

  initial begin
    //Plain <= 128'h00112233445566778899aabbccddeeff;
    Plain <= 128'hdda97ca4864cdfe06eaf70a0ec0d7191;
    Key <= 256'h000102030405060708090a0b0c0d0e0f1011121314151617;
    i <= 0;
    j <= 0;
    START <= 0;
    CLK <= 0;
    RSTB <= 1;
    #2 RSTB <= 0;
    #3 RSTB <= 1;

  end

  generate
    genvar k;
    for (k = 0; k < 16; k = k + 1) begin : assign_Plain_text_w
      initial begin
        #2 Data_reg[k] <= Plain[8*k+7:8*k];
      end
    end
    for (k = 0; k < 32; k = k + 1) begin : assign_CipherKey_w
      initial begin
        #2 Data_reg[k+32] <= Key[8*k+7:8*k];
      end
    end
  endgenerate

  initial begin
    forever # 5CLK <= ~CLK;
  end
  always @ (posedge CLK) begin
    i <= i + 1;
    if (i < 16) begin
      ADDR <= i;
      DIN <= Data_reg[i];
      WR <= 1;
    end
    if(i >15 && i < 48) begin
      ADDR <= i + 16;
      DIN <= Data_reg[i + 16];
      WR <= 1;
    end
    if(i == 48) begin
      ADDR <= 64;
      DIN = 8'h00;
      WR <= 1;
    end
    if(i == 49) begin
      ADDR <= 65;
      DIN = 8'h05;
      WR <= 1;
    end
    if(i == 55) begin
      ADDR <= 65;
      DIN = 8'h01;
      WR <= 0;
    end
    if(i == 56) begin
      ADDR <= 64;
      DIN = 8'h01;
      WR <= 0;
    end
    if(i == 57) begin
      ADDR <= 66;
      DIN = 8'h01;
      WR <= 0;
    end
    if(i == 80) begin
      ADDR <= 66;
      DIN = 8'h01;
      WR <= 0;
    end
    if (i > 80 && OK) begin
      ADDR <= j+16;
      DIN = 8'h01;
      WR <= 0;
    end
  end
  always @ (posedge CLK ) begin
    if(i > 60 || j == 32)
      START <= 1;
    else
      START <= 0;
  end

  always @ (posedge CLK) begin
    if(OK)
      j <= j + 32'h1;
    else
      j <= 0;
  end

  TOP top(CLK,RSTB,DIN,ADDR,WR,START,OK,DOUT);
endmodule // io_tb
