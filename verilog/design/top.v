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
    parameter OS        = `OS       , //! oversampling factor
    parameter NB_OUTPUT = 8           //! NB of output
)
(
    // declaracion de puertos input-output
    output  [3:0]   o_led   , //! leds indicadores

    input   [3:0]   i_sw    , //! switches
    input           i_reset , //! reset
    input           clock     //! clock
);


    // variables
    wire            valid              ;   // senal de validacion
    reg [1:0    ]   counter            ;

    wire            reset              ;
    wire            prbs9_out          ;
    wire [1:0]      offset             ;


    wire signed [NB_OUTPUT-1:0] filter_out              ;
    reg  signed [NB_OUTPUT-1:0] rx_buffer   [OS-1:0]    ;
    wire signed [NB_OUTPUT-1:0] rx_sample               ;
    wire                        rx_bit                  ; 
    reg         [64-1:0       ] error_count             ; //! error count
    reg         [64-1:0       ] bit_count               ; //! bit count

    // instanciacion de modulos
    // control
    control #(
            .NB_COUNT (2)
        )
        u_control (
            .o_valid  (valid)   ,
            .i_reset  (reset)   ,
            .clock    (clock)
    );

    // prbs9
    prbs9 # (
        .SEED   (SEED)
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
            .i_data     (prbs9_out)     ,
            .i_valid    (valid)         ,
            .i_enable   (i_sw[0])       ,
            .i_reset    (reset)         ,
            .clock      (clock)
        );
    
    integer ptr;
    always@(posedge clock or posedge reset) 
    begin
        if (reset) 
            begin
                for (ptr = 0; ptr < OS; ptr = ptr + 1)
                    rx_buffer[ptr] <= 0;
            end
        else
            begin
                rx_buffer[0] <= filter_out;
                for (ptr = 1; ptr < OS; ptr = ptr + 1)
                    rx_buffer[ptr] <= rx_buffer[ptr-1];
            end
    end

    
    
    assign rx_sample= rx_buffer[offset]     ;
    assign rx_bit   = rx_sample[NB_OUTPUT-1]; // tomo el signo de la muestra como el bit (neg = 1, pos = 0)
    assign reset    = ~i_reset              ;
    
    assign o_led[0] = reset                 ;
    assign o_led[1] = i_sw[0]               ;
    assign o_led[2] = i_sw[1]               ;
    assign offset   = i_sw[3:2]             ;
    assign o_led[3] = error_count == 64'd0  ;

    endmodule