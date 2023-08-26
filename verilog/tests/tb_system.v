//! @title System Testbench
//! @file top_tb
//! @autor Marcos Raimondi
//! @date 06/07/2023
//! @brief Testbench for system module
//! @details Testbench para el sistema de comunicaciones

`define NBAUDS  6
`define OS      4
`define SEED    'h1AA

`timescale 1ns / 100ps // referencia de tiempo / paso mas chico

module tb_system();

    parameter NBAUDS  =   `NBAUDS   ;
    parameter SEED    =   `SEED     ;
    parameter OS      =   `OS       ;

    // puertos del top level    
    reg         tx_enable ; 
    reg         rx_enable ; 
    reg  [1:0]  offset    ;
    reg         i_reset   ;
    reg         clock     ;
    
    wire [63:0]  error_count    ;
    wire [63:0]  bit_count      ;

    wire [8:0]   min_latency    ; //! valor minimo de latencia detectado por el modulo ber
    assign min_latency = u_system.u_ber.min_latency;
    
    initial
    begin
        clock               = 1'b0       ;  // inicializo clock
        i_reset             = 1'b0       ;  // activo reset (activo por bajo)
        
        offset              = 2'b00      ;  // offset = 0
        tx_enable           = 1'b0       ;  // deshabilito tx
        rx_enable           = 1'b0       ;  // deshabilito rx

        // en t = 100 ns
        #100 i_reset        = 1'b1       ;  // desactivo el reset

        // en t = 200 ns
        #100 tx_enable      = 1'b1       ;  // habilito tx
        #100 rx_enable      = 1'b1       ;  // habilito rx
        
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
            $display("System Latency = %d", min_latency);
            $display("----------------------------------------");
            $finish;
        end
    end

    // se instancia el modulo
    system #(
            .NBAUDS (NBAUDS)    ,
            .SEED   (SEED)      ,
            .OS     (OS)
        )
        u_system (
            .error_count    (error_count)   ,
            .bit_count      (bit_count  )   ,
            .rx_enable      (rx_enable)     ,
            .tx_enable      (tx_enable)     ,
            .offset         (offset)        ,
            .reset          (~i_reset)      ,
            .clock          (clock)
        );
endmodule
