module Encrypt_Core (
  input clk,
  input rst_n,
  input t_ready,
  input [127:0]Plain_text,
  input [3:0]Nr,
  input [128:0]Key,
  output [5:0]Addr,
  output Core_Full,
  output c_ready,
  output [127:0]Ciphertext
);

endmodule
