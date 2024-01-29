`timescale 1ns / 100ps

module tb_bram_control;

  // Parameters
  parameter RAM_WIDTH = 8;  // Specify RAM data width
  parameter RAM_DEPTH = (100);  // 65536 Specify RAM depth (number of entries)
  parameter IMAGE_WIDTH = 10;
  parameter IMAGE_HEIGHT = 10;
  parameter INIT_FILE    = "C:/Users/marco/OneDrive/Escritorio/procom/program_logic/src/verilog/ram/img.txt";
  //parameter INIT_FILE    = "";
  parameter KERNEL_WIDTH = 3;


  // Inputs
  reg clk;  //! Clock
  reg reset;  //! Reset
  reg i_start_loading;
  reg i_read_for_processing;
  reg [RAM_WIDTH-1:0] i_data_to_mem;
  reg [clogb2(RAM_DEPTH-1)-1:0] i_addr_log_to_mem;
  reg i_valid_get_frame;
  // Outputs
  wire [RAM_WIDTH-1:0] o_data_from_mem;
  wire o_is_frame_ready;
  wire o_valid_data_to_conv;
  wire [RAM_WIDTH-1:0] o_to_conv[KERNEL_WIDTH-1:0];  //! data to convolver 3 x 8 bits

  // Clock generation
  always #1 clk = ~clk;

  // Write data to memory
  initial begin
    clk = 0;
    i_read_for_processing = 0;
    i_start_loading = 0;
    i_data_to_mem = 1;
    i_addr_log_to_mem = 0;
    i_valid_get_frame = 0;

    #1 reset = 1;
    #10 reset = 0;

    // Write data to memory  FUNCIONANDO !!
    //#2 i_start_loading = 1'b1;
    //#2 i_start_loading = 1'b0;

    // Send data to convolver for processing  FUNCIONANDO !!
    #1 u_bram_control.state_reg = u_bram_control.PROCESS_FRAME;

    #2 i_read_for_processing = 1'b1;

    #1500;


    $finish;

    //#2;
    /*
    repeat (RAM_DEPTH) begin
      #2 i_data_to_mem = i_data_to_mem + 1;
    end
    #2;
    if (o_is_frame_ready) begin
      $display("Memory full");
      #2 i_addr_log_to_mem = 31;

      #2 i_read_for_processing = 1'b1;
      #4;
      $display("Data read from memory: %d", o_data_from_mem);
      $display("Expected: %d", i_addr_log_to_mem);
      #2 i_addr_log_to_mem = 32;

      #2 i_read_for_processing = 1'b1;
      #4;
      $display("Data read from memory: %d", o_data_from_mem);
      $display("Expected: %d", i_addr_log_to_mem);
      #2 i_addr_log_to_mem = 33;

      #2 i_read_for_processing = 1'b1;
      #4;
      $display("Data read from memory: %d", o_data_from_mem);
      $display("Expected: %d", i_addr_log_to_mem);
      $finish;
    end else begin
      $display("Memory not full");
      $finish;
      */

  end



  // Instantiate BRAM
  bram_control #(
      .RAM_WIDTH(RAM_WIDTH),
      .RAM_DEPTH(RAM_DEPTH),
      .INIT_FILE(INIT_FILE),
      .KERNEL_WIDTH(KERNEL_WIDTH),
      .IMAGE_WIDTH(IMAGE_WIDTH),
      .IMAGE_HEIGHT(IMAGE_HEIGHT)
  ) u_bram_control (
      .clk                  (clk),
      .reset                (reset),
      .i_start_loading      (i_start_loading),
      .i_valid_get_frame    (i_valid_get_frame),
      .i_read_for_processing(i_read_for_processing),
      .o_valid_data_to_conv (o_valid_data_to_conv),
      .i_data_to_mem        (i_data_to_mem),
      .o_data_from_mem      (o_data_from_mem),
      .o_is_frame_ready     (o_is_frame_ready),
      .o_to_conv0           (o_to_conv[0]),
      .o_to_conv1           (o_to_conv[1]),
      .o_to_conv2           (o_to_conv[2])
  );

  //  The following function calculates the address width based on specified RAM depth
  // calcula cuantos bits de direccion hacen falta para direccionar la memoria
  function integer clogb2;
    input integer depth;
    for (clogb2 = 0; depth > 0; clogb2 = clogb2 + 1) depth = depth >> 1;
  endfunction

endmodule

