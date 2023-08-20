`timescale 1ns / 100ps
`define SEED    'h1AA

module tb_ber #(
    SEED = `SEED
)();
    reg clock;
    reg i_reset;
    wire reset;

    wire                  prbs9_out               ;
    wire                  rx_bit                  ; 
    wire  [63:0         ] error_count             ; //! error count
    wire  [63:0         ] bit_count               ; //! bit count
    
    reg   [10:0]           delay_buffer            ;
    reg   [63:0]          counter                 ;


    initial
    begin
        clock               = 1'b0       ;  // inicializo clock
        i_reset             = 1'b0       ;  // activo reset (activo por bajo)
        
        // en t = 100 ns
        #100 i_reset        = 1'b1       ;  // desactivo el reset
    end

    always #5 clock = ~clock; // 5ns en bajo y 5ns en alto, periodo de 10ns

    always @(posedge clock) 
        begin
            if (reset)
                begin
                    delay_buffer <= 0;
                    counter <= 0;
                end
            else
                begin
                    delay_buffer <= {delay_buffer[9:0], prbs9_out};
                    counter <= counter + 1;
                    if (bit_count == 10000)
                        begin
                             $display("Error count: %d", error_count);
                             $display("Bit count: %d", bit_count);
                            $finish;
                        end
                end
        end

    prbs9 # (
        .SEED   (SEED)
    )
        u_prbs9 (
            .o_bit      (prbs9_out)     ,
            .i_enable   (i_reset)         ,
            .i_reset    (reset)       ,
            .clock      (clock)     
        );

    ber # ()
        u_ber (
            .o_errors   (error_count)   ,
            .o_bits     (bit_count)     ,
            .i_rx       (rx_bit)        ,
            .i_ref      (prbs9_out)     ,
            .i_valid    (i_reset)         ,
            .clock      (clock)         ,
            .i_reset    (reset)
        );

    assign rx_bit = delay_buffer[10];
    assign reset = ~i_reset;
endmodule