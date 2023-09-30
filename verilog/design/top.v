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
//!  - clk100         : reloj del sistema
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
    parameter NB_GPIOS  = 32        , //! NB of GPIOs
    parameter NB        = 8           //! NBits of output
)
(
    // declaracion de puertos input-output
    output  [3:0]   o_led       , //! leds indicadores
    output  [2:0]   o_led_rgb0  ,
    output  [2:0]   o_led_rgb1  ,
    output  [2:0]   o_led_rgb2  ,
    output  [2:0]   o_led_rgb3  ,
    output          out_tx_uart , //! tx uart

    input   [3:0]   i_sw        , //! switches
    input           i_reset     , //! reset
    input           clk100      , //! clk100
    input           in_rx_uart    //! rx uart
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

    // para el micro
    wire                        clockdsp    ;   //! clock de la aplicacion
    wire                        locked      ;   //! lock del clock
    wire [NB_GPIOS - 1 : 0]     gpo0        ;   //! gpio output
    wire [NB_GPIOS - 1 : 0]     gpi0        ;   //! gpio input

    // para usar los puertos input del vio
    wire [3:0]      sw                 ;   //! switches a usar
    wire [3:0]      i_sw_vio           ;   //! switches from vio
    wire            i_reset_vio        ;   //! reset from vio
    wire            sel_mux_vio        ;   //! select mux from vio


    // instanciacion de modulos
    uArtix735
        u_micro
        (
            .clock100         (clockdsp    ),  // Clock aplicacion
            .gpio_rtl_tri_o   (gpo0        ),  // GPIO
            .gpio_rtl_tri_i   (gpi0        ),  // GPIO
            .reset            (in_reset    ),  // Hard Reset
            .sys_clock        (clk100      ),  // Clock de FPGA
            .o_lock_clock     (locked      ),  // Senal Lock Clock
            .usb_uart_rxd     (in_rx_uart  ),  // UART
            .usb_uart_txd     (out_tx_uart )   // UART
        );
    
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
            .clock          (clk100      ) 
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
            .clock          (clk100      ) 
        );
    
    
    //! vio
    vio #()
        u_vio (
            .clk_0          (clockdsp       ),
            .probe_in0_0    (bit_countI     ),
            .probe_in1_0    (error_countI   ),
            .probe_in2_0    (bit_countQ     ),
            .probe_in3_0    (error_countQ   ),
            .probe_in3_0    (o_led          ),
            .probe_out0_0   (i_reset_vio    ),
            .probe_out1_0   (i_sw_vio       ),
            .probe_out2_0   (sel_mux_vio    )
        );
    
    integer ptr;
    always@(posedge clk100 or posedge reset) 
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
    
    assign reset    = (sel_mux_vio) ? ~i_reset_vio  : ~i_reset  ;
    assign sw       = (sel_mux_vio) ? i_sw_vio      : i_sw      ;
    
    assign o_led[0] = reset                 ;
    assign o_led[1] = tx_enable             ;
    assign o_led[2] = rx_enable             ;
    assign o_led[3] = error_countI == 64'd0 && error_countQ == 64'd0 ;

    endmodule
