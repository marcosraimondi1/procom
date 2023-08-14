//! @title      Sistema de Comunicaciones Basico
//! @file       top.v
//! @autor      Marcos Raimondi
//! @date       06/08/2023
//! @brief      Sistema de Comunicaciones PRBS9+BPSK+RC+BER

//! @description:
//! Puertos:
//!  - i_sw     [3:0]: 
//                     [0]      -> TX enable
//!                    [1]      -> RX enable 
//!                    [3:2]    -> selecciona offset de muestreo en RX
//!  - i_reset       : reset del sistema, asincrono, normal-cerrado (activo por bajo) 
//!  - clock         : reloj del sistema
//!  - o_led    [3:0]: 
//                     [0]      -> reset
//!                    [1]      -> TX enable
//!                    [2]      -> RX enable
//!                    [3]      -> BER = 0

`define NBAUDS  6
`define OS      4
`define SEED    'h1AA

module top #(
    parameter NBAUDS    = `NBAUDS   , //! cantidad de baudios del filtro
    parameter SEED      = `SEED     , //! semilla del prbs9
    parameter OS        = `OS       ,  //! oversampling factor
    parameter NB_OUTPUT = 8         , //! NB of output
)
(
    // declaracion de puertos input-output
    output  [3:0]   o_led   , //! leds indicadores

    input   [3:0]   i_sw    , //! switches
    input           i_reset , //! reset
    input           clock     //! clock
);


    // variables
    reg             valid              ;   // senal de validacion
    reg [1:0    ]   counter            ;
    
    wire            reset              ;
    wire            prbs9_out          ;


    wire signed [NB_OUTPUT-1:0] filter_out ;
    
    // instanciacion de modulos
    // prbs9
    prbs9 # (
        .SEED   (SEED)
        .NB
    )
        u_prbs9 (
            .o_bit      (prbs9_out)     ,
            .i_enable   (valid)         ,
            .i_reset    (reset)         ,
            .clock      (clock)     
        );

    //! filtro RC
    filtro_fir # ()
        u_filtro_fir (
            .o_data     (filter_out)    ,
            .i_data     (prbs9_out ? 8'b01111111 : 8'b00000000) ,
            .i_valid    (valid)         ,
            .i_enable   (i_sw[0])       ,
            .i_reset    (reset)         ,
            .clock      (clock)
        );
    
    // TODO : instancias modulo BER
    
    always@(posedge clock or posedge reset) 
    begin
        if (reset) 
        begin
            valid   <= 1'b0     ;
            counter <= 2'b00    ;
        end
        else
        begin
            if (i_sw[0])
            begin
                // oversampling
                if (counter == OS-1)
                begin
                    // doy senal de activacion
                    valid   <= 1'b1     ;
                    counter <= 2'b00    ;
                end
                else
                begin 
                    valid   <= 1'b0             ;
                    counter <= counter + 1'd1   ;
                end
                
                
            end
            else
            begin
                valid   <= valid    ;
                counter <= counter  ;
            end
        end
    end

    
    assign reset    = ~i_reset      ;
    assign o_led[0] = reset         ;
    assign o_led[1] = i_sw[0]       ;
    assign o_led[2] = i_sw[1]       ;

    

    endmodule