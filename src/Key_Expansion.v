//Author: Jinglei Cheng from THU

`include "aes_sbox.v"
module Key_Expansion (
  input wire clk,
  input wire rst_n,
  input wire [255:0] CipherKey, //Ciphter Key provided by the host, start from lower bits.
  input wire k_ready,  //CiphterKey data is ready.
  input wire [3:0] Nk,    //Nk0 in the document.
  input wire [3:0] Addr,  //address of required expanded key.
  output wire [128:0] ex_key  //required expanded key with valid bit.
  );
  //----------------------------------------------------------------
  // Parameters.
  //----------------------------------------------------------------

  localparam AES_128_BIT_KEY = 3'h3;
  localparam AES_192_BIT_KEY = 3'h5;
  localparam AES_256_BIT_KEY = 3'h7;

  localparam AES_128_NUM_ROUNDS = 4'ha;
  localparam AES_192_NUM_ROUNDS = 4'hc;
  localparam AES_256_NUM_ROUNDS = 4'he;

  localparam CTRL_IDLE     = 3'h0;
  localparam CTRL_INIT     = 3'h1;
  localparam CTRL_GENERATE = 3'h2;
  localparam CTRL_DONE     = 3'h3;

  //----------------------------------------------------------------
  // Registers.
  //----------------------------------------------------------------
  reg [128 : 0] key_mem [0 : 14];
  reg [128 : 0] key_mem_new;
  reg           key_mem_we;

  reg [127 : 0] prev_key0_reg;
  reg [127 : 0] prev_key0_new;
  reg           prev_key0_we;

  reg [127 : 0] prev_key1_reg;
  reg [127 : 0] prev_key1_new;
  reg           prev_key1_we;

  reg [3 : 0] round_ctr_reg;
  reg [3 : 0] round_ctr_new;
  reg         round_ctr_rst;
  reg         round_ctr_inc;
  reg         round_ctr_we;

  reg [2 : 0] key_mem_ctrl_reg;
  reg [2 : 0] key_mem_ctrl_new;
  reg         key_mem_ctrl_we;

  reg         ready_reg;
  reg         ready_new;
  reg         ready_we;

  reg [7 : 0] rcon_reg;
  reg [7 : 0] rcon_new;
  reg         rcon_we;
  reg         rcon_set;
  reg         rcon_next;
  reg [7 : 0] tmp_rcon;

  reg [31 : 0]  tmp_sboxw;
  reg [31 : 0]  tmp_sboxw_192;
  reg           round_key_update;
  reg [3 : 0]   num_rounds;
  reg [128 : 0] tmp_ex_key;

  wire [31 : 0] sboxw;
  wire [31 : 0] sboxw_192;
  wire [31 : 0] new_sboxw;
  wire [31 : 0] new_sboxw_192;
  wire ready;

  reg [255 : 0] CipherKey0;
  reg [3 : 0] Nk0;
  reg [63 : 0] mem1, mem2, mem3;
  //----------------------------------------------------------------
  // Concurrent assignments for ports.
  //----------------------------------------------------------------
  assign ex_key  = tmp_ex_key;
  assign ready      = ready_reg;
  assign sboxw      = tmp_sboxw;
  assign sboxw_192  = tmp_sboxw_192;

  aes_sbox sb1(.a(sboxw[7 : 0]),.d(new_sboxw[7 : 0])),
           sb2(.a(sboxw[15 : 8]),.d(new_sboxw[15 : 8])),
           sb3(.a(sboxw[23 : 16]),.d(new_sboxw[23 : 16])),
           sb4(.a(sboxw[31 : 24]),.d(new_sboxw[31 : 24]));
  aes_sbox sb5(.a(sboxw_192[7 : 0]),.d(new_sboxw_192[7 : 0])),
           sb6(.a(sboxw_192[15 : 8]),.d(new_sboxw_192[15 : 8])),
           sb7(.a(sboxw_192[23 : 16]),.d(new_sboxw_192[23 : 16])),
           sb8(.a(sboxw_192[31 : 24]),.d(new_sboxw_192[31 : 24]));

  always @ (posedge k_ready)
    begin: initialization
  CipherKey0 = CipherKey;
  Nk0 = Nk;
    end

  always @ (posedge clk or negedge rst_n)
    begin: reg_update
      integer i;

      if (!rst_n)
        begin
          for (i = 0 ; i < 15 ; i = i + 1)
            key_mem [i] <= 129'h0;

          rcon_reg         <= 8'h0;
    tmp_rcon         <= 8'h0;
          ready_reg        <= 1'b0;
          round_ctr_reg    <= 4'h0;
          mem1 = 64'h0;
          mem2 = 64'h0;
          mem3 = 64'h0;
          key_mem_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (round_ctr_we)
            round_ctr_reg <= round_ctr_new;

          if (ready_we)
            ready_reg <= ready_new;

          if (rcon_we)
            rcon_reg <= rcon_new;

          if (key_mem_we)
            key_mem[round_ctr_reg] <= key_mem_new;

          if (prev_key0_we)
            prev_key0_reg <= prev_key0_new;

          if (prev_key1_we)
            prev_key1_reg <= prev_key1_new;

          if (key_mem_ctrl_we)
            key_mem_ctrl_reg <= key_mem_ctrl_new;
        end
    end // reg_update
  //----------------------------------------------------------------
  // key_mem_read
  //
  // Combinational read port for the key memory.
  //----------------------------------------------------------------
  always @*
    begin : key_mem_read
      tmp_ex_key = key_mem[Addr];
    end // key_mem_read

  //----------------------------------------------------------------
  // round_key_gen
  //
  // The round key generator logic for AES-128 and AES-256.
  //----------------------------------------------------------------
  always @*
    begin:round_key_gen
      reg [31 : 0] w0, w1, w2, w3, w4, w5, w6, w7;
      reg [31 : 0] f0, f1, f2, f3, f4, f5;
      reg [31 : 0] k0, k1, k2, k3, k4, k5;
      reg [31 : 0] rconw, rotstw, tw, trw, rotstw_192, trw_192;

      // Default assignments.
      key_mem_new   = 129'h0;
      key_mem_we    = 1'b0;
      prev_key0_new = 128'h0;
      prev_key0_we  = 1'b0;
      prev_key1_new = 128'h0;
      prev_key1_we  = 1'b0;

      mem1 = prev_key0_reg[127:64];
      mem2 = prev_key0_reg[63:0];
      mem3 = prev_key1_reg[127:64];

      k0 = 32'h0;
      k1 = 32'h0;
      k2 = 32'h0;
      k3 = 32'h0;
      k4 = 32'h0;
      k5 = 32'h0;

      rcon_set   = 1'b1;
      rcon_next  = 1'b0;

      // Extract words and calculate intermediate values.
      // Perform rotation of sbox word etc.
      w0 = prev_key0_reg[127 : 096];
      w1 = prev_key0_reg[095 : 064];
      w2 = prev_key0_reg[063 : 032];
      w3 = prev_key0_reg[031 : 000];

      w4 = prev_key1_reg[127 : 096];
      w5 = prev_key1_reg[095 : 064];
      w6 = prev_key1_reg[063 : 032];
      w7 = prev_key1_reg[031 : 000];

      f0 = mem1[63 : 32];
      f1 = mem1[31 : 0];
      f2 = mem2[63 : 32];
      f3 = mem2[31 : 0];
      f4 = mem3[63 : 32];
      f5 = mem3[31 : 0];

      rconw = {rcon_reg, 24'h0};
      tmp_sboxw = w7;
      tmp_sboxw_192 = f5;
      rotstw = {new_sboxw[23 : 00], new_sboxw[31 : 24]};
      rotstw_192 = {new_sboxw_192[23 : 00], new_sboxw_192[31:24]};
      trw = rotstw ^ rconw;
      trw_192 = rotstw_192 ^ rconw;
      tw = new_sboxw;

      // Generate the specific round keys.
      if (round_key_update)
        begin
          rcon_set   = 1'b0;
          key_mem_we = 1'b1;
          case (Nk0)
            AES_128_BIT_KEY:
              begin
                if (round_ctr_reg == 0)
                  begin
                    key_mem_new   = {1'b1, CipherKey0[127 : 0]};
                    prev_key1_new = CipherKey0[127 : 0];
                    prev_key1_we  = 1'b1;
                    rcon_next     = 1'b1;
                  end
                else
                  begin
                    k0 = w4 ^ trw;
                    k1 = w5 ^ w4 ^ trw;
                    k2 = w6 ^ w5 ^ w4 ^ trw;
                    k3 = w7 ^ w6 ^ w5 ^ w4 ^ trw;

                    key_mem_new   = {1'b1, k0, k1, k2, k3};
                    prev_key1_new = {k0, k1, k2, k3};
                    prev_key1_we  = 1'b1;
                    rcon_next     = 1'b1;
                  end
              end

            AES_256_BIT_KEY:
              begin
                if (round_ctr_reg == 0)
                  begin
                    key_mem_new   = {1'b1, CipherKey0[255 : 128]};
                    prev_key0_new = CipherKey0[255 : 128];
                    prev_key0_we  = 1'b1;
                  end
                else if (round_ctr_reg == 1)
                  begin
                    key_mem_new   = {1'b1, CipherKey0[127 : 0]};
                    prev_key1_new = CipherKey0[127 : 0];
                    prev_key1_we  = 1'b1;
                    rcon_next     = 1'b1;
                  end
                else
                  begin
                    if (round_ctr_reg[0] == 0)
                      begin
                        k0 = w0 ^ trw;
                        k1 = w1 ^ w0 ^ trw;
                        k2 = w2 ^ w1 ^ w0 ^ trw;
                        k3 = w3 ^ w2 ^ w1 ^ w0 ^ trw;
                      end
                    else
                      begin
                        k0 = w0 ^ tw;
                        k1 = w1 ^ w0 ^ tw;
                        k2 = w2 ^ w1 ^ w0 ^ tw;
                        k3 = w3 ^ w2 ^ w1 ^ w0 ^ tw;
                        rcon_next = 1'b1;
                      end

                    // Store the generated round keys.
                    key_mem_new   = {1'b1, k0, k1, k2, k3};
                    prev_key1_new = {k0, k1, k2, k3};
                    prev_key1_we  = 1'b1;
                    prev_key0_new = prev_key1_reg;
                    prev_key0_we  = 1'b1;
                  end
              end

            AES_192_BIT_KEY:
              begin
    if (round_ctr_reg == 0)
        begin
      mem1 = CipherKey0[191 : 128];
      mem2 = CipherKey0[127 : 64];
      mem3 = CipherKey0[63 : 0];
      key_mem_new = {1'b1, mem1, mem2};
      prev_key0_new = {mem1, mem2};
      prev_key0_we = 1'b1;
      prev_key1_new = {mem3, 64'h0};
      prev_key1_we = 1'b1;
            rcon_next = 1'b1;
        end
    else if (round_ctr_reg%3 == 0)
        begin
      key_mem_new = {1'b1, mem1, mem2};
      prev_key0_new = {mem1, mem2};
      prev_key0_we = 1'b1;
        end
    else if (round_ctr_reg%3 == 1)
        begin
      k0 = f0 ^ trw_192;
      k1 = f0 ^ f1 ^ trw_192;
      k2 = f0 ^ f1 ^ f2 ^ trw_192;
      k3 = f0 ^ f1 ^ f2 ^ f3 ^ trw_192;
      k4 = f0 ^ f1 ^ f2 ^ f3 ^ f4 ^ trw_192;
      k5 = f0 ^ f1 ^ f2 ^ f3 ^ f4 ^ f5 ^ trw_192;
      key_mem_new = {1'b1, mem3, k0, k1};
      prev_key0_new = {k0, k1, k2, k3};
      prev_key1_new = {k4, k5, 64'h0};
      prev_key0_we = 1'b1;
      prev_key1_we = 1'b1;
      rcon_next = 1'b1;
        end
    else if (round_ctr_reg%3 == 2)
        begin
      k0 = f0 ^ trw_192;
      k1 = f0 ^ f1 ^ trw_192;
      k2 = f0 ^ f1 ^ f2 ^ trw_192;
      k3 = f0 ^ f1 ^ f2 ^ f3 ^ trw_192;
      k4 = f0 ^ f1 ^ f2 ^ f3 ^ f4 ^ trw_192;
      k5 = f0 ^ f1 ^ f2 ^ f3 ^ f4 ^ f5 ^ trw_192;
      key_mem_new = {1'b1, mem2, mem3};
      prev_key0_new = {k0, k1, k2, k3};
      prev_key1_new = {k4, k5, 64'h0};
      prev_key0_we = 1'b1;
      prev_key1_we = 1'b1;
      rcon_next = 1'b1;
        end
              end

            default:
              begin
              end
          endcase // case (Nk0)
        end
    end // round_key_gen

  //----------------------------------------------------------------
  // rcon_logic
  //
  // Caclulates the rcon value for the different key expansion
  // iterations.
  //----------------------------------------------------------------
  always @*
    begin : rcon_logic
      rcon_new = 8'h00;
      rcon_we  = 1'b0;

      tmp_rcon = {rcon_reg[6 : 0], 1'b0} ^ (8'h1b & {8{rcon_reg[7]}});

      if (rcon_set)
        begin
          rcon_new = 8'h8d;
          rcon_we  = 1'b1;
        end

      if (rcon_next)
        begin
          rcon_new = tmp_rcon[7 : 0];
          rcon_we  = 1'b1;
        end
    end

  //----------------------------------------------------------------
  // round_ctr
  //
  // The round counter logic with increase and reset.
  //----------------------------------------------------------------
  always @*
    begin : round_ctr
      round_ctr_new = 4'h0;
      round_ctr_we  = 1'b0;

      if (round_ctr_rst)
        begin
          round_ctr_new = 4'h0;
          round_ctr_we  = 1'b1;
        end

      else if (round_ctr_inc)
        begin
          round_ctr_new = round_ctr_reg + 1'b1;
          round_ctr_we  = 1'b1;
        end
    end

  //----------------------------------------------------------------
  // num_rounds_logic
  //
  // Logic to select the number of rounds to generate keys for
  //----------------------------------------------------------------
  always @*
    begin : num_rounds_logic
      num_rounds = 4'h0;

      case (Nk0)
        AES_128_BIT_KEY:
          begin
            num_rounds = AES_128_NUM_ROUNDS;
          end

        AES_256_BIT_KEY:
          begin
            num_rounds = AES_256_NUM_ROUNDS;
          end

        AES_192_BIT_KEY:
          begin
            num_rounds = AES_192_NUM_ROUNDS;
          end

        default:
          begin
          end
      endcase // case (Nk0)
    end

  //----------------------------------------------------------------
  // key_mem_ctrl
  //
  //
  // The FSM that controls the round key generation.
  //----------------------------------------------------------------
  always @*
    begin:key_mem_ctrl
      // Default assignments.
      ready_new        = 1'b0;
      ready_we         = 1'b0;
      round_key_update = 1'b0;
      round_ctr_rst    = 1'b0;
      round_ctr_inc    = 1'b0;
      key_mem_ctrl_new = CTRL_IDLE;
      key_mem_ctrl_we  = 1'b0;

      case(key_mem_ctrl_reg)
        CTRL_IDLE:
          begin
            if (k_ready)
              begin
                ready_new        = 1'b0;
                ready_we         = 1'b1;
                key_mem_ctrl_new = CTRL_INIT;
                key_mem_ctrl_we  = 1'b1;
              end
          end

        CTRL_INIT:
          begin
            round_ctr_rst    = 1'b1;
            key_mem_ctrl_new = CTRL_GENERATE;
            key_mem_ctrl_we  = 1'b1;
          end

        CTRL_GENERATE:
          begin
            round_ctr_inc    = 1'b1;
            round_key_update = 1'b1;
            if (round_ctr_reg == num_rounds)
              begin
                key_mem_ctrl_new = CTRL_DONE;
                key_mem_ctrl_we  = 1'b1;
              end
          end

        CTRL_DONE:
          begin
            ready_new        = 1'b1;
            ready_we         = 1'b1;
            key_mem_ctrl_new = CTRL_IDLE;
            key_mem_ctrl_we  = 1'b1;
          end

        default:
          begin
          end
      endcase // case (key_mem_ctrl_reg)

    end // key_mem_ctrl


endmodule // Key_Expansion
