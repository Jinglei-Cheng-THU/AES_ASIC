`include "aes_tbox.v"
`include "aes_sbox.v"
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

  wire [127:0]add_in;
  wire [127:0]key_in;
  wire [127:0]add_out;

  wire [127:0]shift_in;
  wire [127:0]pre_shift[0:2];
  wire [127:0]shift_out[0:2];

  wire [127:0]mix_in;
  wire [127:0]mix_out;

  reg [127:0]round_result;
  reg [3:0]rounds;
  assign add_out <= add_in ^ key_in;

  assign shift_in = add_out;

  generate
    genvar i;
    for (i = 0; i < 16; i = i + 1) begin:gen_tbox
      aes_tbox tboxs(shift_in[8*i+7:8*i],{pre_shift[0][8*i+7:8*i],pre_shift[1][8*i+7:8*i],pre_shift[2][8*i+7:8*i]});
    end
    genvar c,r,t;
    for (c = 0; c < 4; c = c + 1) begin:select_coloum
      for (r = 0; r < 4; r = r + 1) begin:select_row
        for (t = 0; t < 3; t= t + 1) begin:select_times
          assign shift_out[t][32*c+8*r+7:32*c+8*r] = pre_shift[t][((4*c+r+c)%4+c*4)*8+7:((4*c+r+c)%4+c*4)*8];
        end
      end
    end
  endgenerate

  generate
    genvar m;
    for (m = 0; m < 4; m = m + 1) begin : gen_mix
      assign mix_out[m*32+31:m*32] = (|shift_channel) ?
          { shift_out[2][m*32+7:m*32]^shift_out[0][m*32+15:m*32+8]^shift_out[0][m*32+23:m*32+16]^shift_out[1][m*32+31:m*32+24],
            shift_out[0][m*32+7:m*32]^shift_out[0][m*32+15:m*32+8]^shift_out[1][m*32+23:m*32+16]^shift_out[2][m*32+31:m*32+24],
            shift_out[0][m*32+7:m*32]^shift_out[1][m*32+15:m*32+8]^shift_out[2][m*32+23:m*32+16]^shift_out[0][m*32+31:m*32+24],
            shift_out[1][m*32+7:m*32]^shift_out[2][m*32+15:m*32+8]^shift_out[0][m*32+23:m*32+16]^shift_out[0][m*32+31:m*32+24]} : 32'h0;
    end
  endgenerate



endmodule
