`timescale 1ns / 100ps

module tb_top_convolver #(
    IMAGE_HEIGHT = 3,  // Image height with zero padding
    KERNEL_WIDTH = 3,
    NB_PIXEL = 8,
    NB_COEFF = 8,
    KERNEL_SIZE = KERNEL_WIDTH * KERNEL_WIDTH,
    NB_CONV = KERNEL_SIZE * NB_PIXEL,
    NB_DATA = 32
) ();
  reg clk;
  reg i_rst;

  wire [NB_DATA-1:0] o_axi_data;
  reg [NB_DATA-1:0] i_axi_data;
  always #1 clk = ~clk;
  reg i_valid;


  initial begin
    clk = 0;
    i_rst = 0;
    i_valid = 0;

    #2 i_rst = 1;
    #2 i_rst = 0;

    #2 i_axi_data = 32'hff000022;
    i_valid = 1;
    #2 i_valid = 0;

    #2 i_axi_data = 32'h77ff1133;
    i_valid = 1;
    #2 i_valid = 0;

    #2 i_axi_data = 32'h0011ff00;
    i_valid = 1;
    #2 i_valid = 0;

    #2;

    // se cargo la primera columna, el primer subframe12
    // se deberia obtener 2 pixeles validos del convolver 2y3
    $display("resultado, puede haber error de truncamiento y por punto fijo");
    $display("conv0 = %h | expected = 00", o_axi_data[7:0]);
    $display("conv1 = %h | expected = 33", o_axi_data[15:8]);
    $display("conv2 = %h | expected = 11", o_axi_data[23:16]);
    $display("conv3 = %h | expected = ff", o_axi_data[31:24]);

    #10;

    #2 i_axi_data = 32'h11111111;
    i_valid = 1;
    #2 i_valid = 0;

    #4 i_axi_data = 32'h22445500;
    i_valid = 1;
    #2 i_valid = 0;

    #2 i_axi_data = 32'h00000000;
    i_valid = 1;
    #2 i_valid = 0;

    #2;

    // se cargo la segunda columna, el segundo subframe12 y el primero de 18
    // se deberian obtener 4 pixeles validos 
    $display("resultado, puede haber error de truncamiento y por punto fijo");
    $display("conv0 = %h | expected = 77", o_axi_data[7:0]);
    $display("conv1 = %h | expected = 00", o_axi_data[15:8]);
    $display("conv2 = %h | expected = 55", o_axi_data[23:16]);
    $display("conv3 = %h | expected = 44", o_axi_data[31:24]);

    #40;
    $finish;
  end

  top_convolver #(
      .IMAGE_HEIGHT(IMAGE_HEIGHT),  // Image height with zero padding
      .KERNEL_WIDTH(KERNEL_WIDTH),
      .NB_PIXEL(NB_PIXEL),
      .NB_COEFF(NB_COEFF),
      .KERNEL_SIZE(KERNEL_SIZE),
      .NB_CONV(NB_CONV),
      .NB_DATA(NB_DATA)
  ) u_top_convolver (
      .i_clk     (clk),
      .i_reset   (i_rst),
      .i_axi_data(i_axi_data),
      .i_valid   (i_valid),
      .o_axi_data(o_axi_data)

  );
endmodule

