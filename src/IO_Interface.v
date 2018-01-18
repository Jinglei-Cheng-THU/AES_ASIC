module IO_Interface(
  input CLK,
  input RSTB,
  input [7:0]DIN,
  input [6:0]ADDR,
  input WR,
  input START,
  output OK,
  output [7:0]DOUT,
  //above are ports defined for the host
  input [127:0]Ciphertext   //Encrypted Data
  input Core_Full,    //Being 1 means Encrypt Core is already fully occupied and do not feed any more data.
  input c_ready,    //indicate Ciphertext is ready.
  output [127:0]Plain_text,
  output [3:0]Nr,   //number of encryption rounds, 10, 12, 14 for 128, 192, 256 keys seperately
  output t_ready,   //indicate Plain_text data is ready
  output t_reset,   //reset Encrypt Core
  output op,        //indicate operations, 0 for decryption and 1 for encryption
  //above are interactions with Encrypt Core.
  output [256:0]CipherKey,  //CipherKey, fill unused bits with 0.
  output [3:0]Nk_val, //value of Nk, 4 for 128 bits key, 6 for 192 and 8 for 256
  output k_ready,   //indicate CipherKey data is ready
  output k_reset,   //reset key expansion Core
  //above are interactions with key expansion core.
  output clk_slow   //divided slow clock
  );


endmodule
