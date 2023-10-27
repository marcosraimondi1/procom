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
    parameter NB        = 8         , //! NBits of output,
    parameter RAM_WIDTH = 32        ,
    parameter RAM_DEPTH = 1024      ,
    parameter NB_C0M    = 8         ,
    parameter NB_DATA   = 24        ,
    parameter NB_BER    = 64        ,
    parameter NB_INST   = 32
)
(
    // declaracion de puertos input-output
    output  [2:0]   o_led       , //! leds indicadores
    output  [2:0]   o_led_rgb0  ,
    output  [2:0]   o_led_rgb1  ,
    output          out_tx_uart , //! tx uart

    input           i_reset     , //! reset
    input           clk100      , //! clk100
    input           in_rx_uart    //! rx uart
);


    // variables
    wire            tx_enable          ;
    wire            rx_enable          ;
    wire  [1:0]     offset             ;   //! offset de muestreo del buffer
    wire            reset              ;   //! reset por alto
    wire  [NB-1:0]  filter_out_I       ;   //! salida del filtro
    wire  [NB-1:0]  filter_out_Q       ;   //! salida del filtro

    wire [63:0]     error_countI       ;   //! error count
    wire [63:0]     bit_countI         ;   //! bit count
    wire [63:0]     error_countQ       ;
    wire [63:0]     bit_countQ         ;

    // para el micro
    wire                        clockdsp    ;   //! clock de la aplicacion
    wire                        locked      ;   //! lock del clock
    wire [NB_GPIOS - 1 : 0]     gpo0        ;   //! gpio from micro to fpga
    wire [NB_GPIOS - 1 : 0]     gpi0        ;   //! gpio from fpga to micro

    // para usar los puertos input del vio
    wire            i_reset_vio        ;   //! reset from vio
    wire            sel_mux_vio        ;   //! select mux from vio

    wire               reset_from_micro;

    // para file register y bram
    wire  [NB_INST-1:0]        data_log_from_mem_to_fr    ;
    wire                        mem_full_from_mem_to_fr    ;
    wire                       run_log_from_fr_to_mem      ;
    wire                       read_log_from_fr_to_mem     ;
    wire  [       14:0]        addr_log_from_fr_to_mem     ;

    wire  [32-1:0] data_tx_to_mem;

    localparam [NB_C0M -1:0] RESET    = 8'b00000001          ; 
    localparam [NB_C0M -1:0] EN_TX    = 8'b00000010          ;
    localparam [NB_C0M -1:0] EN_RX    = 8'b00000011          ;
    localparam [NB_C0M -1:0] PH_SEL   = 8'b00000100          ;
    localparam [NB_C0M -1:0] RUN_MEM  = 8'b00000101          ;
    localparam [NB_C0M -1:0] RD_MEM   = 8'b00000110          ; // lee la memoria, en el campo data va la direccion
    localparam [NB_C0M -1:0] IS_FULL  = 8'b00000111          ; // ver si esta llena
    localparam [NB_C0M -1:0] BER_S_I  = 8'b00001000          ; // leer samples
    localparam [NB_C0M -1:0] BER_S_Q  = 8'b00001001          ; 
    localparam [NB_C0M -1:0] BER_E_I  = 8'b00001010          ; // leer errores
    localparam [NB_C0M -1:0] BER_E_Q  = 8'b00001011          ;
    localparam [NB_C0M -1:0] BER_HIGH = 8'b00001100          ; // para leer la parte alta de la BER (lee la parte alta de la ultima lectura)

    // instanciacion de modulos
    uArtix735
        u_micro
        (
            .clock100         (clockdsp    ),  // Clock aplicacion
            .gpio_rtl_tri_o   (gpo0        ),  // GPIO
            .gpio_rtl_tri_i   (gpi0        ),  // GPIO
            .reset            (i_reset     ),  // Hard Reset
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
            .error_count (error_countI           ),
            .bit_count   (bit_countI             ),
            .tx_enable   (tx_enable              ),
            .rx_enable   (rx_enable              ),
            .offset      (offset                 ), // phase
            .reset       (reset                  ),
            .clock       (clk100                 ),
            .reset_ber   (reset_from_micro       ),
            .o_filter    (filter_out_I           )           
        );
        
    // module parte Q (en cuadratura)
    system #(
        .SEED(SEEDQ)
        ) 
        u_systemQ (
            .error_count (error_countQ            ),
            .bit_count   (bit_countQ              ),
            .tx_enable   (tx_enable               ),
            .rx_enable   (rx_enable               ),
            .offset      (offset                  ),
            .reset       (reset                   ),
            .clock       (clk100                  ),
            .reset_ber   (reset_from_micro        ),
            .o_filter    (filter_out_Q            ) 
        );
    
    
    //! vio
    vio #()
        u_vio (
            .clk_0          (clk100         ),
            .probe_in0_0    (bit_countI     ),
            .probe_in1_0    (error_countI   ),
            .probe_in2_0    (bit_countQ     ),
            .probe_in3_0    (error_countQ   ),
            .probe_in4_0    (o_led          ),
            .probe_in5_0    (o_led_rgb0     ), // agregar esto al vio
            .probe_in6_0    (o_led_rgb1     ), // agregar esto al vio
            .probe_out0_0   (i_reset_vio    ),
            .probe_out1_0   (sel_mux_vio    ) // select reset
        );

    file_register #(
            .NB_C0M  (NB_C0M ), //! numero de bits de comando de la instruccion
            .NB_DATA (NB_DATA), //! numero de bits de la data de la instruccion
            .NB_BER  (NB_BER ), //! numero de bits de ber
            .NB_INST (NB_INST)  //! numero de bits de instruccion
        ) u_file_register
        (
            .i_cmd_from_micro    (gpo0                      ),    //! gpo0, comando del micro hacia el file register
            .o_data_to_micro     (gpi0                      ),    //! gpi0, datos del file register hacia el micro
            .i_mem_full          (mem_full_from_mem_to_fr   ),    //! entrada del sistema de memoria llena
            .i_ber_samp_I        (bit_countI                ),    //! entrada de la cantidad de muestras I del BER
            .i_ber_samp_Q        (bit_countQ                ),    //! entrada de la cantidad de muestras Q del BER
            .i_ber_error_I       (error_countI              ),    //! entrada de la cantidad de errores I del BER
            .i_ber_error_Q       (error_countQ              ),    //! entrada de la cantidad de errores Q del BER
            .i_data_log_from_mem (data_log_from_mem_to_fr   ),    //! entrada de los datos de log desde la memoria
            .o_reset             (reset_from_micro          ),    //! salida de reset del file register hacia el sistema
            .o_enbTx             (tx_enable                 ),
            .o_enbRx             (rx_enable                 ),
            .o_phase_sel         (offset                    ),
            .o_run_log           (run_log_from_fr_to_mem    ),
            .o_read_log          (read_log_from_fr_to_mem   ),
            .o_addr_log_to_mem   (addr_log_from_fr_to_mem   ),
            .clock               (clk100                    ),
            .reset               (reset                     )
        );
    
    //! bram
    bram #(
    .RAM_WIDTH(RAM_WIDTH),
    .RAM_DEPTH(RAM_DEPTH)
    ) u_bram (
        .clk                  (clk100                       ),
        .reset                (reset                        ),
        .i_run_log            (run_log_from_fr_to_mem       ),
        .i_read_log           (read_log_from_fr_to_mem      ),
        .i_data_tx_to_mem     (data_tx_to_mem               ),
        .i_addr_log_to_mem    (addr_log_from_fr_to_mem      ),
        .o_data_log_from_mem  (data_log_from_mem_to_fr      ),
        .o_mem_full           (mem_full_from_mem_to_fr      )
    );
    
    // asignaciones
    assign reset    = (sel_mux_vio) ? ~i_reset_vio  : ~i_reset  ;

    assign o_led[0] = reset     ;
    assign o_led[1] = tx_enable ;
    assign o_led[2] = rx_enable ;

    assign data_tx_to_mem = {{16{1'b0}} , filter_out_Q , filter_out_I};
 
    assign o_led_rgb0[0] = run_log_from_fr_to_mem   ;
    assign o_led_rgb0[1] = read_log_from_fr_to_mem  ;
    assign o_led_rgb0[2] = mem_full_from_mem_to_fr  ;

    assign o_led_rgb1[0] = offset[0]  ;
    assign o_led_rgb1[1] = offset[1]  ;
    assign o_led_rgb1[2] = 1'b0       ;

  // calcula cuantos bits de direccion hacen falta para direccionar la memoria
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction  

endmodule
