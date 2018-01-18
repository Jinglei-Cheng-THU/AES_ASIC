module Key_Expansion (
  input wire clk,
  input wire rst_n,
  input wire [255:0] CipherKey, //Ciphter Key provided by the host, start from lower bits.
  input wire k_ready,  //CiphterKey data is ready.
  input wire [3:0] Nk,    //Nk in the document.
  input wire [3:0] Addr,  //address of required expanded key.
  output wire [127:0] ex_key  //required expanded key with valid bit.
  );

endmodule // Key_Expansion
