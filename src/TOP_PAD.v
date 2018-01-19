`include "TOP.v"
module TOP_PAD(
  input CLK,
  input RSTB,
  input START,
  input WR,
  input [7:0]DIN,
  input [6:0]ADDR,
  output OK,
  output [7:0]DOUT
  );
  wire [7:0] _DIN;
  wire [7:0] _DOUT;
  wire [6:0] _ADDR;
  wire _CLK, _RSTB;
  wire _START, _WR, _OK;
  TOP top_core(.CLK(_CLK),.RSTB(_RSTB),.DIN(_DIN),.ADDR(_ADDR),.WR(_WR),
      .START(_START),.OK(_OK),.DOUT(_DOUT));

  PIW PCLK(.PAD(CLK),.C(_CLK));
  PIW PRSTB(.PAD(RSTB),.C(_RSTB));
  generate
    genvar i;
    for (i = 0; i < 8; i = i + 1)begin:gen_data_pin
      PIW PDIN(.PAD(DIN[i]),.C(_DIN[i]));
      PO16W PDOUT(.PAD(DOUT[i]),.I(_DOUT[i]));
    end
    for (i = 0; i < 7; i = i + 1)begin:gen_addr_pin
      PIW PDIN(.PAD(ADDR[i]),.C(_ADDR[i]));
    end
  endgenerate
  PIW PSTART(.PAD(START),.C(_START));
  PIW PWR(.PAD(WR),.C(_WR));
  PO16W POK(.PAD(OK),.I(_OK));

endmodule
