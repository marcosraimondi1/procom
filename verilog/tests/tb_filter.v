`timescale 1ns / 100ps
`define SEED    'h1AA

module tb_filter #(
    SEED = `SEED
)();
    reg clock;
    reg i_reset;
    wire reset;


    wire signed [7:0]     filter_out              ;
    reg  signed [7:0]     rx_buffer   [3:0]       ;
    wire                  prbs9_out               ;
    wire                  rx_bit                  ; 
    wire                  valid                   ;
    reg   [63:0]          counter                 ;

    wire  [63:0         ] error_count             ; //! error count
    wire  [63:0         ] bit_count               ; //! bit count

    assign rx_bit = rx_buffer[0][7];

    initial
    begin
        clock               = 1'b0       ;  // inicializo clock
        i_reset             = 1'b0       ;  // activo reset (activo por bajo)
        
        // en t = 100 ns
        #100 i_reset        = 1'b1       ;  // desactivo el reset
    end

    always #5 clock = ~clock; // 5ns en bajo y 5ns en alto, periodo de 10ns

    integer i;
    always @(posedge clock) 
        begin
            if (reset)
                begin
                    counter <= 0;
                end
            else
                begin
                    counter <= counter + 1;

                    rx_buffer[0] <= filter_out;

                    for (i = 1; i < 4; i=i+1)
                        rx_buffer[i] <= rx_buffer[i-1];
                    
                    if (counter == 2000)
                        $finish;
                end
        end

    prbs9 # (
        .SEED   (SEED)
    )
        u_prbs9 (
            .o_bit      (prbs9_out)     ,
            .i_enable   (valid)         ,
            .i_reset    (reset)         ,
            .clock      (clock)     
        );

    control #(
            .NB_COUNT (2)
        )
        u_control (
            .o_valid  (valid)     ,
            .i_reset  (reset)     ,
            .clock    (clock)
        );

    filter #()
        u_filter (
            .i_enable  (i_reset)   ,
            .i_valid   (valid)     ,
            .i_bit     (prbs9_out) ,
            .o_data     (filter_out),
            .reset     (reset)     ,
            .clock     (clock)
        );

    ber # ()
        u_ber (
            .o_errors   (error_count)   ,
            .o_bits     (bit_count)     ,
            .i_rx       (rx_bit)        ,
            .i_ref      (prbs9_out)     ,
            .i_valid    (valid)         ,
            .clock      (clock)         ,
            .i_reset    (reset)
        );
    
    assign reset    = ~i_reset        ;
endmodule