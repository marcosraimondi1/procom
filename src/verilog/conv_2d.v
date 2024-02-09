module conv_2d # (
    parameter NB_COEFF    = 8,
    parameter NB_OUTPUT   = 8,
    parameter NB_DATA     = 8,
    parameter KERNEL_SIZE = 9
)
 (
    input clk, 
    input i_rst,   
    input      signed [NB_COEFF*KERNEL_SIZE-1:0] i_kernel,    
    input      signed [NB_DATA*KERNEL_SIZE-1:0] i_data,    
    output  wire   signed [NB_OUTPUT-1:0] o_pixel            //Resultado de la convolución
    );

    localparam NBF_COEFF   = 7;                
    localparam NB_PROD     = NB_COEFF*2;
    localparam NBF_PROD    = NBF_COEFF*2;
    localparam NB_ADD      = NB_PROD+4;

    localparam NBF_ADD    = NBF_PROD;
    localparam NBI_ADD    = NB_ADD - NBF_ADD;

    localparam NBF_OUTPUT = 7;
    localparam NBI_OUTPUT = NB_OUTPUT - NBF_OUTPUT;
    localparam NB_SAT     = (NBI_ADD) - (NBI_OUTPUT);

    wire signed [NB_DATA-1:0]  subframe [KERNEL_SIZE-1:0];   //Sector de la imagen a convolucionar
    wire signed [NB_COEFF-1:0] kernel   [KERNEL_SIZE-1:0];    //Matriz de coeficientes del kernel 
    wire signed [NB_PROD-1:0]  prod     [KERNEL_SIZE-1:0]; //! Partial Products

    genvar gi;
    generate
        for (gi = 0; gi<KERNEL_SIZE; gi=gi+1) begin
            assign kernel[gi]   = i_kernel[NB_COEFF*(KERNEL_SIZE-gi)-1 -: NB_COEFF];
            assign subframe[gi] = i_data[NB_DATA*(KERNEL_SIZE-gi)-1 -: NB_DATA];
        end
    endgenerate

    // pasar a un for
    assign prod[0] = subframe[0] * kernel[0];
    assign prod[1] = subframe[1] * kernel[1];
    assign prod[2] = subframe[2] * kernel[2];
    assign prod[3] = subframe[3] * kernel[3];
    assign prod[4] = subframe[4] * kernel[4];
    assign prod[5] = subframe[5] * kernel[5];
    assign prod[6] = subframe[6] * kernel[6];
    assign prod[7] = subframe[7] * kernel[7];
    assign prod[8] = subframe[8] * kernel[8];

    reg signed [NB_ADD-1:0] sum;
    always @(posedge clk) begin
       if (i_rst) begin
        sum <= {NB_ADD{1'b0}};
       end
       else begin
           sum <= prod[0]+prod[1]+prod[2]+prod[3]+prod[4]+prod[5]+prod[6]+prod[7]+prod[8];
       end
    end
    // assign sum = prod[0]+prod[1]+prod[2]+prod[3]+prod[4]+prod[5]+prod[6]+prod[7]+prod[8];

    assign o_pixel = ( ~|sum[NB_ADD-1 -: NB_SAT+1] || &sum[NB_ADD-1 -: NB_SAT+1]) ? sum[NB_ADD-(NB_SAT) - 1 -: NB_OUTPUT] :
                      (sum[NB_ADD-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};
endmodule
