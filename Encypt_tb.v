`timescale 1ns / 1ns
module tb;
reg [127:0]key[0:10];
reg [3:0]Nr;
reg clk;
reg rst_n;
reg t_ready;
reg [127:0] plaintext;
reg op;
wire [3:0]Addr;
wire Core_Busy;
wire c_ready;
wire [127:0]Ciphertext;
wire [128:0]Key;
initial fork
  key[0]<=128'h112233445566778899AABBCCDDEEFF00;
  //key[0] <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
  key[1]<=128'h383450856D52270DF4F89CC1291663C1;
  key[2]<=128'h7DCF2820109D0F2DE46593ECCD73F02D;
  key[3]<=128'hF643F09DE6DEFFB002BB6C5CCFC89C71;
  key[4]<=128'h169D5317F043ACA7F2F8C0FB3D305C8A;
  key[5]<=128'h02D72D30F2948197006C416C3D5C1DE6;
  key[6]<=128'h6873A3179AE722809A8B63ECA7D77E0A;
  key[7]<=128'h2680C44BBC67E6CB26EC8527813BFB2D;
  key[8]<=128'h448F1C47F8E8FA8CDE047FAB5F3F8486;
  key[9]<=128'h2AD05888D238A2040C3CDDAF53035929;
  key[10]<=128'h671bfd65b5235f61b91f82ceea1cdbe7;
  clk <= 0;
  rst_n <= 1;
  op <= 0;
  #150 op <= 1;
  #150 plaintext <= 128'h1234567890ABCDEF01234567899ABCDE;
  plaintext <= 128'h3C84F58C1E000953A415C5B1352F9892;
  Nr <= 10;
  t_ready <= 1;
  #20 t_ready <= 0;
  #170 t_ready <= 1;
  #200 t_ready <= 0;
  #2 rst_n <= 0;
  #4 rst_n <= 1;
  clk <= 1;
  forever #5 clk = ~clk;
join
wire [127:0]rev_key[0:10];
wire [127:0]rev_plain;
generate
  genvar i,j;
  for (i = 0; i < 16; i = i + 1)begin:reverse
    for (j = 0; j < 11; j = j + 1)begin:reversej
      assign rev_key[j][127-8*i:127-8*i-7] = key[j][i*8+7:i*8];
    end
    assign rev_plain[127-8*i:127-8*i-7] = plaintext[i*8+7:i*8];
  end
endgenerate
assign Key = {1'b1,rev_key[Addr]};

Encrypt_Core EC(clk,rst_n,t_ready,rev_plain,Nr,Key,op,Addr,Core_Busy,c_ready,Ciphertext);
endmodule
