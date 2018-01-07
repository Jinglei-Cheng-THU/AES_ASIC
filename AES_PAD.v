`include "top.v"
module TOP_PAD( CLK, RST_, CMD, DIN, READY, OK, DOUT );
  input [1:0] CMD;
  input [7:0] DIN;
  output [7:0] DOUT;
  input CLK, RST_;
  output READY, OK;

  wire[1:0] _CMD;
  wire[7:0] _DIN;
  wire[7:0] _DOUT;
  wire _CLK, _RST_;
  wire _READY, _OK;

 TOP chip_core( _CLK, _RST_, _CMD, _DIN, _READY, _OK, _DOUT );

 PIW    PCLK(.PAD(CLK),.C(_CLK));
 PIW    PRST_(.PAD(RST_),.C(_RST_));
 PIW    PCMD0(.PAD(CMD[0]),.C(_CMD[0])),PCMD1(.PAD(CMD[1]),.C(_CMD[1]));
 PIW    PDIN0(.PAD(DIN[0]),.C(_DIN[0])),
        PDIN1(.PAD(DIN[1]),.C(_DIN[1])),
        PDIN2(.PAD(DIN[2]),.C(_DIN[2])),
        PDIN3(.PAD(DIN[3]),.C(_DIN[3])),
        PDIN4(.PAD(DIN[4]),.C(_DIN[4])),
        PDIN5(.PAD(DIN[5]),.C(_DIN[5])),
        PDIN6(.PAD(DIN[6]),.C(_DIN[6])),
        PDIN7(.PAD(DIN[7]),.C(_DIN[7]));
 PO16W 	PREADY(.PAD(READY),.I(_READY));
 PO16W 	POK(.PAD(OK),.I(_OK));
 PO16W 	PDOUT0(.PAD(DOUT[0]),.I(_DOUT[0])),
        PDOUT1(.PAD(DOUT[1]),.I(_DOUT[1])),
        PDOUT2(.PAD(DOUT[2]),.I(_DOUT[2])),
        PDOUT3(.PAD(DOUT[3]),.I(_DOUT[3])),
        PDOUT4(.PAD(DOUT[4]),.I(_DOUT[4])),
        PDOUT5(.PAD(DOUT[5]),.I(_DOUT[5])),
        PDOUT6(.PAD(DOUT[6]),.I(_DOUT[6])),
        PDOUT7(.PAD(DOUT[7]),.I(_DOUT[7]));
endmodule
