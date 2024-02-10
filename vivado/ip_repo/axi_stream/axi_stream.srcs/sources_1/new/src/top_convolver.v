module top_convolver #(
    IMAGE_HEIGHT = 200,  // Image height with zero padding
    KERNEL_WIDTH = 3,
    NB_PIXEL = 8,
    NB_COEFF = 8,
    KERNEL_SIZE = KERNEL_WIDTH * KERNEL_WIDTH,
    NB_CONV = KERNEL_SIZE * NB_PIXEL,
    NB_DATA = 32
) (
    input                i_clk,
    input                i_reset,
    input  [NB_DATA-1:0] i_axi_data,
    input                i_valid,
    // input  [1:0]         i_kernel_sel,
    output [NB_DATA-1:0] o_axi_data
);


  // KERNEL DEFINITION
  wire signed [NB_COEFF*3-1:0] kernel[KERNEL_WIDTH-1:0];

  wire signed [NB_COEFF*3-1:0] kernel_identidad[KERNEL_WIDTH-1:0];
  assign kernel_identidad[0] = {8'b0, 8'b0, 8'b0};
  assign kernel_identidad[1] = {8'b0, 8'b01111111, 8'b0};
  assign kernel_identidad[2] = {8'b0, 8'b0, 8'b0};

  genvar i;
  generate
      for (i = 0; i < KERNEL_WIDTH; i = i + 1) begin
        assign kernel[i] = kernel_identidad[i];
        // assign kernel[i] = i_kernel_sel == 2'b00 ? kernel_identidad[i] :
        //    i_kernel_sel == 2'b01 ? kernel_edges[i] :
        //   i_kernel_sel == 2'b10 ? kernel_gaussian_blur[i] :
        //   kernel_sharpen[i];
      end
  endgenerate

  wire signed [NB_COEFF*KERNEL_SIZE-1:0] kernel_to_convolver;
  assign kernel_to_convolver = {kernel[2], kernel[1], kernel[0]};

  // data connections
  wire signed [NB_PIXEL*KERNEL_SIZE-1:0] data_to_conv0, data_to_conv1, data_to_conv2, data_to_conv3;

  // output pixels
  wire [NB_PIXEL-1:0] o_pixel0, o_pixel1, o_pixel2, o_pixel3;
  assign o_axi_data = {o_pixel3, o_pixel2, o_pixel1, o_pixel0};

  // Instancias
  conv_2d #(
      .NB_COEFF   (NB_COEFF),
      .NB_OUTPUT  (NB_PIXEL),
      .NB_DATA    (NB_PIXEL),
      .KERNEL_SIZE(KERNEL_SIZE)
  ) u_conv_0 (
      .clk(i_clk),
      .i_rst(i_reset),
      .i_kernel(kernel_to_convolver),
      .i_data(data_to_conv0),
      .o_pixel(o_pixel0)
  );

  conv_2d #(
      .NB_COEFF   (NB_COEFF),
      .NB_OUTPUT  (NB_PIXEL),
      .NB_DATA    (NB_PIXEL),
      .KERNEL_SIZE(KERNEL_SIZE)
  ) u_conv_1 (
      .clk(i_clk),
      .i_rst(i_reset),
      .i_kernel(kernel_to_convolver),
      .i_data(data_to_conv1),
      .o_pixel(o_pixel1)
  );

  conv_2d #(
      .NB_COEFF   (NB_COEFF),
      .NB_OUTPUT  (NB_PIXEL),
      .NB_DATA    (NB_PIXEL),
      .KERNEL_SIZE(KERNEL_SIZE)
  ) u_conv_2 (
      .clk(i_clk),
      .i_rst(i_reset),
      .i_kernel(kernel_to_convolver),
      .i_data(data_to_conv2),
      .o_pixel(o_pixel2)
  );

  conv_2d #(
      .NB_COEFF   (NB_COEFF),
      .NB_OUTPUT  (NB_PIXEL),
      .NB_DATA    (NB_PIXEL),
      .KERNEL_SIZE(KERNEL_SIZE)
  ) u_conv_3 (
      .clk(i_clk),
      .i_rst(i_reset),
      .i_kernel(kernel_to_convolver),
      .i_data(data_to_conv3),
      .o_pixel(o_pixel3)
  );

  subframe #(
      .IMAGE_HEIGHT(IMAGE_HEIGHT),  // Image height with zero padding
      .KERNEL_WITDH(KERNEL_WIDTH),
      .NB_PIXEL    (NB_PIXEL),
      .NB_DATA     (NB_DATA)
  ) u_subframe (
      .i_clk     (i_clk),
      .i_reset   (i_reset),
      .i_axi_data(i_axi_data),
      .i_valid   (i_valid),
      .o_conv0   (data_to_conv0),
      .o_conv1   (data_to_conv1),
      .o_conv2   (data_to_conv2),
      .o_conv3   (data_to_conv3)
  );

endmodule
