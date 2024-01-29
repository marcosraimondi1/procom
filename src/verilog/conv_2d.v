module conv_2d(
    input clk,       //! Clock 100 MHz
    input i_nrst,   
    input i_en_conv,         // Habilita la operación de convolución
    input i_load_knl,   // Indica si se van a cargar los coeficientes del kernel
    input      signed [7:0] i_data1,    //Recibo de a 3 pixeles/coeficientes (9x3)
    input      signed [7:0] i_data2,    //Recibo de a 3 pixeles/coeficientes (9x3)
    input      signed [7:0] i_data3,    //Recibo de a 3 pixeles/coeficientes (9x3)
    output reg signed [19:0] o_pixel            //Resultado de la convolución
    );

    localparam NB_COEFF = 8;               //Numero de bits de los coeficientes 
    localparam NB_PROD  = NB_COEFF*2;
    localparam NB_SUM   = NB_PROD+4;
    localparam KERNEL_SIZE = 9;

    reg signed  [7:0]         subframe [KERNEL_SIZE:1];   //Sector de la imagen a convolucionar
    reg signed [NB_COEFF-1:0] kernel   [KERNEL_SIZE:1];    //Matriz de coeficientes del kernel 
    wire signed [NB_PROD-1:0] prod     [KERNEL_SIZE:1]; //! Partial Products

    reg [1:0] load_count;
    //Kernel identidad --> despues hay que hacerlo reg para poder cambiarlo durante la ejecucion

    // integer ptr1;
    // integer ptr2;
    // always @(posedge clk) begin
    //   if (i_nrst == 1'b1) begin
    //     for(ptr1=1; ptr1<=9; ptr1=ptr1+1) 
    //         subframe[ptr1] <= 8'b0;
    //   end else begin
    //     if (i_en_conv == 1'b1) begin
    //       for(ptr2=1; ptr2<9; ptr2=ptr2+1) begin
    //         if(ptr2 == 1)
    //             subframe[ptr2] <= i_row1;
    //         else if(ptr2 == 1)
    //             subframe[ptr2] <= i_row2;
    //         else if(ptr2 == 1)
    //             subframe[ptr2] <= i_row3;
    //         else
    //             subframe[ptr2] <= subframe[ptr2-1];
    //        end   
    //     end
    //   end
    // end
    integer ptr1;
    always @(posedge clk) begin
        if (!i_nrst) begin
            load_count <= 2'b0;
            for(ptr1=1; ptr1<=9; ptr1=ptr1+1) 
                subframe[ptr1] <= {NB_COEFF{1'b0}};
        end else begin
            if (i_en_conv == 1'b1) begin
                subframe[1] <= i_data1;
                subframe[2] <= subframe[1];
                subframe[3] <= subframe[2];
                subframe[4] <= i_data2;
                subframe[5] <= subframe[4];
                subframe[6] <= subframe[5];
                subframe[7] <= i_data3;
                subframe[8] <= subframe[7];
                subframe[9] <= subframe[8];
            end 
            else if(i_load_knl) begin
                if(load_count == 2'd3) 
                    load_count <= 2'b0;
                else begin
                    kernel[1+load_count] = i_data1;
                    kernel[4+load_count] = i_data2;
                    kernel[7+load_count] = i_data3;
                    load_count <= load_count+2'b1;
                end
            end
        end
    end

    // y[n] = x_I * h[n]
    // pasar a un for
    assign prod[1] = subframe[1] * kernel[1];
    assign prod[2] = subframe[2] * kernel[2];
    assign prod[3] = subframe[3] * kernel[3];
    assign prod[4] = subframe[4] * kernel[4];
    assign prod[5] = subframe[5] * kernel[5];
    assign prod[6] = subframe[6] * kernel[6];
    assign prod[7] = subframe[7] * kernel[7];
    assign prod[8] = subframe[8] * kernel[8];
    assign prod[9] = subframe[9] * kernel[9];

    always @ (posedge clk) begin
        if( !i_nrst ) 
            o_pixel <= {NB_SUM{1'b0}};
        else begin 
            if ( i_en_conv )
                o_pixel <= prod[1]+prod[2]+prod[3]+prod[4]+prod[5]+prod[6]+prod[7]+prod[8]+prod[9];
            else 
                o_pixel <= {NB_SUM{1'b0}};
        end            
    end

    // assign o_data = ( ~|y_I[phase_sel][NB_ADD-1 -: NB_SAT+1] || &y_I[phase_sel][NB_ADD-1 -: NB_SAT+1]) ? y_I[phase_sel][NB_ADD-(NBI_ADD-NBI_OUTPUT) - 1 -: NB_OUTPUT] :
    // (y_I[phase_sel][NB_ADD-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};


endmodule
