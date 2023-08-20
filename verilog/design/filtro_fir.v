//! @title FIR Filter
//! @file filtro_fir.v
//! @author Advance Digital Design - Ariel Pola
//! @date 29-08-2021
//! @version Unit02 - Modelo de Implementacion

//! - Fir filter with 6 coefficients 
//! - **i_reset** is the system reset.
//! - **i_enable** controls the enable (1) of the FIR. The value (0) stops the systems without change of the current state of the FIR.
//! - Coefficients from raised cosine filter

module filtro_fir
  #(
    parameter NB_INPUT   = 8, //! NB of input
    parameter NBF_INPUT  = 7, //! NBF of input
    parameter NB_OUTPUT  = 8, //! NB of output
    parameter NBF_OUTPUT = 7, //! NBF of output
    parameter NB_COEFF   = 8, //! NB of Coefficients
    parameter NBF_COEFF  = 7  //! NBF of Coefficients
  ) 
  (
    output signed [NB_OUTPUT-1:0] o_data                  , //! Output Sample
    input                         i_data                  , //! Input Sample (bit)
    input                         i_enable                , //! Enable
    input                         i_valid                 , //! Valid Input -> shift register
    input                         i_reset                 , //! Reset
    input                         clock                     //! Clock
  );

  localparam N_COEFF    = 6                         ; //! Number of Coefficients
  localparam NB_ADD     = NB_COEFF  + NB_INPUT + 3  ; // una multiplicacion y 3 sumas
  localparam NBF_ADD    = NBF_COEFF + NBF_INPUT     ; // por la multiplicacion se suman los NBF
  localparam NBI_ADD    = NB_ADD    - NBF_ADD       ;
  localparam NBI_OUTPUT = NB_OUTPUT - NBF_OUTPUT    ;
  localparam NB_SAT     = (NBI_ADD) - (NBI_OUTPUT)  ;

  //! Internal Signals
  reg         [N_COEFF-1:1          ] register              ; //! input samples
  reg         [1:0                  ] f_selector            ; //! selecciona el filtro polifasico
  wire signed [NB_INPUT+NB_COEFF-1:0] prod     [N_COEFF-1:0]; //! Partial Products
  wire signed [NB_ADD-1:0           ] sum      [N_COEFF-1:1]; //! Add samples
  wire signed [NB_ADD-1:0           ] sum_res               ; //! Add Result, Filter Full Resolution Output
  
  wire signed [NB_COEFF -1:0        ] coeff    [N_COEFF-1:0]; //! Coefficients

  //! Coeficientes filtro polifasico RC
  // filter	0: [255, 0, 255, 127, 0, 255]
  // filter	1: [0, 248, 33, 113, 240, 2]
  // filter	2: [2, 240, 76, 76, 240, 2]
  // filter	3: [2, 240, 113, 33, 248, 0]
  //                                        filter 0 ,                       filter 1 ,                       filter 2 , filter 3
  assign coeff[0]   = f_selector == 2'b00 ? 8'd255   : f_selector == 2'b01 ? 8'd0     : f_selector == 2'b10 ? 8'd2     : 8'd2     ;
  assign coeff[1]   = f_selector == 2'b00 ? 8'd0     : f_selector == 2'b01 ? 8'd248   : f_selector == 2'b10 ? 8'd240   : 8'd240   ;
  assign coeff[2]   = f_selector == 2'b00 ? 8'd255   : f_selector == 2'b01 ? 8'd33    : f_selector == 2'b10 ? 8'd76    : 8'd113   ;
  assign coeff[3]   = f_selector == 2'b00 ? 8'd127   : f_selector == 2'b01 ? 8'd113   : f_selector == 2'b10 ? 8'd76    : 8'd33    ;
  assign coeff[4]   = f_selector == 2'b00 ? 8'd0     : f_selector == 2'b01 ? 8'd240   : f_selector == 2'b10 ? 8'd240   : 8'd248   ;
  assign coeff[5]   = f_selector == 2'b00 ? 8'd255   : f_selector == 2'b01 ? 8'd2     : f_selector == 2'b10 ? 8'd2     : 8'd0     ;


  //! Cambio filtro polifasico
  always @(posedge clock) begin
    if (i_reset)
      f_selector     <= 2'b00          ;
    else
      f_selector     <= i_enable ? f_selector + 1 : f_selector;
  end

  //! ShiftRegister model

  always @(posedge clock) begin:shiftRegister
    if (i_reset) 
    begin
      register <= {N_COEFF{1'b0}} ;
    end 
    else 
    begin
      if (i_enable && i_valid)
      begin
        // si esta habilitado y entra una muestra
        register[N_COEFF-1:2] <= register[N_COEFF-2:1]  ;
        register[1]           <= i_data                 ;
      end
      else
        register <= register;
    end
  end

  //! Products
  generate
    genvar ptr;
    for(ptr=0; ptr<N_COEFF ;ptr=ptr+1) begin:mult
      if (ptr==0) 
        // optimizacion para data +-1, 0 -> coef , 1 -> -coef
        assign prod[ptr] = i_data         ? ~coeff[ptr] + 1 : coeff[ptr]  ; // coeff[ptr] * i_data        ;
      else
        assign prod[ptr] = register[ptr]  ? ~coeff[ptr] + 1 : coeff[ptr]  ; // coeff[ptr] * register[ptr] ;
    end
  endgenerate

  // USANDO REGISTROS PARA LOS PRODUCTOS
  // reg signed [NB_INPUT+NB_COEFF-1:0] prod     [3:0]; //! Partial Products
  // integer ptr;
  // always @(posedge clock) begin// @(*) begin
  //   for(ptr=0;ptr<N_COEFF;ptr=ptr+1) begin:mult
  //     if (ptr==0) 
  //       prod[ptr] <= coeff[ptr] * i_data;
  //     else
  //       prod[ptr] <= coeff[ptr] * register[ptr];
  //   end    
  // end

 
  //! Adders
  generate
    for(ptr=1; ptr<N_COEFF ;ptr=ptr+1) begin:adders
      if (ptr==1) 
        assign sum[ptr] = prod[ptr-1] + prod[ptr];
      else
        assign sum[ptr] = sum[ptr-1]  + prod[ptr];
    end
  endgenerate
  

  // Output con truncamiento y saturacion
  // sum[N_COEFF-1]                -> resultado del filtrado
  // sum_res[NB_ADD-1 -: NB_SAT+1] -> parte del resultado que tiene que tener la extension del signo

  assign sum_res = sum[N_COEFF-1];

  assign o_data = ( 
    ~|sum_res[NB_ADD-1 -: NB_SAT+1] || &sum_res[NB_ADD-1 -: NB_SAT+1])  ? // se cumple la extension de signo ?
    sum_res[NB_ADD-(NBI_ADD-NBI_OUTPUT) - 1 -: NB_OUTPUT]               : // si se cumple, solo se trunca
    (sum_res[NB_ADD-1])                                                 ? // si no se cumple, se satura segun el signo
    {{1'b1},{NB_OUTPUT-1{1'b0}}}                                        : // saturo negativo {1000....0}
    {{1'b0},{NB_OUTPUT-1{1'b1}}}                                        ; // saturo positivo {0111....1}

endmodule
