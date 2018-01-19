`timescale 1ns / 1ns
module Key_Expansion_tb;
reg clk;
reg rst_n;
reg [255:0] CipherKey; //Ciphter Key provided by the host; start from lower bits.
reg k_ready;  //CiphterKey data is ready.
reg [3:0] Nk;    //Nk in the document.
reg [3:0] Addr;  //address of required expanded key.
wire [127:0] ex_key;  //required expanded key with valid bit.

initial begin
	clk <= 0;
	rst_n <= 0;
	CipherKey <= 256'h0;
	k_ready <=0;
	Nk <= 4'h0;
	Addr <= 4'h0;

	#10
		rst_n <= 1;
	#20
		CipherKey <= 256'h00000000000000000000000000000000FFEEDDBBCCAA99887766554433221100;
	#30
		k_ready <= 1;
	#40
		Nk <= 4'h3;
	#50
		Addr <= 4'h1;
	#100
		Addr <= 4'h2;

end

Key_Expansion tb(
.clk(clk),
.rst_n(rst_n),
.CipherKey(CipherKey), //Ciphter Key provided by the host, start from lower bits.
.k_ready(k_ready),  //CiphterKey data is ready.
.Nk(Nk),    //Nk in the document.
.Addr(Addr),  //address of required expanded key.
.ex_key(ex_key)  //required expanded key with valid bit.
  );

always
begin
	#10
		clk=~clk;
end
always @ (posedge clk) begin
  if(k_ready) begin
    k_ready <= 0;
    Nk <= 4'h0;
    CipherKey <= 256'h0;
  end
end

endmodule
