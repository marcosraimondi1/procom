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
`define SEEDI   'h1AA
`define SEEDQ   'h1FE

module top #(
    // parametros
    parameter NBAUDS    = `NBAUDS   , //! cantidad de baudios del filtro
    parameter SEEDI     = `SEEDI    , //! semilla del prbs9
    parameter SEEDQ     = `SEEDQ    , //! semilla del prbs9
    parameter OS        = `OS       , //! oversampling factor
    parameter NB = 8           //! NB of output
)
(
    // declaracion de puertos input-output
    output  [3:0]   o_led   , //! leds indicadores

    input   [3:0]   i_sw    , //! switches
    input           i_reset , //! reset
    input           clock     //! clock
);


    // variables
    wire            valid              ;   //! senal de validacion
    reg             tx_enable          ;
    reg             rx_enable          ;
    reg  [1:0]      offset             ;   //! offset de muestreo del buffer
    wire            reset              ;   //! reset por alto

    wire [63:0]     error_countI       ;   //! error count
    wire [63:0]     bit_countI         ;   //! bit count
    wire [63:0]     error_countQ       ;
    wire [63:0]     bit_countQ         ;



    // para usar los puertos input del vio
    wire [3:0]      sw                 ;   //! switches a usar
    wire [3:0]      i_sw_vio           ;   //! switches from vio
    wire            i_reset_vio        ;   //! reset from vio
    wire            sel_mux_vio        ;   //! select mux from vio


    // instanciacion de modulos
    // module parte I (en fase)
    system #(
        .SEED(SEEDI)
        ) 
        u_systemI (
            .error_count    (error_countI)  ,
            .bit_count      (bit_countI  )  ,
            .tx_enable      (tx_enable   )  ,
            .rx_enable      (rx_enable   )  ,
            .offset         (offset      )  ,
            .reset          (reset       )  ,
            .clock          (clock       ) 
        );
    // module parte Q (en cuadratura)
    system #(
        .SEED(SEEDQ)
        ) 
        u_systemQ (
            .error_count    (error_countQ)  ,
            .bit_count      (bit_countQ  )  ,
            .tx_enable      (tx_enable   )  ,
            .rx_enable      (rx_enable   )  ,
            .offset         (offset      )  ,
            .reset          (reset       )  ,
            .clock          (clock       ) 
        );
    //! ila
    ila #()
        u_ila (
            .clock          (clock       )   ,
            .bit_countI     (bit_countI  )   ,
            .error_countI   (error_countI)   ,
            .bit_countQ     (bit_countQ  )   ,
            .error_countQ   (error_countQ)   ,
            .latency        (u_systemI.u_ber.min_latency),
            .o_led          (o_led       )
        );
    
    //! vio
    vio #()
        u_vio (
            .clock      (clock      ),
            .o_sel_mux  (sel_mux_vio),
            .o_reset    (i_reset_vio),
            .o_sw       (i_sw_vio   ),
            .i_led      (o_led      )
        );
    
    integer ptr;
    always@(posedge clock or posedge reset) 
    begin
        if (reset) 
            begin
                rx_enable <= 0;
                tx_enable <= 0;
                offset    <= 0;
            end
        else
            begin               
                tx_enable <= sw[0]      ;
                rx_enable <= sw[1]      ;
                offset    <= sw[3:2]    ;
            end
    end

    // asignaciones
    
    assign reset        = (sel_mux_vio) ? ~i_reset_vio : ~i_reset    ;
    assign sw           = (sel_mux_vio) ? i_sw_vio : i_sw            ;
    
    assign o_led[0] = reset                 ;
    assign o_led[1] = tx_enable             ;
    assign o_led[2] = rx_enable             ;
    assign o_led[3] = error_countI == 64'd0 && error_countQ == 64'd0 ;

    endmodule