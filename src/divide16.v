module divide16(CLK,clk_slow); 
input CLK; 
output clk_slow; 
reg clk_slow; 
reg [2:0]c; 
initial 
begin 
c<=3'd0; 
clk_slow<=0;  
end
always @(posedge CLK)
begin
if(c==3'd1)
begin
clk_slow<=~clk_slow;
c<=3'd0;
end
else c<=c+3'd1;
end
endmodule
