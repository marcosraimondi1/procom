module subframe #(
    IMAGE_HEIGHT = 200,  // Image height with zero padding
    KERNEL_WITDH = 3,
    NB_PIXEL = 8,
    NB_DATA = 32
) (
    input                i_clk,
    input                i_reset,
    input  [NB_DATA-1:0] i_axi_data,
    input                i_valid,
    output [NB_DATA-1:0] o_axi_data
);

  wire [NB_PIXEL-1:0] o_conv0;
  wire [NB_PIXEL-1:0] o_conv1;
  wire [NB_PIXEL-1:0] o_conv2;
  wire [NB_PIXEL-1:0] o_conv3;

  reg [NB_PIXEL*2-1:0] fifo[IMAGE_HEIGHT-1:0];
  reg [NB_DATA-1:0] subframe12[KERNEL_WITDH-1:0];  //columnas a la izquierda, fila derecha
  reg [NB_PIXEL-1:0] subframe18[KERNEL_WITDH-1:0][6-1:0];

  // subframe12 - is a FIFO with a width of 4 pixels
  integer i;
  always @(posedge i_clk) begin
    if (i_reset) begin
      for (i = 0; i < KERNEL_WITDH; i = i + 1) begin
        subframe12[i] <= {NB_DATA{1'b0}};
      end
    end else begin
      if (i_valid) begin
        for (i = 0; i < KERNEL_WITDH; i = i + 1) begin
          if (i < KERNEL_WITDH - 1) begin
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
        for (i = 0; i < IMAGE_HEIGHT - 1; i = i + 1) begin
          if (i < IMAGE_HEIGHT - 1) begin
            fifo[i] <= fifo[i+1];  // shift fifo
          end else begin
            fifo[i] <= subframe12[0][KERNEL_WITDH-1:1];  // add new data to fifo
          end
        end
      end
    end
  end

  // subframe18
  integer j;
  always @(*) begin
    // assign subframe12 to subframe18
    for (i = 0; i < IMAGE_HEIGHT - 1; i = i + 1) begin
      for (j = 0; j < 6; j = j + 1) begin
        if (j < 2) begin
          subframe18[i][j] <= fifo[i][j];
        end else begin
          subframe18[i][j] <= subframe12[i][j-2];
        end
      end
    end
  end

  /////////////////
  // Convolutors //
  /////////////////

  localparam NB_COEFF = 8;  //Numero de bits de los coeficientes
  localparam NBF_COEFF = 7;
  localparam NB_PROD = NB_COEFF * 2;
  localparam NBF_PROD = NBF_COEFF * 2;
  localparam NB_ADD = NB_PROD + 4;
  localparam KERNEL_SIZE = 9;
  localparam NBF_ADD = NBF_PROD;
  localparam NBI_ADD = NB_ADD - NBF_ADD;
  localparam NB_OUTPUT = 8;
  localparam NBF_OUTPUT = 7;
  localparam NBI_OUTPUT = NB_OUTPUT - NBF_OUTPUT;
  localparam NB_SAT = (NBI_ADD) - (NBI_OUTPUT);
  reg [NB_PIXEL-1:0] kernel[KERNEL_WITDH-1:0][KERNEL_WITDH-1:0];  // 3x3 kernel
  //[0][0][0]
  //[0][1][0]
  //[0][0][0]

  always @(posedge i_clk) begin
    if (i_reset) begin
      for (i = 0; i < KERNEL_WITDH; i = i + 1) begin
        for (j = 0; j < KERNEL_WITDH; j = j + 1) begin
          if (i == 1 && j == 1) kernel[i][j] <= {NB_PIXEL{1'b1}};
          else kernel[i][j] <= {NB_PIXEL{1'b0}};
        end
      end
    end
  end

//   reg signed [NB_ADD-1:0] sum;
//   always @(posedge i_clk) begin
//     if (i_reset) sum <= {NB_ADD{1'b0}};
//     else begin
//       if (i_valid)
//         sum <= prod[1]+prod[2]+prod[3]+prod[4]+prod[5]+prod[6]+prod[7]+prod[8]+prod[9];
//       else sum <= {NB_ADD{1'b0}};
//     end
//   end

  reg signed [NB_ADD-1:0] sum[4];
  always @(*) begin
    for (i = 0; i < 4; i = i + 1) begin
      sum[i] = {NB_ADD{1'b0}};
      for (j = 0; j < KERNEL_WITDH * KERNEL_WITDH; j = j + 1) begin
        sum[i] = sum[i] + subframe18[k/3][k%3+j] * kernel[k/3][k%3];
      end
    end
  end

  // Convolutor 0
  assign o_conv0 = ( ~|sum[0][NB_ADD-1 -: NB_SAT+1] || &sum[0][NB_ADD-1 -: NB_SAT+1]) ? sum[0][NB_ADD-(NB_SAT) - 1 -: NB_OUTPUT] :
                      (sum[0][NB_ADD-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};

  // Convolutor 1
  assign o_conv1 = ( ~|sum[1][NB_ADD-1 -: NB_SAT+1] || &sum[1][NB_ADD-1 -: NB_SAT+1]) ? sum[1][NB_ADD-(NB_SAT) - 1 -: NB_OUTPUT] :
                      (sum[1][NB_ADD-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};

  // Convolutor 2
  assign o_conv2 = ( ~|sum[2][NB_ADD-1 -: NB_SAT+1] || &sum[2][NB_ADD-1 -: NB_SAT+1]) ? sum[2][NB_ADD-(NB_SAT) - 1 -: NB_OUTPUT] :
                      (sum[2][NB_ADD-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};

  // Convolutor 3
  assign o_conv3 = ( ~|sum[3][NB_ADD-1 -: NB_SAT+1] || &sum[3][NB_ADD-1 -: NB_SAT+1]) ? sum[3][NB_ADD-(NB_SAT) - 1 -: NB_OUTPUT] :
                      (sum[3][NB_ADD-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};


  assign o_axi_data = {o_conv3, o_conv2, o_conv1, o_conv0};
endmodule

