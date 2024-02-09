module subframe #(
    IMAGE_HEIGHT = 200,  // Image height with zero padding
    KERNEL_WIDTH = 3,
    NB_PIXEL = 8,
    NB_CONV = KERNEL_WIDTH * KERNEL_WIDTH * NB_PIXEL,
    NB_DATA = 32
) (
    input                i_clk,
    input                i_reset,
    input  [NB_DATA-1:0] i_axi_data,
    input                i_valid,
    output [NB_CONV-1:0] o_conv0,
    output [NB_CONV-1:0] o_conv1,
    output [NB_CONV-1:0] o_conv2,
    output [NB_CONV-1:0] o_conv3
);


  reg [NB_PIXEL*2-1:0] fifo[IMAGE_HEIGHT-1:0];     
  reg [NB_DATA-1:0] subframe12[KERNEL_WIDTH-1:0];  //columnas a la izquierda, fila derecha
  wire [NB_PIXEL-1:0] subframe18[KERNEL_WIDTH-1:0][6-1:0];

  // subframe12 - is a FIFO with a width of 4 pixels
  integer i;
  always @(posedge i_clk) begin
    if (i_reset) begin
      for (i = 0; i < KERNEL_WIDTH; i = i + 1) begin
        subframe12[i] <= {NB_DATA{1'b0}};
      end
    end else begin
      if (i_valid) begin
        for (i = 0; i < KERNEL_WIDTH; i = i + 1) begin
          if (i < KERNEL_WIDTH - 1) begin
            subframe12[i] <= subframe12[i+1];  // shift subframe12
          end else begin
            subframe12[i] <= i_axi_data;  // add new data to subframe12
          end
        end
      end
    end
  end

  // FIFO: height equal to image height
  always @(posedge i_clk) begin
    if (i_reset) begin
       for (i = 0; i < IMAGE_HEIGHT; i = i + 1) begin
           fifo[i] <= {NB_PIXEL * 2{1'b0}};
      end
    end else begin
      if (i_valid) begin
        for (i = 0; i < IMAGE_HEIGHT; i = i + 1) begin
          if (i < IMAGE_HEIGHT - 1) begin
            fifo[i] <= fifo[i+1];  // shift fifo
          end else begin
            fifo[i] <= subframe12[0][NB_DATA-1-:NB_PIXEL*2];  // add new data to fifo
          end
        end
      end
    end
  end

  // subframe18
  genvar gi, gj;

  generate
    for (gi = 0; gi < KERNEL_WIDTH; gi = gi + 1) begin
      for (gj = 0; gj < 2; gj = gj + 1) begin
        assign subframe18[gi][gj] = fifo[gi][NB_PIXEL*(gj+1)-1-:NB_PIXEL];
      end
    end
  endgenerate


  generate
    for (gi = 0; gi < KERNEL_WIDTH; gi = gi + 1) begin
      for (gj = 2; gj < 6; gj = gj + 1) begin
        assign subframe18[gi][gj] = subframe12[gi][NB_PIXEL*(gj-1)-1-:NB_PIXEL];
      end
    end
  endgenerate

  
  // CONV0
  wire [NB_PIXEL*KERNEL_WIDTH-1:0] conv0_fila0;
  wire [NB_PIXEL*KERNEL_WIDTH-1:0] conv0_fila1;
  wire [NB_PIXEL*KERNEL_WIDTH-1:0] conv0_fila2;

  assign conv0_fila0 = {subframe18[0][2], subframe18[0][1], subframe18[0][0]};
  assign conv0_fila1 = {subframe18[1][2], subframe18[1][1], subframe18[1][0]};
  assign conv0_fila2 = {subframe18[2][2], subframe18[2][1], subframe18[2][0]};

  assign o_conv0 = {conv0_fila2, conv0_fila1, conv0_fila0};

  // CONV1
  wire [NB_PIXEL*KERNEL_WIDTH-1:0] conv1_fila0;
  wire [NB_PIXEL*KERNEL_WIDTH-1:0] conv1_fila1;
  wire [NB_PIXEL*KERNEL_WIDTH-1:0] conv1_fila2;

  assign conv1_fila0 = {subframe18[0][3], subframe18[0][2], subframe18[0][1]};
  assign conv1_fila1 = {subframe18[1][3], subframe18[1][2], subframe18[1][1]};
  assign conv1_fila2 = {subframe18[2][3], subframe18[2][2], subframe18[2][1]};

  assign o_conv1 = {conv1_fila2, conv1_fila1, conv1_fila0};

  // CONV2
  wire [NB_PIXEL*KERNEL_WIDTH-1:0] conv2_fila0;
  wire [NB_PIXEL*KERNEL_WIDTH-1:0] conv2_fila1;
  wire [NB_PIXEL*KERNEL_WIDTH-1:0] conv2_fila2;

  assign conv2_fila0 = {subframe18[0][4], subframe18[0][3], subframe18[0][2]};
  assign conv2_fila1 = {subframe18[1][4], subframe18[1][3], subframe18[1][2]};
  assign conv2_fila2 = {subframe18[2][4], subframe18[2][3], subframe18[2][2]};

  assign o_conv2 = {conv2_fila2, conv2_fila1, conv2_fila0};

  // CONV3
  wire [NB_PIXEL*KERNEL_WIDTH-1:0] conv3_fila0;
  wire [NB_PIXEL*KERNEL_WIDTH-1:0] conv3_fila1;
  wire [NB_PIXEL*KERNEL_WIDTH-1:0] conv3_fila2;

  assign conv3_fila0 = {subframe18[0][5], subframe18[0][4], subframe18[0][3]};
  assign conv3_fila1 = {subframe18[1][5], subframe18[1][4], subframe18[1][3]};
  assign conv3_fila2 = {subframe18[2][5], subframe18[2][4], subframe18[2][3]};

  assign o_conv3 = {conv3_fila2, conv3_fila1, conv3_fila0};
  
endmodule

