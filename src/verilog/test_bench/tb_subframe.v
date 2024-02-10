`timescale 1ns / 100ps
module tb_subframe #(
    IMAGE_HEIGHT = 3,  // Image height with zero padding
    KERNEL_WITDH = 3,
    NB_CONV = 72,
    NB_PIXEL = 8,
    NB_DATA = 32
) ();
  reg i_clk;
  reg i_reset;
  reg [NB_DATA-1:0] i_axi_data;  //data from ublaze
  reg i_valid;

  initial begin
    i_clk   = 0;
    i_reset = 0;
    i_valid = 0;

    #2 i_reset = 1;
    #2 i_reset = 0;

    #2 i_axi_data = 32'hff000000;
    i_valid = 1;
    #2 i_valid = 0;

    #2 i_axi_data = 32'h01ff0000;
    i_valid = 1;
    #2 i_valid = 0;

    #2 i_axi_data = 32'h0200ff00;
    i_valid = 1;
    #2 i_valid = 0;

    #2 i_axi_data = 32'h0300ffff;
    i_valid = 1;
    #2 i_valid = 0;

    #2 i_axi_data = 32'h04000000;
    i_valid = 1;
    #2 i_valid = 0;

    #2 i_axi_data = 32'h00000000;
    i_valid = 1;
    #2 i_valid = 0;

    #2 i_axi_data = 32'h11111111;
    i_valid = 1;
    #2 i_valid = 0;
    #40;
    $finish;
  end

  always #1 i_clk = ~i_clk;

  wire [NB_CONV-1:0] o_conv0;
  wire [NB_CONV-1:0] o_conv1;
  wire [NB_CONV-1:0] o_conv2;
  wire [NB_CONV-1:0] o_conv3;

  subframe #(
      .IMAGE_HEIGHT(IMAGE_HEIGHT),  // Image height with zero padding
      .KERNEL_WITDH(KERNEL_WITDH),
      .NB_PIXEL    (NB_PIXEL),
      .NB_DATA     (NB_DATA)
  ) u_subframe (
      .i_clk     (i_clk),
      .i_reset   (i_reset),
      .i_axi_data(i_axi_data),
      .i_valid   (i_valid),
      .o_conv0   (o_conv0),
      .o_conv1   (o_conv1),
      .o_conv2   (o_conv2),
      .o_conv3   (o_conv3)
  );


endmodule

