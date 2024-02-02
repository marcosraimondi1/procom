module top #(
    parameter NB_GPIOS  = 32        ,
    parameter RAM_WIDTH = 8         ,
    parameter RAM_DEPTH = (2**16)   ,
    parameter NB_C0M    = 7         ,
    parameter NB_DATA   = 24        ,
    parameter NB_INST   = 32        ,
    parameter IMAGE_WIDTH  = 50     ,
    parameter IMAGE_HEIGHT = 50     ,
    parameter KERNEL_WIDTH = 3
)
(
    // declaracion de puertos input-output
    // output  [2:0]   o_led       , //! leds indicadores
    // output  [2:0]   o_led_rgb0  ,
    // output  [2:0]   o_led_rgb1  ,
    output          out_tx_uart , //! tx uart

    input           i_reset     , //! reset
    input           clk100      , //! clk100
    input           in_rx_uart    //! rx uart
);

    // para el micro
    wire                        clockdsp    ;   //! clock de la aplicacion
    wire                        locked      ;   //! lock del clock
    wire [NB_GPIOS - 1 : 0]     gpo0        ;   //! gpio from micro to fpga
    wire [NB_GPIOS - 1 : 0]     gpi0        ;   //! gpio from fpga to micro

    wire reset;
   
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
   
    integration #(
        .NB_GPIOS(NB_GPIOS)    ,
        .RAM_WIDTH(RAM_WIDTH)    ,
        .RAM_DEPTH(RAM_DEPTH) ,
        .NB_C0M(NB_C0M)       ,
        .NB_DATA(NB_DATA)     ,
        .NB_INST(NB_INST)     ,
        .IMAGE_WIDTH(IMAGE_WIDTH) ,
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .KERNEL_WIDTH(KERNEL_WIDTH)
    ) u_integration (
        .reset(reset)     ,
        .clock(clk100)     ,
        .gpi0(gpi0)       ,
        .gpo0(gpo0)
    );

    // asignaciones
    assign reset    = ~i_reset  ;


endmodule
