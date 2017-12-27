module Key_Expansion (
  input clk,
  input rst_n,
  input [255:0]CipherKey, //Ciphter Key provided by the host, start from lower bits.
  input k_ready,  //CiphterKey data is ready.
  input [3:0]Nk,    //Nk in the document.
  input [5:0]Addr,  //address of required expanded key.
  output [128:0]ex_key  //required expanded key with valid bit.
  );

endmodule // Key_Expansion
