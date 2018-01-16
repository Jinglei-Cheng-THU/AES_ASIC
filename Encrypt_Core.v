`include "aes_tbox.v"
`include "aes_sbox.v"
`include "aes_tbox_r.v"
module Encrypt_Core (
  input clk,
  input rst_n,
  input t_ready,
  input [127:0]Plain_text,
  input [3:0]Nr,
  input [128:0]Key,
  input op, //op = 1: encrypt; op = 0: decrypt
  output reg [3:0]Addr,
  output reg Core_Busy,
  output reg c_ready,
  output reg [127:0]Ciphertext
);
  wire [127:0]add_in;
  wire [127:0]key_in;
  wire [127:0]add_out;

  wire [127:0]shift_in;
  wire [127:0]pre_shift[0:3];
  wire [127:0]shift_out[0:3];
  wire [127:0]tbox_out[0:3];
  wire [127:0]tbox_out_r[0:3];


  wire [127:0]mix_out;

  reg [127:0]round_result;
  reg [3:0]rounds;
  reg operation;
  reg final_round;

  assign key_in = Key[127:0];
  always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      Ciphertext <= 128'h0;
      c_ready <= 0;
    end
    else begin
      if(Addr == rounds) begin
        Ciphertext <= round_result ^ key_in;
        c_ready <= 1;
      end
      else begin
        Ciphertext <= 128'h0;
        c_ready <= 0;
      end
    end
  end
  //controller
  always @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      rounds <= 4'h0;
      round_result <= 127'h0;
      Core_Busy <= 0;
      Addr <= 4'h1;
      operation <= 0;
    end
    else begin
      if (~Core_Busy) begin
        if (t_ready) begin
          round_result <= Plain_text;
          Core_Busy <= 1;
          operation <= op;
          if(op) begin
            Addr <= 4'h0;
            rounds <= Nr;
          end
          else begin
            Addr <= Nr;
            rounds <= 4'h0;
          end
        end
        else begin
          round_result <= round_result;
          Core_Busy <= Core_Busy;
          rounds <= rounds;
          operation <= operation;
          Addr <= Addr;
        end
      end
      else begin
        operation <= operation;
        rounds <= rounds;
        if (Key[128]) begin
          if(Addr == rounds) begin
            Core_Busy <= 0;
            Addr <= 4'h0;
          end
          else begin
            if(operation) begin
              Addr <= Addr + 1;
            end
            else begin
              Addr <= Addr - 1;
            end
            Core_Busy <= Core_Busy;
          end
          round_result <= mix_out;
        end
        else begin
          round_result <= round_result;
          Addr <= Addr;
          Core_Busy <= Core_Busy;
        end
      end
    end
  end

  //add round key
  assign add_in = round_result;
  assign add_out = add_in ^ key_in;
  //tbox and shift row
  assign shift_in = add_out;

  generate
    genvar i;
    for (i = 0; i < 4; i = i + 1) begin:assign_tbox_out
      assign pre_shift[i] = op ? tbox_out[i] : tbox_out_r[i];
    end
    for (i = 0; i < 16; i = i + 1) begin:gen_tbox
      aes_tbox tboxs(shift_in[8*i+7:8*i],{tbox_out[3][8*i+7:8*i],tbox_out[2][8*i+7:8*i],tbox_out[1][8*i+7:8*i],tbox_out[0][8*i+7:8*i]});
      aes_tbox_r tboxs_r(shift_in[8*i+7:8*i],{tbox_out_r[3][8*i+7:8*i],tbox_out_r[2][8*i+7:8*i],tbox_out_r[1][8*i+7:8*i],tbox_out_r[0][8*i+7:8*i]});
    end
    genvar c,r,t;
    for (c = 0; c < 4; c = c + 1) begin:select_column
      for (r = 0; r < 4; r = r + 1) begin:select_row
        for (t = 0; t < 4; t= t + 1) begin:select_times
          assign shift_out[t][32*c+8*r+7:32*c+8*r] =
              operation ? pre_shift[t][((4*c+4*r+r+16)%16)*8+7:((4*c+4*r+r+16)%16)*8] :
                          pre_shift[t][((4*c-4*r+r+16)%16)*8+7:((4*c-4*r+r+16)%16)*8];
        end
      end
    end
  endgenerate

  //mix column
  generate
    genvar m;
    for (m = 0; m < 4; m = m + 1) begin : gen_mix
      assign mix_out[m*32+31:m*32] = ((operation & (Addr == (rounds - 1)))|(~operation & (Addr == (rounds + 1)))) ? operation ? shift_out[0][m*32+31:m*32] :
        { shift_out[2][m*32+31:m*32+24]^shift_out[1][m*32+31:m*32+24]^shift_out[0][m*32+31:m*32+24]^shift_out[3][m*32+31:m*32+24],
          shift_out[1][m*32+23:m*32+16]^shift_out[0][m*32+23:m*32+16]^shift_out[3][m*32+23:m*32+16]^shift_out[2][m*32+23:m*32+16],
          shift_out[0][m*32+15:m*32+8]^shift_out[3][m*32+15:m*32+8]^shift_out[2][m*32+15:m*32+8]^shift_out[1][m*32+15:m*32+8],
          shift_out[3][m*32+7:m*32]^shift_out[2][m*32+7:m*32]^shift_out[1][m*32+7:m*32]^shift_out[0][m*32+7:m*32]} :
        { shift_out[2][m*32+7:m*32]^shift_out[1][m*32+15:m*32+8]^shift_out[0][m*32+23:m*32+16]^shift_out[3][m*32+31:m*32+24],
          shift_out[1][m*32+7:m*32]^shift_out[0][m*32+15:m*32+8]^shift_out[3][m*32+23:m*32+16]^shift_out[2][m*32+31:m*32+24],
          shift_out[0][m*32+7:m*32]^shift_out[3][m*32+15:m*32+8]^shift_out[2][m*32+23:m*32+16]^shift_out[1][m*32+31:m*32+24],
          shift_out[3][m*32+7:m*32]^shift_out[2][m*32+15:m*32+8]^shift_out[1][m*32+23:m*32+16]^shift_out[0][m*32+31:m*32+24]};
    end
  endgenerate

endmodule
