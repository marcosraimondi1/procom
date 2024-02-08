module convolver(
    input   i_clk,
    input   i_reset,
    input  [7:0] kernel1,
    input  [7:0] kernel2,
    input  [7:0] kernel3,
    input  [7:0] kernel4,
    input  [7:0] kernel5,
    input  [7:0] kernel6,
    input  [7:0] kernel7,
    input  [7:0] kernel8,
    input  [7:0] kernel9,
    input  [7:0] subframe1,
    input  [7:0] subframe2,
    input  [7:0] subframe3,
    input  [7:0] subframe4,
    input  [7:0] subframe5,
    input  [7:0] subframe6,
    input  [7:0] subframe7,
    input  [7:0] subframe8,
    input  [7:0] subframe9,
    output [7:0] o_conv,
);    
    
    localparam NB_DATA     = 8;
    localparam NB_COEFF    = 8;               //Numero de bits de los coeficientes 
    localparam NBF_COEFF   = 7;                
    localparam NB_PROD     = NB_COEFF*2;
    localparam NBF_PROD    = NBF_COEFF*2;
    localparam NB_ADD      = NB_PROD+4;
    localparam KERNEL_SIZE = 9;

    localparam NBF_ADD    = NBF_PROD;
    localparam NBI_ADD    = NB_ADD - NBF_ADD;

    localparam NB_OUTPUT  = 8;
    localparam NBF_OUTPUT = 7;
    localparam NBI_OUTPUT = NB_OUTPUT - NBF_OUTPUT;
    localparam NB_SAT     = (NBI_ADD) - (NBI_OUTPUT);

    reg signed [NB_COEFF-1:0] kernel [KERNEL_SIZE:1];    //Matriz de coeficientes del kernel 
    wire signed [NB_PROD-1:0] prod  [KERNEL_SIZE:1]; //! Partial Products
    reg signed  [NB_ADD-1:0] sum;


endmodule