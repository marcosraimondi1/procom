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

module tb_top();

    parameter NBAUDS  =   `NBAUDS   ;
    parameter SEED    =   `SEED     ;
    parameter OS      =   `OS       ;

    // puertos del top level    
    wire [3:0]  o_led     ;
    reg  [3:0]  i_sw      ;
    reg         i_reset   ;
    reg         clock     ;
    
    // cuenta de ber
    wire [63:0]  error_count = u_top.u_ber.error_count ;
    wire [63:0]  bit_count = u_top.u_ber.bit_count     ;

    initial
    begin
        i_sw                = 4'b0000    ;  // swithces en 0
        clock               = 1'b0       ;  // inicializo clock
        i_reset             = 1'b0       ;  // activo reset (activo por bajo)
        
        // en t = 100 ns
        #100 i_reset        = 1'b1       ;  // desactivo el reset
        // en t = 200 ns
        #100 i_sw[0]        = 1'b1       ;  // habilito tx
        #100 i_sw[1]        = 1'b1       ;  // habilito rx
        #100 i_sw[3:2]      = 2'b00      ;  // offset = 0
        
    end

    always #5 clock = ~clock; // 5ns en bajo y 5ns en alto, periodo de 10ns

    always @(posedge clock)
    begin
        if (bit_count == 2000)
        begin
            $display("----------------------------------------");
            $display("Bit Count = %d", bit_count);
            $display("Error Count = %d", error_count);
            $display("BER = %f", error_count / bit_count);
            $display("----------------------------------------");
            $finish;
        end
    end

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
