module filter#(
        NB  = 8,    //! number of bits
        NBF = 7,    //! number of fractional bits
        OS  = 4     //! oversampling factor
    )(
        output signed [NB-1:0]  o_data          , //! output data, OS samples
        input                   i_bit           , //! input data
        input                   i_valid         , //! on valid add sample
        input                   i_enable        , //! enable filter
        input                   reset           ,
        input                   clock
    );

    localparam NBAUDS   = 6                 ; //! number of bauds to filter
    localparam NBI      = NB - NBF          ; //! number of integer bits                    S(8,7)
    localparam NB_PROD  = NB                ; //! number of bits of the product             S(16,14)
    localparam NBF_PROD = NBF               ; //! number of fractional bits of the product  S(16,14)
    localparam NB_SUM   = NB_PROD + 3       ; //! number of bits of the sum                 S(19,14)
    localparam NBF_SUM  = NBF_PROD          ; //! number of fractional bits of the sum      S(19,14)
    localparam NBI_SUM  = NB_SUM - NBF_SUM  ; //! numero de bits enteros de la suma         (19-14 = 5)

    wire signed [NB-1     :0]   coeff       [NBAUDS-1:0]; //! filter coefficients
    reg         [NBAUDS-1 :1]   shiftreg                ; //! filter shift register
    wire signed [NB_PROD-1:0]   prod        [NBAUDS-1:0]; //! partial products          (6 multiplicaciones)
    wire signed [NB_SUM-1 :0]   sum         [NBAUDS-1:1]; //! sum of partial products   (5 sumas)
    wire signed [NB_SUM-1 :0]   sum_res                 ; //! sum result (full resolution)
    reg         [1        :0]   f_selector              ; //! filter phase selector

    assign coeff[0]   = f_selector == 2'b00 ? 8'd255   : f_selector == 2'b01 ? 8'd0     : f_selector == 2'b10 ? 8'd2     : 8'd2     ;
    assign coeff[1]   = f_selector == 2'b00 ? 8'd0     : f_selector == 2'b01 ? 8'd248   : f_selector == 2'b10 ? 8'd240   : 8'd240   ;
    assign coeff[2]   = f_selector == 2'b00 ? 8'd255   : f_selector == 2'b01 ? 8'd33    : f_selector == 2'b10 ? 8'd76    : 8'd113   ;
    assign coeff[3]   = f_selector == 2'b00 ? 8'd127   : f_selector == 2'b01 ? 8'd113   : f_selector == 2'b10 ? 8'd76    : 8'd33    ;
    assign coeff[4]   = f_selector == 2'b00 ? 8'd0     : f_selector == 2'b01 ? 8'd240   : f_selector == 2'b10 ? 8'd240   : 8'd248   ;
    assign coeff[5]   = f_selector == 2'b00 ? 8'd255   : f_selector == 2'b01 ? 8'd2     : f_selector == 2'b10 ? 8'd2     : 8'd0     ;

    always @(posedge clock)
    begin
        if (reset)
            f_selector <= 0;
        else 
            begin
                if (i_enable && i_valid)
                    f_selector <= f_selector + 1;
                else
                    f_selector <= f_selector;
            end
    end

    // shiftreg
    always @(posedge clock)
    begin
        if (reset)
            shiftreg <= 0;
        else if (i_enable && i_valid)
            shiftreg    <= {shiftreg[NBAUDS-2:1], i_bit};
        else
            shiftreg <= shiftreg;
    end

    // partial products
    assign prod[0] = i_bit == 1'b1 ? ~coeff[0] + 1'b1 : coeff[0];
    generate
        genvar ptr;
        for (ptr = 1; ptr < NBAUDS; ptr = ptr + 1)
        begin
            assign prod[ptr] = shiftreg[ptr] == 1'b1 ? ~coeff[ptr] + 1'b1 : coeff[ptr];
        end
    endgenerate

    // sum of partial products
    assign sum[1] = prod[0] + prod[1];
    generate
        genvar ptr2;
        for (ptr2 = 2; ptr2 < NBAUDS; ptr2 = ptr2 + 1)
        begin
            assign sum[ptr2] = sum[ptr2-1] + prod[ptr2];
        end
    endgenerate

    assign sum_res = sum[NBAUDS-1]; // resultado full resolution del filtrado S(19,14)
    
    // saturate and truncate
    wire [3:0] extension_de_signo = sum_res[NB_SUM-1 -: 4]            ; // parte de extension de signo [18:14]

    wire no_saturar         = ~|extension_de_signo || &extension_de_signo   ; // no saturar si todos los bits son iguales
    
    wire [NB-1:0] truncado  = sum_res[NB-1 : 0]            ;
    
    wire [NB-1:0] saturado  = sum_res[NB_SUM-1] ? {{1'b1}, {NB-1{1'b0}}} : {{1'b0}, {NB-1{1'b1}}}   ;
    
    assign o_data           = no_saturar ? truncado : saturado;

endmodule