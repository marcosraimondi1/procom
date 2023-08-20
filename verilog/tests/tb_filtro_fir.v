//! @title FIR Filter - Testbench
//! @file filtro_fir.v
//! @author Advance Digital Design - Ariel Pola
//! @date 29-08-2021
//! @version Unit02 - Modelo de Implementacion

//! - Fir polifasic filter with 6 coefficients 
//! - **i_srst** is the system reset.
//! - **i_en** controls the enable (1) of the FIR. The value (0) stops the systems without change of the current state of the FIR.
//! - Coefficients from raised cosine filter

`timescale 1ns/1ps

module tb_filtro_fir ();

  reg           clock      ;
  reg           i_reset    ;
  wire          valid      ;
  reg   [31:0]  errors     ;                
  
  reg           [0:199  ]  filter_input              = {1'b1,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0,1'b1,1'b1,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,1'b1,1'b0,1'b1,1'b1,1'b1,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0,1'b1,1'b0,1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b1,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0,1'b1,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b1,1'b1,1'b0,1'b1,1'b1};
  
  
//   reg  signed   [7:0    ]  expected_output [0:799 ]  = {126, 124, 120, 120, 124, 127, 127, 127, 127, 58, 224, 150, 128, 170, 4, 90, 127, 90, 0, 166, 128, 166, 0, 90, 127, 90, 0, 166, 130, 166, 252, 86, 126, 106, 36, 202, 130, 128, 128, 128, 128, 186, 4, 74, 126, 127, 127, 127, 127, 120, 116, 120, 126, 127, 127, 127, 126, 74, 4, 186, 130, 128, 128, 128, 128, 202, 32, 102, 127, 102, 28, 198, 132, 128, 128, 128, 128, 136, 140, 136, 132, 128, 128, 128, 128, 198, 32, 106, 127, 86, 0, 170, 130, 150, 220, 54, 126, 127, 127, 127, 127, 70, 0, 186, 130, 128, 128, 128, 128, 202, 32, 102, 127, 102, 28, 198, 130, 128, 128, 128, 128, 128, 128, 128, 130, 182, 252, 70, 126, 127, 127, 127, 127, 54, 224, 154, 128, 154, 228, 58, 126, 127, 127, 127, 126, 127, 127, 127, 127, 58, 224, 150, 128, 170, 4, 90, 126, 90, 4, 170, 128, 150, 224, 58, 124, 127, 127, 127, 127, 120, 116, 120, 124, 127, 127, 127, 127, 58, 224, 150, 128, 170, 4, 90, 127, 90, 0, 166, 130, 166, 252, 86, 126, 106, 36, 202, 132, 128, 128, 128, 128, 202, 36, 106, 127, 86, 0, 170, 130, 150, 220, 54, 126, 127, 127, 127, 127, 70, 252, 182, 130, 128, 128, 128, 130, 136, 136, 132, 132, 132, 132, 132, 130, 132, 136, 136, 132, 128, 128, 128, 130, 198, 28, 102, 127, 102, 32, 202, 130, 128, 128, 128, 128, 186, 0, 70, 126, 127, 127, 127, 127, 54, 224, 154, 128, 154, 224, 54, 124, 127, 127, 127, 127, 54, 224, 154, 128, 154, 224, 54, 124, 127, 127, 127, 127, 54, 220, 150, 128, 170, 0, 86, 126, 106, 36, 202, 132, 128, 128, 128, 128, 202, 32, 102, 127, 102, 28, 198, 132, 128, 128, 128, 130, 136, 136, 132, 132, 132, 132, 132, 130, 132, 136, 136, 130, 128, 128, 128, 130, 182, 252, 70, 126, 127, 127, 127, 127, 54, 224, 154, 128, 154, 224, 54, 126, 127, 127, 127, 127, 70, 0, 186, 130, 128, 128, 128, 128, 202, 36, 106, 127, 86, 252, 166, 128, 166, 0, 90, 126, 90, 4, 170, 130, 150, 220, 54, 126, 127, 127, 127, 127, 70, 0, 186, 128, 128, 128, 128, 128, 186, 0, 70, 127, 127, 127, 127, 127, 70, 0, 186, 128, 128, 128, 128, 128, 186, 4, 74, 126, 127, 127, 127, 126, 120, 120, 124, 124, 124, 124, 124, 124, 124, 124, 124, 126, 124, 120, 120, 126, 127, 127, 127, 126, 74, 4, 186, 128, 128, 128, 128, 128, 186, 4, 74, 127, 127, 127, 127, 127, 127, 127, 127, 126, 74, 4, 186, 128, 128, 128, 128, 128, 186, 0, 70, 126, 127, 127, 127, 127, 54, 220, 150, 128, 170, 4, 90, 126, 90, 4, 170, 128, 150, 224, 58, 126, 127, 127, 127, 127, 127, 127, 127, 126, 74, 4, 186, 130, 128, 128, 128, 128, 202, 36, 106, 127, 86, 0, 170, 130, 150, 220, 54, 124, 127, 127, 127, 127, 54, 220, 150, 128, 170, 0, 86, 127, 106, 32, 198, 132, 128, 128, 128, 130, 136, 136, 132, 132, 132, 132, 132, 132, 132, 132, 132, 130, 132, 136, 136, 132, 128, 128, 128, 128, 198, 32, 106, 127, 86, 0, 170, 128, 150, 224, 58, 126, 127, 127, 127, 126, 127, 127, 127, 127, 58, 224, 150, 128, 170, 0, 86, 126, 106, 36, 202, 130, 128, 128, 128, 128, 186, 4, 74, 127, 127, 127, 127, 127, 127, 127, 127, 127, 74, 0, 182, 128, 128, 128, 128, 130, 128, 128, 128, 128, 198, 32, 106, 127, 86, 252, 166, 130, 166, 252, 86, 126, 106, 36, 202, 130, 128, 128, 128, 128, 186, 0, 70, 126, 127, 127, 127, 127, 54, 220, 150, 128, 170, 0, 86, 126, 106, 36, 202, 130, 128, 128, 128, 128, 186, 0, 70, 127, 127, 127, 127, 127, 70, 252, 182, 130, 128, 128, 128, 128, 136, 140, 136, 130, 128, 128, 128, 128, 182, 0, 74, 127, 127, 127, 127, 127, 127, 127, 127, 127, 74, 0, 182, 130, 128, 128, 128, 130, 136, 136, 132, 130, 132, 136, 136, 132, 128, 128, 128, 130, 198, 28, 102, 127, 102, 28, 198, 130, 128, 128, 128, 130, 128, 128, 128, 128, 198, 32, 106, 127, 86, 0, 170, 128, 150, 224, 58, 124, 127, 127, 127, 126, 120, 120, 124, 126, 124, 120, 120, 126, 127, 127, 127, 126, 74, 4, 186, 130, 128, 128, 128, 128, 202, 36, 106, 127, 86, 252, 166, 130, 166, 252, 86, 126, 106, 36, 202, 132, 128, 128, 128, 128, 202, 32, 102, 127, 102, 32, 202, 132, 128, 128, 128, 128, 202, 32, 102};
//   reg  signed   [7:0    ]   expected_output [0:799 ]  = {8'd126, 8'd124, 8'd120, 8'd120, 8'd124, 8'd127, 8'd127, 8'd127, 8'd127, 8'd58, 8'd224, 8'd150, 8'd128, 8'd170, 8'd4, 8'd90, 8'd127, 8'd90, 8'd0, 8'd166, 8'd128, 8'd166, 8'd0, 8'd90, 8'd127, 8'd90, 8'd0, 8'd166, 8'd130, 8'd166, 8'd252, 8'd86, 8'd126, 8'd106, 8'd36, 8'd202, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd186, 8'd4, 8'd74, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd120, 8'd116, 8'd120, 8'd126, 8'd127, 8'd127, 8'd127, 8'd126, 8'd74, 8'd4, 8'd186, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd202, 8'd32, 8'd102, 8'd127, 8'd102, 8'd28, 8'd198, 8'd132, 8'd128, 8'd128, 8'd128, 8'd128, 8'd136, 8'd140, 8'd136, 8'd132, 8'd128, 8'd128, 8'd128, 8'd128, 8'd198, 8'd32, 8'd106, 8'd127, 8'd86, 8'd0, 8'd170, 8'd130, 8'd150, 8'd220, 8'd54, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd70, 8'd0, 8'd186, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd202, 8'd32, 8'd102, 8'd127, 8'd102, 8'd28, 8'd198, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd128, 8'd128, 8'd128, 8'd130, 8'd182, 8'd252, 8'd70, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd54, 8'd224, 8'd154, 8'd128, 8'd154, 8'd228, 8'd58, 8'd126, 8'd127, 8'd127, 8'd127, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd58, 8'd224, 8'd150, 8'd128, 8'd170, 8'd4, 8'd90, 8'd126, 8'd90, 8'd4, 8'd170, 8'd128, 8'd150, 8'd224, 8'd58, 8'd124, 8'd127, 8'd127, 8'd127, 8'd127, 8'd120, 8'd116, 8'd120, 8'd124, 8'd127, 8'd127, 8'd127, 8'd127, 8'd58, 8'd224, 8'd150, 8'd128, 8'd170, 8'd4, 8'd90, 8'd127, 8'd90, 8'd0, 8'd166, 8'd130, 8'd166, 8'd252, 8'd86, 8'd126, 8'd106, 8'd36, 8'd202, 8'd132, 8'd128, 8'd128, 8'd128, 8'd128, 8'd202, 8'd36, 8'd106, 8'd127, 8'd86, 8'd0, 8'd170, 8'd130, 8'd150, 8'd220, 8'd54, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd70, 8'd252, 8'd182, 8'd130, 8'd128, 8'd128, 8'd128, 8'd130, 8'd136, 8'd136, 8'd132, 8'd132, 8'd132, 8'd132, 8'd132, 8'd130, 8'd132, 8'd136, 8'd136, 8'd132, 8'd128, 8'd128, 8'd128, 8'd130, 8'd198, 8'd28, 8'd102, 8'd127, 8'd102, 8'd32, 8'd202, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd186, 8'd0, 8'd70, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd54, 8'd224, 8'd154, 8'd128, 8'd154, 8'd224, 8'd54, 8'd124, 8'd127, 8'd127, 8'd127, 8'd127, 8'd54, 8'd224, 8'd154, 8'd128, 8'd154, 8'd224, 8'd54, 8'd124, 8'd127, 8'd127, 8'd127, 8'd127, 8'd54, 8'd220, 8'd150, 8'd128, 8'd170, 8'd0, 8'd86, 8'd126, 8'd106, 8'd36, 8'd202, 8'd132, 8'd128, 8'd128, 8'd128, 8'd128, 8'd202, 8'd32, 8'd102, 8'd127, 8'd102, 8'd28, 8'd198, 8'd132, 8'd128, 8'd128, 8'd128, 8'd130, 8'd136, 8'd136, 8'd132, 8'd132, 8'd132, 8'd132, 8'd132, 8'd130, 8'd132, 8'd136, 8'd136, 8'd130, 8'd128, 8'd128, 8'd128, 8'd130, 8'd182, 8'd252, 8'd70, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd54, 8'd224, 8'd154, 8'd128, 8'd154, 8'd224, 8'd54, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd70, 8'd0, 8'd186, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd202, 8'd36, 8'd106, 8'd127, 8'd86, 8'd252, 8'd166, 8'd128, 8'd166, 8'd0, 8'd90, 8'd126, 8'd90, 8'd4, 8'd170, 8'd130, 8'd150, 8'd220, 8'd54, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd70, 8'd0, 8'd186, 8'd128, 8'd128, 8'd128, 8'd128, 8'd128, 8'd186, 8'd0, 8'd70, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd70, 8'd0, 8'd186, 8'd128, 8'd128, 8'd128, 8'd128, 8'd128, 8'd186, 8'd4, 8'd74, 8'd126, 8'd127, 8'd127, 8'd127, 8'd126, 8'd120, 8'd120, 8'd124, 8'd124, 8'd124, 8'd124, 8'd124, 8'd124, 8'd124, 8'd124, 8'd124, 8'd126, 8'd124, 8'd120, 8'd120, 8'd126, 8'd127, 8'd127, 8'd127, 8'd126, 8'd74, 8'd4, 8'd186, 8'd128, 8'd128, 8'd128, 8'd128, 8'd128, 8'd186, 8'd4, 8'd74, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd126, 8'd74, 8'd4, 8'd186, 8'd128, 8'd128, 8'd128, 8'd128, 8'd128, 8'd186, 8'd0, 8'd70, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd54, 8'd220, 8'd150, 8'd128, 8'd170, 8'd4, 8'd90, 8'd126, 8'd90, 8'd4, 8'd170, 8'd128, 8'd150, 8'd224, 8'd58, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd126, 8'd74, 8'd4, 8'd186, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd202, 8'd36, 8'd106, 8'd127, 8'd86, 8'd0, 8'd170, 8'd130, 8'd150, 8'd220, 8'd54, 8'd124, 8'd127, 8'd127, 8'd127, 8'd127, 8'd54, 8'd220, 8'd150, 8'd128, 8'd170, 8'd0, 8'd86, 8'd127, 8'd106, 8'd32, 8'd198, 8'd132, 8'd128, 8'd128, 8'd128, 8'd130, 8'd136, 8'd136, 8'd132, 8'd132, 8'd132, 8'd132, 8'd132, 8'd132, 8'd132, 8'd132, 8'd132, 8'd130, 8'd132, 8'd136, 8'd136, 8'd132, 8'd128, 8'd128, 8'd128, 8'd128, 8'd198, 8'd32, 8'd106, 8'd127, 8'd86, 8'd0, 8'd170, 8'd128, 8'd150, 8'd224, 8'd58, 8'd126, 8'd127, 8'd127, 8'd127, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd58, 8'd224, 8'd150, 8'd128, 8'd170, 8'd0, 8'd86, 8'd126, 8'd106, 8'd36, 8'd202, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd186, 8'd4, 8'd74, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd74, 8'd0, 8'd182, 8'd128, 8'd128, 8'd128, 8'd128, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd198, 8'd32, 8'd106, 8'd127, 8'd86, 8'd252, 8'd166, 8'd130, 8'd166, 8'd252, 8'd86, 8'd126, 8'd106, 8'd36, 8'd202, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd186, 8'd0, 8'd70, 8'd126, 8'd127, 8'd127, 8'd127, 8'd127, 8'd54, 8'd220, 8'd150, 8'd128, 8'd170, 8'd0, 8'd86, 8'd126, 8'd106, 8'd36, 8'd202, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd186, 8'd0, 8'd70, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd70, 8'd252, 8'd182, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd136, 8'd140, 8'd136, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd182, 8'd0, 8'd74, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd127, 8'd74, 8'd0, 8'd182, 8'd130, 8'd128, 8'd128, 8'd128, 8'd130, 8'd136, 8'd136, 8'd132, 8'd130, 8'd132, 8'd136, 8'd136, 8'd132, 8'd128, 8'd128, 8'd128, 8'd130, 8'd198, 8'd28, 8'd102, 8'd127, 8'd102, 8'd28, 8'd198, 8'd130, 8'd128, 8'd128, 8'd128, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd198, 8'd32, 8'd106, 8'd127, 8'd86, 8'd0, 8'd170, 8'd128, 8'd150, 8'd224, 8'd58, 8'd124, 8'd127, 8'd127, 8'd127, 8'd126, 8'd120, 8'd120, 8'd124, 8'd126, 8'd124, 8'd120, 8'd120, 8'd126, 8'd127, 8'd127, 8'd127, 8'd126, 8'd74, 8'd4, 8'd186, 8'd130, 8'd128, 8'd128, 8'd128, 8'd128, 8'd202, 8'd36, 8'd106, 8'd127, 8'd86, 8'd252, 8'd166, 8'd130, 8'd166, 8'd252, 8'd86, 8'd126, 8'd106, 8'd36, 8'd202, 8'd132, 8'd128, 8'd128, 8'd128, 8'd128, 8'd202, 8'd32, 8'd102, 8'd127, 8'd102, 8'd32, 8'd202, 8'd132, 8'd128, 8'd128, 8'd128, 8'd128, 8'd202, 8'd32, 8'd102};
  wire signed   [7:0    ]   filter_out;
  

  reg [7:0]  input_index  ;


  initial
  begin
      clock               = 1'b0       ;  // inicializo clock
      i_reset             = 1'b0       ;  // activo reset (activo por bajo)
      
      // en t = 100 ns
      #100 i_reset        = 1'b1       ;  // desactivo el reset
  end

  always #5 clock = ~clock; // 5ns en bajo y 5ns en alto, periodo de 10ns

  always @(posedge clock) 
      begin
          if (~i_reset)
              begin
                  input_index     <= 0;
                  errors          <= 0;
              end
          else
              begin
                  $display(filter_out);

                  if (input_index == 199)
                      $finish;
                  
                  if (valid)
                    input_index <= input_index + 1;

                  
              end
      end
    
    
      
    filtro_fir # ()
      u_filtro_fir (
          .o_data     (filter_out               ) ,
          .i_data     (filter_input[input_index]) ,
          .i_valid    (valid                    ) ,
          .i_enable   (clock                    ) ,
          .i_reset    (~i_reset                 ) ,
          .clock      (clock                    )
      );

    control #(
        .NB_COUNT (2)
    )

    u_control (
        .o_valid  (valid)       ,
        .i_reset  (~i_reset)     ,
        .clock    (clock)
    );

endmodule
