//! @title Top Testbench
//! @file top_tb
//! @autor Marcos Raimondi
//! @date 06/07/2023
//! @brief Testbench for top module
//! @details Testbench para el sistema de comunicaciones

`define NBAUDS  6
`define OS      4
`define SEED    'h1AA

`timescale 1ns / 100ps // referencia de tiempo / paso mas chico

module tb_top(); // testbench no tiene puertos

    parameter NBAUDS  =   `NBAUDS   ;
    parameter SEED    =   `SEED     ;
    parameter OS      =   `OS       ;
    
    // se definen las variables que son entradas y salidas del modulo
    wire [3:0]  o_led     ;
    reg  [3:0]  i_sw      ;
    reg         i_reset   ;
    reg         clock     ;
    
    wire [8:0] tb_prbs9 ;
    wire tb_prbs9_o_bit ;
    wire [7:0] tb_filtro_fir_i_data;
    wire [7:0] tb_filtro_fir_o_data;
    wire [1:0] tb_f_selector;
        
    assign tb_prbs9             = tb_top.u_top.u_prbs9.shiftregister    ;
    assign tb_prbs9_o_bit       = tb_top.u_top.connect_prbs9_to_filter  ;
    assign tb_filtro_fir_i_data = tb_top.u_top.u_filtro_fir.i_data      ;
    assign tb_f_selector        = tb_top.u_top.u_filtro_fir.f_selector  ;
    assign tb_filtro_fir_o_data = tb_top.u_top.u_filtro_fir.o_data      ;

    initial
    begin
        // asignaciones bloqueantes que se ejecutan una sola vez
        i_sw                = 4'b0000    ;  // swithces en 0
        clock               = 1'b0       ;  // inicializo clock
        i_reset             = 1'b0       ;  // activo reset (activo por bajo)
        
        // en t = 100 ns
        #100 i_reset        = 1'b1       ;  // desactivo el reset
        // en t = 200 ns
        #100 i_sw[0]        = 1'b1       ;  // habilito tx

        #10000 $finish                 ;  // finaliza la simulacion
    end

    always #5 clock = ~clock; // 5ns en bajo y 5ns en alto, periodo de 10ns

    // se instancia el modulo
    top #(
            .NBAUDS (NBAUDS)    ,
            .SEED   (SEED)      ,
            .OS     (OS)
        )
        u_top (
            .o_led    (o_led)    ,
            .i_sw     (i_sw)     ,
            .i_reset  (i_reset)  ,
            .clock    (clock)
        );

endmodule
