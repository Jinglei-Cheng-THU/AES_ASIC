`include "aes_sbox.v"
`timescale	1ns/100ps
module	KEY_GENERATOR(CLK,RST_,key,select,enable_,round_key);
	input						CLK;
	input						RST_;
	input[63:0]		key;
	input						select,enable_;
	output[63:0]		round_key;
	
	reg[63:0]			round_key,key_reg;
	reg[7:0]				RC;
	wire[31:0]			ksout;
	
	aes_sbox  		sb1(.a(round_key[39:32]), .d(ksout[7:0])),
					sb2(.a(round_key[47:40]),.d(ksout[15:8])),
					sb3(.a(round_key[55:48]),.d(ksout[23:16])),
					sb4(.a(round_key[63:56]),.d(ksout[31:24]));
	
	always @(posedge CLK or negedge RST_)
		begin
			if (~RST_)
				key_reg=64'h0;
			else
			 if (enable_==0)
			 	begin
					key_reg[31:0]={round_key[39:32],round_key[63:48],round_key[47:40]^RC}^round_key[31:0];
					key_reg[63:32]=round_key[63:32]^key_reg[31:0];
					//key_reg[95:64]=round_key[95:64]^key_reg[63:32];
					//key_reg[63:96]=round_key[63:96]^key_reg[95:64];
					
				end			
		end
	always @(select or key_reg or key)
		round_key=select?key_reg:key;
	
	always @(posedge CLK or negedge RST_)
		begin
			if (~RST_)
				RC<=8'h01;
			else
				begin
					if (enable_==0) RC<=(RC<<1)^{3'b0,{2{RC[7]}},1'b0,{2{RC[7]}}};//xtime(RC);
					else RC<=8'h01;
				end
	end
endmodule
