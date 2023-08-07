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
    input  signed [NB_INPUT -1:0] i_data                  , //! Input Sample
    input                         i_enable                , //! Enable
    input                         i_reset                 , //! Reset
    input                         clock                     //! Clock
  );

  localparam N_COEFF    = 6;  //! Number of Coefficients
  localparam NB_ADD     = NB_COEFF  + NB_INPUT + 3; // una multiplicacion y 3 sumas
  localparam NBF_ADD    = NBF_COEFF + NBF_INPUT;    // por la multiplicacion se suman los NBF
  localparam NBI_ADD    = NB_ADD    - NBF_ADD;
  localparam NBI_OUTPUT = NB_OUTPUT - NBF_OUTPUT;
  localparam NB_SAT     = (NBI_ADD) - (NBI_OUTPUT);

  //! Internal Signals
  reg  signed [NB_INPUT-1:0         ] register [N_COEFF-1:1]; //! Matrix for 
  reg         [1:0                  ] f_selector            ; //! selecciona el filtro polifasico
  wire signed [NB_INPUT+NB_COEFF-1:0] prod     [N_COEFF-1:0]; //! Partial Products
  wire signed [NB_ADD-1:0           ] sum      [N_COEFF-1:1]; //! Add samples
  wire signed [NB_COEFF -1:0        ] coeff    [N_COEFF-1:0]; //! Coefficients

  //! Coeficientes filtro polifasico RC
  //! Coeff = [0, 1, 2, 3, 0, -7, -15, -16, 0, 34, 77, 114, 128, 114, 77, 34, 0, -16, -15, -7, 0, 3, 2, 1] 
  assign coeff[0]   = f_selector == 2'b00 ?  0 : f_selector == 2'b01 ? -15  : f_selector == 2'b10 ? 128 : -15 ;
  assign coeff[1]   = f_selector == 2'b00 ?  1 : f_selector == 2'b01 ? -16  : f_selector == 2'b10 ? 114 : -7  ;
  assign coeff[2]   = f_selector == 2'b00 ?  2 : f_selector == 2'b01 ?  0   : f_selector == 2'b10 ?  77 :  0  ;
  assign coeff[3]   = f_selector == 2'b00 ?  3 : f_selector == 2'b01 ?  34  : f_selector == 2'b10 ?  34 :  3  ;
  assign coeff[4]   = f_selector == 2'b00 ?  0 : f_selector == 2'b01 ?  77  : f_selector == 2'b10 ?  0  :  2  ;
  assign coeff[5]   = f_selector == 2'b00 ? -7 : f_selector == 2'b01 ?  114 : f_selector == 2'b10 ? -16 :  1  ;


  //! Cambio filtro polifasico
  always @(posedge clock) begin
    if (i_reset)
      f_selector     <= 2'b00          ;
    else
      f_selector     <= i_enable ? f_selector + 1 : f_selector;
  end

  //! ShiftRegister model
  integer i;
  integer j;

  always @(posedge clock) begin:shiftRegister
    if (i_reset) 
    begin
      for(i=1; i < N_COEFF; i=i+1) begin:init
        register[i] <= {NB_INPUT{1'b0}};
      end
    end else begin
      if (i_enable == 1'b1) begin
        for(j=1; j < N_COEFF; j=j+1) begin:srmove
          if(j==1)
            register[j] <= i_data;
          else
            register[j] <= register[j-1];
         end   
      end
    end
  end

  //! Products
  generate
    genvar ptr;
    for(ptr=0; ptr<N_COEFF ;ptr=ptr+1) begin:mult
      if (ptr==0) 
        assign prod[ptr] = coeff[ptr] * i_data;
      else
        assign prod[ptr] = coeff[ptr] * register[ptr];
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
  assign o_data = ( ~|sum[N_COEFF-1][NB_ADD-1 -: NB_SAT+1] || &sum[N_COEFF-1][NB_ADD-1 -: NB_SAT+1]) ? sum[N_COEFF-1][NB_ADD-(NBI_ADD-NBI_OUTPUT) - 1 -: NB_OUTPUT] :
                    (sum[N_COEFF-1][NB_ADD-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};



endmodule
