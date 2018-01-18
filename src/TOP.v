module TOP (
  input CLK,
  input RSTB,
  input [7:0]DIN,
  input [6:0]ADDR,
  input WR,
  input START,
  output OK,
  output [7:0]DOUT
  );

  wire [127:0]Ciphertext;
  wire Core_Full;
  wire c_ready;
  wire [127:0]Plain_text;
  wire [3:0]Nr;
  wire t_ready;
  wire t_reset;
  wire op;
  wire [255:0]CipherKey;
  wire [3:0]Nk;
  wire k_ready;
  wire k_reset;
  wire clk_slow;
  wire [128:0]Key;
  wire [3:0]Addr;

  IO_Interface io(.CLK(CLK),.RSTB(RSTB),.DIN(DIN),.ADDR(ADDR),.WR(WR),
          .START(START),.OK(OK),.DOUT(DOUT),
          .Ciphertext(Ciphertext),.Core_Full(Core_Full),.c_ready(c_ready),
          .Plain_text(Plain_text),.Nr(Nr),.t_ready(t_ready),.t_reset(t_reset),.op(op),
          .CipherKey(CipherKey),.Nk_val(Nk),.k_ready(k_ready),.k_reset(k_reset),
          .clk_slow(clk_slow));
  Encrypt_Core EC(.clk(clk_slow),.rst_n(t_reset),.t_ready(t_ready),
          .Plain_text(Plain_text),.op(op),.Nr(Nr),.Key(Key),.Addr(Addr),
          .Core_Full(Core_Full),.c_ready(c_ready),.Ciphertext(Ciphertext));
  Key_Expansion KE(.clk(clk_slow),.rst_n(k_reset),.CipherKey(CipherKey),
          .k_ready(k_ready),.Nk(Nk),.Addr(Addr),.ex_key(Key));


endmodule // TOP
