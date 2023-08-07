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
    parameter OS        = `OS         //! oversampling factor
)
(
    // declaracion de puertos input-output
    output  [3:0]   o_led   , //! leds indicadores

    input   [3:0]   i_sw    , //! switches
    input           i_reset , //! reset
    input           clock     //! clock
);


    // variables
    reg [OS-1:0]     rxBuffer           ;
    wire reset                          ;
    wire connect_prbs9_to_filter        ;
    wire connect_filter_to_rx           ;
    
    // instanciacion de modulos
    // prbs9
    prbs9 # (
        .SEED   (SEED)
    )
        u_prbs9 (
            .o_bit      (connect_prbs9_to_filter)           ,
            .i_enable   (i_sw[0])                           ,
            .i_reset    (reset)                             ,
            .clock      (clock)                   
        );

    //! filtro RC
    filtro_fir # ()
        u_filtro_fir (
            .o_data     (connect_filter_to_rx)              ,
            .i_data     (connect_prbs9_to_filter ? 1 : -1)  ,
            .i_enable   (i_sw[0])                           ,
            .i_reset    (reset)                             ,
            .clock      (clock)
        );
    
    // // ber counter
    // ber # ()
    //     u_ber (
    //         .o_is_zero  (o_led[3])    ,
    //         .i_rxBuffer (rxBuffer)    ,
    //         .i_enable   (i_sw[1])     ,
    //         .i_reset    (reset)       ,
    //         .clock      (clock)
    //     );

    
    always@(posedge clock or posedge reset) 
    begin
        // verifico si estoy en reset
        if (reset) 
        begin
            // reseteo el sistema
            // rxBuffer       <= {OS{1'b0}}     ;   // rxbuffer en 0
        end
        else
        begin
            // shifteo 
            // rxBuffer        <= {connect_filter_to_rx, rxBuffer[NBAUDS-1:1]} ;

        end
    end

    
    assign reset    = ~i_reset      ;
    assign o_led[0] = reset         ;
    assign o_led[1] = i_sw[0]       ;
    assign o_led[2] = i_sw[1]       ;

    

    endmodule