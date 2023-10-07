`timescale 1ns / 100ps

module tb_bram;
    
  // Parameters
  parameter RAM_WIDTH = 18;
  parameter RAM_DEPTH = 1024;

  // Inputs
  reg                                           clk;    //! Clock
  reg                                         reset;    //! Reset
  reg                                     i_run_log;    //! Start saving input data
  reg                                    i_read_log;    //! 
  reg  [RAM_WIDTH-1:0]             i_data_tx_to_mem;    //! data in [31:0]   
  reg  [clogb2(RAM_DEPTH-1)-1:0]  i_addr_log_to_mem;    //! read address [14:0]
  
  // Outputs
  wire [RAM_WIDTH-1:0]  o_data_log_from_mem;  //! data out [31:0]
  wire                  o_mem_full;           //! Memory full

  // Instantiate BRAM
  bram #(
    .RAM_WIDTH(RAM_WIDTH),
    .RAM_DEPTH(RAM_DEPTH)
  ) u_bram (
    .clk                  (clk),
    .reset                (reset),
    .i_run_log            (i_run_log),
    .i_read_log           (i_read_log),
    .i_data_tx_to_mem     (i_data_tx_to_mem),
    .i_addr_log_to_mem    (i_addr_log_to_mem),
    .o_data_log_from_mem  (o_data_log_from_mem),
    .o_mem_full           (o_mem_full)
  );

  // Clock generation
  always #1 clk = ~clk;

  // Write data to memory
  initial begin
    clk = 0;
    i_read_log = 0;
    i_run_log = 0;
    i_data_tx_to_mem = 0;
    i_addr_log_to_mem = 0;
    #1  reset = 1;
    #10 reset = 0;
    
    // Write data to memory
    #2 i_run_log = 1'b1;
    #2 i_run_log = 1'b0;
    //#2;
    repeat (RAM_DEPTH) begin
      #2 i_data_tx_to_mem = i_data_tx_to_mem + 1;
    end
    #2;
    if (o_mem_full) begin
      $display("Memory full");
      #2 i_addr_log_to_mem = 31;

      #2 i_read_log = 1'b1;
      #4;
      $display("Data read from memory: %d", o_data_log_from_mem);
      $display("Expected: %d", i_addr_log_to_mem);
      #2 i_addr_log_to_mem = 32;

      #2 i_read_log = 1'b1;
      #4;
      $display("Data read from memory: %d", o_data_log_from_mem);
      $display("Expected: %d", i_addr_log_to_mem);
      #2 i_addr_log_to_mem = 33;

      #2 i_read_log = 1'b1;
      #4;
      $display("Data read from memory: %d", o_data_log_from_mem);
      $display("Expected: %d", i_addr_log_to_mem);
      $finish;
    end else begin
      $display("Memory not full");
      $finish;
    end
  end

//  The following function calculates the address width based on specified RAM depth
// calcula cuantos bits de direccion hacen falta para direccionar la memoria
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction
endmodule