//! @title      Sistema de Comunicaciones Basico
//! @file       system.v
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

module system #(
    // parametros
    parameter NBAUDS    = `NBAUDS   , //! cantidad de baudios del filtro
    parameter SEED      = `SEED     , //! semilla del prbs9
    parameter OS        = `OS       , //! oversampling factor
    parameter NB = 8                  //! NB of output
)
(
    // declaracion de puertos input-output
    output [   63:0       ] error_count , //! error count
    output [   63:0       ] bit_count   , //! bit count
    output [NB- 1:0       ] o_filter    , //! salida del filtro
    input                   tx_enable   , //! tx enable
    input                   rx_enable   , //! rx enable
    input  [    1:0       ] offset      , //! offset de muestreo del buffer
    input                   reset       , //! reset
    input                   reset_ber   , //! reset del contador de ber
    input                   clock         //! clock
);


    // variables
    wire            valid              ;   //! senal de validacion
    wire            prbs9_out          ;   //! salida del prbs9

    reg  signed [NB-1:0       ] rx_buffer   [OS-1:0]    ; //! buffer de muestras de rx
    wire signed [NB-1:0       ] filter_out              ; //! salida del filtro
    wire signed [NB-1:0       ] rx_sample               ; //! muestra seleccionada por offset
    wire                        rx_bit                  ; //! bit de rx (signo de la muestra)

    // instanciacion de modulos
    //! control
    control #(
            .NB_COUNT (2)
        )
        u_control (
            .o_valid  (valid)   ,
            .i_reset  (reset)   ,
            .clock    (clock)
    );

    //! prbs9
    prbs9 # (
        .SEED   (SEED)
    )
        u_prbs9 (
            .o_bit      (prbs9_out)         ,
            .i_enable   (valid && tx_enable),
            .i_reset    (reset)             ,
            .clock      (clock)     
        );

    //! filtro RC
    filter #()
        u_filter (
            .i_enable  (tx_enable)  ,
            .i_valid   (valid)      ,
            .i_bit     (prbs9_out)  ,
            .o_data    (filter_out) ,
            .reset     (reset)      ,
            .clock     (clock)
        );

    //! ber y sync
    ber # ()
        u_ber (
            .o_errors   (error_count)       ,
            .o_bits     (bit_count)         ,
            .i_rx       (rx_bit)            ,
            .i_ref      (prbs9_out)         ,
            .i_valid    (valid && rx_enable),
            .clock      (clock)             ,
            .i_reset    (reset | reset_ber)
        );

    
    integer ptr;
    always@(posedge clock ) //or posedge reset
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

    // asignaciones
    
    assign rx_sample    = rx_buffer[offset]     ;
    assign rx_bit       = rx_sample[NB-1]       ; // tomo el signo de la muestra como el bit (neg = 1, pos = 0)
    assign o_filter     = filter_out            ;
    endmodule 