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


  reg clk;  
  reg reset;

  reg i_load_valid;
  reg [RAM_WIDTH-1:0] i_data_to_mem;
  reg i_read_valid;
  wire [RAM_WIDTH-1:0] o_data_from_mem;

  reg i_load_valid_2;
  reg [RAM_WIDTH-1:0] i_data_to_mem_2;
  reg i_read_valid_2;
  wire [RAM_WIDTH-1:0] o_data_from_mem_2;

  integer i;

  // Clock generation
  always #1 clk = ~clk;

  initial begin
    clk = 0;
    i_read_valid = 0;
    i_load_valid = 0;
    i_data_to_mem = 0;

    i_read_valid_2 = 0;
    i_load_valid_2 = 0;
    i_data_to_mem_2 = 0;

    #1 reset = 1;
    #10 reset = 0;

    // Write data to memory

    for (i = 0; i < 100; i = i + 1) begin
      #2 i_load_valid_2 = 1'b1;
      #2 i_load_valid_2 = 1'b0;
      #2 i_data_to_mem_2 = i_data_to_mem_2 + 1;
      
      #2 i_load_valid = 1'b1;
      #2 i_load_valid = 1'b0;
      #2 i_data_to_mem = i_data_to_mem + 1;
    end

    // Request data for processing

    // discard first read value (repeated 0)
    #2 i_read_valid = 1'b1;
    #2 i_read_valid = 1'b0;

    for (i = 0; i < 300-60; i = i + 1) begin
      #2 i_read_valid = 1'b1;
      #2 i_read_valid = 1'b0;
      // $display("Data read from memory: %d", o_data_from_mem);
    end

     // Get processed frame
     for (i = 0; i < 100; i = i + 1) begin
      #2 i_read_valid_2 = 1'b1;
      #2 i_read_valid_2 = 1'b0;
      $display("Data read from memory: %d", o_data_from_mem_2);
    end

    #100;


    $finish;
  end

  while (@posedge clk) begin
  
  end

  // Instantiate BRAM for frame to process
  bram_control #(
      .RAM_WIDTH(RAM_WIDTH),
      .RAM_DEPTH(RAM_DEPTH),
      .INIT_FILE(INIT_FILE),
      .KERNEL_WIDTH(KERNEL_WIDTH),
      .IMAGE_WIDTH(IMAGE_WIDTH),
      .IMAGE_HEIGHT(IMAGE_HEIGHT),
      .TO_PROCESS(1)
  ) u_bram_control (
      .clk              (clk),
      .reset            (reset),
      .i_load_valid     (i_load_valid),
      .i_data_to_mem    (i_data_to_mem),
      .i_read_valid     (i_read_valid),
      .o_data_from_mem  (o_data_from_mem)
  );

  // Instantiate BRAM for processed frame
 bram_control #(
     .RAM_WIDTH(RAM_WIDTH),
     .RAM_DEPTH(RAM_DEPTH),
     .INIT_FILE(INIT_FILE),
     .KERNEL_WIDTH(KERNEL_WIDTH),
     .IMAGE_WIDTH(IMAGE_WIDTH),
     .IMAGE_HEIGHT(IMAGE_HEIGHT),
     .TO_PROCESS(0)
 ) u_bram_control_2 (
     .clk              (clk),
     .reset            (reset),
     .i_load_valid     (i_load_valid_2),
     .i_data_to_mem    (i_data_to_mem_2),
     .i_read_valid     (i_read_valid_2),
     .o_data_from_mem  (o_data_from_mem_2)
 );

  //  The following function calculates the address width based on specified RAM depth
  // calcula cuantos bits de direccion hacen falta para direccionar la memoria
  function integer clogb2;
    input integer depth;
    for (clogb2 = 0; depth > 0; clogb2 = clogb2 + 1) depth = depth >> 1;
  endfunction

endmodule

