`timescale 1ns/1ns
module io_tb ();
  reg [7:0]DIN;
  reg CLK;
  reg RSTB;
  reg [6:0]ADDR;
  reg WR;
  reg START;
  wire OK;
  wire [7:0]DOUT;
  reg [127:0]Ciphertext;
  reg Core_Full;
  reg c_ready;
  wire [127:0]Plain_text;
  wire [3:0]Nr;
  wire t_ready;
  wire t_reset;
  wire op;
  wire [255:0]CipherKey;
  wire [3:0] Nk;
  wire k_ready;
  wire k_reset;
  wire clk_slow;
  reg start_fetch;
  integer i,j;
  initial begin
    i <= 0;
    j <= 0;
    START <= 0;
    CLK <= 0;
    RSTB <= 1;
    #2 RSTB <= 0;
    #3 RSTB <= 1;
    Core_Full <= 0;
    forever #5CLK <= ~CLK;

  end
  always @ (posedge CLK) begin
    if(START)
      Core_Full <= 1;
    else
      if(i == 100)
        Core_Full <= 0;
  end
  always @ (posedge CLK) begin
    i <= i + 1;
    if (i < 16) begin
      ADDR <= i;
      DIN <= i;
      WR <= 1;
    end
    if(i >15 && i < 48) begin
      ADDR <= i + 16;
      DIN <= i;
      WR <= 1;
    end
    if(i == 48) begin
      ADDR <= 64;
      DIN <= 8'h01;
      WR <= 1;
    end
    if(i == 49) begin
      ADDR <= 65;
      DIN <= 8'h05;
      WR <= 1;
    end
    if(i == 55) begin
      ADDR <= 65;
      DIN <= 8'h01;
      WR <= 0;
    end
    if(i == 56) begin
      ADDR <= 64;
      DIN <= 8'h01;
      WR <= 0;
    end
    if(i == 57) begin
      ADDR <= 66;
      DIN <= 8'h01;
      WR <= 0;
    end
    if(i == 65) begin
      ADDR <= 66;
      DIN <= 8'h01;
      WR <= 0;
    end
    if(i > 100 ) begin
      if(start_fetch) begin
        ADDR <= j+32'd16;
        DIN <= 8'h00;
        WR <= 0;
      end
      else begin
        ADDR <= i;
        DIN <= 8'h00;
        WR <= 0;
      end
    end
  end
  always @ (posedge CLK ) begin
    if(i == 60)
      START <= 1;
    else
      START <= 0;
  end
  always @ (posedge CLK) begin
    if(i == 100) begin
      Ciphertext <= 128'h123456789abcdef00123456789abcdef;
      c_ready <= 1;
    end
  end
  always @ (posedge CLK) begin
    if(start_fetch)
      j <= j + 32'h1;
    else
      j <= 0;
  end

  always @ ( posedge CLK ) begin
    if(OK)
      start_fetch <= 1;
    else
      if(j == 16)
        start_fetch <= 0;
  end

  IO_Interface io(.CLK(CLK),.RSTB(RSTB),.DIN(DIN),.ADDR(ADDR),.WR(WR),
          .START(START),.OK(OK),.DOUT(DOUT),
          .Ciphertext(Ciphertext),.Core_Full(Core_Full),.c_ready(c_ready),
          .Plain_text(Plain_text),.Nr(Nr),.t_ready(t_ready),.t_reset(t_reset),.op(op),
          .CipherKey(CipherKey),.Nk_val(Nk),.k_ready(k_ready),.k_reset(k_reset),
          .clk_slow(clk_slow));
endmodule // io_tb
