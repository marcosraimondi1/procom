module conv_2d
    (
    input clk,       //! Clock 100 MHz
    input i_nrst,   
    input i_en_conv,         // Habilita la operación de convolución
    input i_data_valid,     //El subframe está completo
    input i_load_knl,   // Indica si se van a cargar los coeficientes del kernel
    output     o_read_for_processing,        //Le indica a la bram que tiene que cargar los 3 pixeles

    input      signed [7:0] i_data1,    
    input      signed [7:0] i_data2,    
    input      signed [7:0] i_data3,    
    output     signed [7:0] o_pixel            //Resultado de la convolución
    );

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

    reg signed  [7:0]         subframe [KERNEL_SIZE:1];   //Sector de la imagen a convolucionar
    reg signed [NB_COEFF-1:0] kernel   [KERNEL_SIZE:1];    //Matriz de coeficientes del kernel 
    wire signed [NB_PROD-1:0] prod     [KERNEL_SIZE:1]; //! Partial Products

    reg [1:0] load_count;

    integer ptr1;
    always @(posedge clk) begin
        if (!i_nrst) begin
            load_count <= 2'b0;
            for(ptr1=1; ptr1<=9; ptr1=ptr1+1) 
                subframe[ptr1] <= {NB_COEFF{1'bZ}};
        end else begin
            if(i_load_knl) begin    //Carga del kernel
                if(load_count == 2'd3) 
                   load_count <= 2'b0;
                else begin
                    kernel[1+load_count] = i_data1;
                    kernel[4+load_count] = i_data2;
                    kernel[7+load_count] = i_data3;
                    load_count <= load_count+2'b1;
                end
            end else begin      //Desplazamiento del SR del subframe
                subframe[1] <= subframe[4];
                subframe[2] <= subframe[5];
                subframe[3] <= subframe[6];
                subframe[4] <= subframe[7];
                subframe[5] <= subframe[8];
                subframe[6] <= subframe[9];
                subframe[7] <= i_data1;
                subframe[8] <= i_data2;
                subframe[9] <= i_data3;
            end
        end
    end

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

    reg signed [NB_ADD-1:0] sum;
    always @ (posedge clk) begin
        if( !i_nrst ) 
            sum <= {NB_ADD{1'b0}};
        else begin 
            if ( i_data_valid )
                sum <= prod[1]+prod[2]+prod[3]+prod[4]+prod[5]+prod[6]+prod[7]+prod[8]+prod[9];
            else 
                sum <= {NB_ADD{1'b0}};
        end            
    end

    assign o_pixel = ( ~|sum[NB_ADD-1 -: NB_SAT+1] || &sum[NB_ADD-1 -: NB_SAT+1]) ? sum[NB_ADD-(NB_SAT) - 1 -: NB_OUTPUT] :
                      (sum[NB_ADD-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};

endmodule