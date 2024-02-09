module top_convolver #(
    IMAGE_HEIGHT = 200,  // Image height with zero padding
    KERNEL_WIDTH = 3,
    NB_PIXEL = 8,
    NB_COEFF = 8,
    KERNEL_SIZE = 9,
    NB_CONV = KERNEL_SIZE * NB_PIXEL,
    NB_DATA = 32
) (
    input                i_clk,
    input                i_reset,
    input  [NB_DATA-1:0] i_axi_data,
    input                i_valid,
    //output               i_ready,

    //output reg              o_valid,
    //input                   o_ready,
    output [NB_DATA-1:0] o_axi_data

);

subframe #(
    .IMAGE_HEIGHT (IMAGE_HEIGHT),  // Image height with zero padding
    .KERNEL_WITDH (KERNEL_WIDTH),
    .NB_PIXEL     (NB_PIXEL)  ,
    .NB_DATA      (NB_DATA)
) u_subframe (
    .i_clk  (i_clk),
    .i_reset(i_reset),
    .i_axi_data (i_axi_data),
    .i_valid    (i_valid),
    .o_conv0(i_data_to_conv0),
    .o_conv1(i_data_to_conv1),
    .o_conv2(i_data_to_conv2),
    .o_conv3(i_data_to_conv3)
);

wire signed [NB_COEFF*KERNEL_SIZE-1:0] kernel_to_convolver;
wire signed [NB_COEFF*KERNEL_SIZE-1:0] i_data_to_conv0,i_data_to_conv1,i_data_to_conv2,i_data_to_conv3;

reg [NB_PIXEL-1:0] kernel[KERNEL_WIDTH-1:0][KERNEL_WIDTH-1:0];  // 3x3 kernel
wire [NB_PIXEL-1:0] o_pixel0,o_pixel1,o_pixel2,o_pixel3;
integer i,j;
  //[0][0][0]
  //[0][1][0]
  //[0][0][0]
always @(posedge i_clk) begin
    if (i_reset) begin
      for (i = 0; i < KERNEL_WIDTH; i = i + 1) begin
        for (j = 0; j < KERNEL_WIDTH; j = j + 1) begin
          if (i == 1 && j == 1) kernel[i][j] <= {(NB_PIXEL-1){1'b1}};
          else kernel[i][j] <= {NB_PIXEL{1'b0}};
        end
      end
    end
  end

assign kernel_to_convolver = {kernel[2][2], kernel[2][1], kernel[2][0], kernel[1][2], kernel[1][1], kernel[1][0], kernel[0][2], kernel[0][1], kernel[0][0]};
assign o_axi_data = {o_pixel0,o_pixel1,o_pixel2,o_pixel3};

conv_2d # (
    .NB_COEFF    (NB_COEFF),
    .NB_OUTPUT   (NB_PIXEL),
    .NB_DATA     (NB_PIXEL),
    .KERNEL_SIZE (KERNEL_SIZE)
)
    u_conv_0 (
    .clk(i_clk), 
    .i_rst(i_reset),   
    .i_kernel(kernel_to_convolver),    
    .i_data(i_data_to_conv0),    
    .o_pixel(o_pixel0)            
);
conv_2d # (
    .NB_COEFF    (NB_COEFF),
    .NB_OUTPUT   (NB_PIXEL),
    .NB_DATA     (NB_PIXEL),
    .KERNEL_SIZE (KERNEL_SIZE)
)
    u_conv_1 (
    .clk(i_clk), 
    .i_rst(i_reset),   
    .i_kernel(kernel_to_convolver),    
    .i_data(i_data_to_conv1),    
    .o_pixel(o_pixel1)            
);
conv_2d # (
    .NB_COEFF    (NB_COEFF),
    .NB_OUTPUT   (NB_PIXEL),
    .NB_DATA     (NB_PIXEL),
    .KERNEL_SIZE (KERNEL_SIZE)
)
    u_conv_2 (
    .clk(i_clk), 
    .i_rst(i_reset),   
    .i_kernel(kernel_to_convolver),    
    .i_data(i_data_to_conv2),    
    .o_pixel(o_pixel2)            
);
conv_2d # (
    .NB_COEFF    (NB_COEFF),
    .NB_OUTPUT   (NB_PIXEL),
    .NB_DATA     (NB_PIXEL),
    .KERNEL_SIZE (KERNEL_SIZE)
)
    u_conv_3 (
    .clk(i_clk), 
    .i_rst(i_reset),   
    .i_kernel(kernel_to_convolver),    
    .i_data(i_data_to_conv3),    
    .o_pixel(o_pixel3)            
);

endmodule
