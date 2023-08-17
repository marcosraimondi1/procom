`timescale 1ns / 100ps

module tb_control();

    reg         i_reset   ;
    reg         clock     ; 
    wire        valid     ;
    
    initial
    begin
        clock               = 1'b0       ;  // inicializo clock
        i_reset             = 1'b0       ;  // activo reset (activo por bajo)
        
        // en t = 100 ns
        #100 i_reset        = 1'b1       ;  // desactivo el reset

        #10000 $finish                   ;
    end

    always #5 clock = ~clock; // 5ns en bajo y 5ns en alto, periodo de 10ns

    // se instancia el modulo
    control #(
            .NB_COUNT (2)
        )
        u_control (
            .o_valid  (valid)       ,
            .i_reset  (~i_reset)     ,
            .clock    (clock)
        );

endmodule