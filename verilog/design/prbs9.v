//! @title      Pseudo Random Binary Sequence Generator (PRBS9)
//! @file       prsb9.v
//! @autor      Marcos Raimondi
//! @date       06/08/2023
//! @brief      Modela un generador de prbs9
//! 
//! @description
//! Puertos:
//!  - i_enable [3:0]: habilita el prsb9 
//!  - i_reset       : reset del sistema
//!  - clock         : reloj del sistema

`define SEED    'h1AA
module prbs9 #(
    parameter SEED = `SEED
)
(
    output o_bit   , //! bit de salida
    input  i_enable, //! habilitacion
    input  i_reset , //! reset
    input  clock     //! clock
);

    // variables
    reg [0:8] shiftregister ;
    reg       feedback      ;

    always@(posedge clock) 
    begin
        if(i_reset)
        begin
            shiftregister   <=  SEED  ;
        end    
        else if (i_enable)
        begin
            feedback = shiftregister[8] ^ shiftregister[4] ;  // XOR de los bits 8 y 4
            // shifteo y cargo el nuevo bit XOR de los bits 8 y 4
            shiftregister   <=  {feedback, shiftregister[0:7]} ;
        end
        else
        begin
            // conserva su valor
            shiftregister   <=  shiftregister       ;
        end
    end

    assign      o_bit       =   shiftregister[8]                  ;  // la salida es el ultimo bit del shift register


endmodule