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

  reg [127:0]add_in;
  reg [127:0]key_in;
  reg [127:0]add_out;
  reg [2:0]add_channel;


  wire [127:0]shift_in;
  wire [127:0]pre_shift_w[0:2];
  wire [127:0]shift_out_w[0:2];
  reg [127:0]shift_out[0:2];
  reg [2:0]shift_channel;


  wire [127:0]mix_in;
  wire [127:0]mix_out_w;
  reg [127:0]mix_out;
  reg [2:0]mix_channel;

  always @ ( posedge clk or negedge rst_n ) begin
    if(~rst_n) begin
      add_out <= 127'h0;
      add_channel <= 3'h0;
    end
    else begin
      if(running) begin
        add_out <= add_in ^ key_in;
        add_channel <= current_channel;
      end
      else begin
        add_out <= add_out;
        add_channel <= add_channel;
      end
    end
  end

  assign shift_in = (|add_channel) ? add_out : 127'h0 ;

  always @ ( posedge clk or negedge rst_n ) begin
    if(~rst_n) begin
      shift_channel <= 3'h0;
    end
    else begin
      if(running)
        shift_channel <= add_channel;
      else
        shift_channel <= shift_channel;
    end
  end

  generate
    genvar i;
    for (i = 0; i < 16; i = i + 1) begin:gen_tbox
      aes_tbox tboxs(shift_in[8*i+7:8*i],{pre_shift_w[0][8*i+7:8*i],pre_shift_w[1][8*i+7:8*i],pre_shift_w[2][8*i+7:8*i]});
    end
    genvar c,r,t;
    for (c = 0; c < 4; c = c + 1) begin:select_coloum
      for (r = 0; r < 4; r = r + 1) begin:select_row
        for (t = 0; t < 3; t= t + 1) begin:select_times
          assign shift_out_w[t][32*c+8*r+7:32*c+8*r] = pre_shift_w[t][((4*c+r+c)%4+c*4)*8+7:((4*c+r+c)%4+c*4)*8];
        end
      end
    end
    for (i = 0; i < 3; i = i + 1)begin:write_reg
      always @ ( posedge clk or negedge rst_n ) begin
        if(~rst_n) begin
          shift_out[i] <= 127'h0;
        end
        else begin
          if(running)
            shift_out[i] <= shift_out_w[i];
          else
            shift_out[i] <= shift_out[i];
        end
      end
    end
  endgenerate


  generate
    genvar m;
    for (m = 0; m < 4; m = m + 1) begin : gen_mix
      assign mix_out_w[m*32+31:m*32] = (|shift_channel) ?
          { shift_out[2][m*32+7:m*32]^shift_out[0][m*32+15:m*32+8]^shift_out[0][m*32+23:m*32+16]^shift_out[1][m*32+31:m*32+24],
            shift_out[0][m*32+7:m*32]^shift_out[0][m*32+15:m*32+8]^shift_out[1][m*32+23:m*32+16]^shift_out[2][m*32+31:m*32+24],
            shift_out[0][m*32+7:m*32]^shift_out[1][m*32+15:m*32+8]^shift_out[2][m*32+23:m*32+16]^shift_out[0][m*32+31:m*32+24],
            shift_out[1][m*32+7:m*32]^shift_out[2][m*32+15:m*32+8]^shift_out[0][m*32+23:m*32+16]^shift_out[0][m*32+31:m*32+24]} : 32'h0;
    end
  endgenerate

  always @ ( posedge clk or negedge rst_n ) begin
    if(~rst_n) begin
      mix_out <= 127'h0;
      mix_channel <= 3'h0;
    end
    else begin
      if(running) begin
        mix_out <= mix_out_w;
        mix_channel <= shift_channel;
      end
      else begin
        mix_out <= mix_out;
        mix_channel <= mix_channel;
      end
    end
  end

  always @ ( posedge clk or negedge rst_n ) begin
  if(~rst_n) begin
    add_out <= 127'h0;
    add_channel <= 3'h0;
  end
  else begin
    add_out <= add_in ^ key_in;
    add_channel <= current_channel;
  end
  end


endmodule
