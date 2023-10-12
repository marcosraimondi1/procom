`timescale 1ns / 100ps

module tb_file_register
#(
    parameter NB_C0M  =  8,
    parameter NB_DATA = 24,
    parameter NB_BER  = 64,
    parameter NB_INST = 32
)
(

);
reg                          clk                 ;    //! Clock
reg                          reset               ;    //! Reset

reg     [NB_INST-1:0]        i_cmd_from_micro    ;   //! gpi0
wire    [NB_INST-1:0]        o_data_to_micro     ;   //! gpo0
reg                          i_mem_full          ;
reg     [NB_BER -1:0]        i_ber_samp_I        ;
reg     [NB_BER -1:0]        i_ber_samp_Q        ;
reg     [NB_BER -1:0]        i_ber_error_I       ;
reg     [NB_BER -1:0]        i_ber_error_Q       ;
reg     [NB_INST-1:0]        i_data_log_from_mem ;
wire                         o_reset_from_micro  ;
wire                         o_enbTx             ;
wire                         o_enbRx             ;
wire    [        1:0]        o_phase_sel         ;

wire                         o_run_log           ;
wire                         o_read_log          ;
wire    [       14:0]        o_addr_log_to_mem   ;


//!----------------Comandos disponibles----------------
localparam [NB_C0M -1:0] RESET   = 8'b00000001;
localparam [NB_C0M -1:0] EN_TX   = 8'b00000010;
localparam [NB_C0M -1:0] EN_RX   = 8'b00000011;
localparam [NB_C0M -1:0] PH_SEL  = 8'b00000100;
localparam [NB_C0M -1:0] RUN_MEM = 8'b00000101;
localparam [NB_C0M -1:0] RD_MEM  = 8'b00000110; // lee la memoria
localparam [NB_C0M -1:0] IS_FULL = 8'b00000111; // ver si esta llena
localparam [NB_C0M -1:0] BER_S_I = 8'b00001000; // leer samples
localparam [NB_C0M -1:0] BER_S_Q = 8'b00001001; 
localparam [NB_C0M -1:0] BER_E_I = 8'b00001010; // leer errores
localparam [NB_C0M -1:0] BER_E_Q = 8'b00001011;
localparam [NB_C0M -1:0] BER_HIGH = 8'b00001100; // para leer la parte alta de la BER (lee la parte alta de la ultima lectura)

initial begin
    clk                 = 0     ;
    reset               = 0     ;
    i_cmd_from_micro    = 0     ;
    i_mem_full          = 1'b0  ;
    i_ber_error_I       = 64'b0 ;
    i_ber_error_Q       = 64'b0 ;
    i_ber_samp_I        = 64'b0 ;
    i_ber_samp_Q        = 64'b0 ;
    
    #2  reset           = 1     ;
    #2  reset           = 0     ;
    #2;
    // prueba de reset
    //                    {CMD  , ENABLE, DATA                    };
    #2 i_cmd_from_micro = {RESET, 1'b0  , {(NB_DATA-2){1'b0}},1'b1}; // reset on
    #2 i_cmd_from_micro = {RESET, 1'b1  , {(NB_DATA-2){1'b0}},1'b1}; // reset on
    #2 i_cmd_from_micro = {RESET, 1'b0  , {(NB_DATA-2){1'b0}},1'b1}; // reset on

    #2 i_cmd_from_micro = {RESET, 1'b0  , {(NB_DATA-2){1'b0}},1'b0}; // reset off
    #2 i_cmd_from_micro = {RESET, 1'b1  , {(NB_DATA-2){1'b0}},1'b0}; // reset off
    #2 i_cmd_from_micro = {RESET, 1'b0  , {(NB_DATA-2){1'b0}},1'b0}; // reset off
    
    // prueba de enables
    #2 i_cmd_from_micro = {EN_TX, 1'b0  , {(NB_DATA-2){1'b0}},1'b1}; // enables on
    #2 i_cmd_from_micro = {EN_TX, 1'b1  , {(NB_DATA-2){1'b0}},1'b1}; // enables on
    #2 i_cmd_from_micro = {EN_TX, 1'b0  , {(NB_DATA-2){1'b0}},1'b1}; // enables on

    #2 i_cmd_from_micro = {EN_RX, 1'b0  , {(NB_DATA-2){1'b0}},1'b1}; // enables on
    #2 i_cmd_from_micro = {EN_RX, 1'b1  , {(NB_DATA-2){1'b0}},1'b1}; // enables on
    #2 i_cmd_from_micro = {EN_RX, 1'b0  , {(NB_DATA-2){1'b0}},1'b1}; // enables on

    // prueba de fases
    #2 i_cmd_from_micro = {PH_SEL, 1'b0  , {(NB_DATA-3){1'b0}},1'b1,1'b1}; // phase 3
    #2 i_cmd_from_micro = {PH_SEL, 1'b1  , {(NB_DATA-3){1'b0}},1'b1,1'b1}; // phase 3
    #2 i_cmd_from_micro = {PH_SEL, 1'b0  , {(NB_DATA-3){1'b0}},1'b1,1'b1}; // phase 3

    #2 i_cmd_from_micro = {PH_SEL, 1'b0  , {(NB_DATA-3){1'b0}},1'b1,1'b0}; // phase 2
    #2 i_cmd_from_micro = {PH_SEL, 1'b1  , {(NB_DATA-3){1'b0}},1'b1,1'b0}; // phase 2
    #2 i_cmd_from_micro = {PH_SEL, 1'b0  , {(NB_DATA-3){1'b0}},1'b1,1'b0}; // phase 2

    // prueba de mem full
    #2 i_mem_full = 1'b1;
    #2 i_cmd_from_micro = {IS_FULL, 1'b0  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {IS_FULL, 1'b1  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {IS_FULL, 1'b0  , {(NB_DATA-1){1'b0}}}; 

    #2 i_mem_full = 1'b0;
    #2 i_cmd_from_micro = {IS_FULL, 1'b0  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {IS_FULL, 1'b1  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {IS_FULL, 1'b0  , {(NB_DATA-1){1'b0}}}; 

    // read ber
    #2 i_mem_full = 1'b1;
    i_ber_error_I       = {{32{1'b1}}, {30{1'b0}}, 2'b11};
    i_ber_error_Q       = 64'b01010 ;
    i_ber_samp_I        = {32'b1, 32'd15};
    i_ber_samp_Q        = 64'b11110 ;

    // leo parte baja
    #2 i_cmd_from_micro = {BER_E_I, 1'b0   , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {BER_E_I, 1'b1   , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {BER_E_I, 1'b0   , {(NB_DATA-1){1'b0}}}; 
    // leo parte alta
    #2 i_cmd_from_micro = {BER_HIGH, 1'b0  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {BER_HIGH, 1'b1  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {BER_HIGH, 1'b0  , {(NB_DATA-1){1'b0}}}; 

    // leo parte baja
    #2 i_cmd_from_micro = {BER_S_I, 1'b0   , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {BER_S_I, 1'b1   , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {BER_S_I, 1'b0   , {(NB_DATA-1){1'b0}}}; 
    // leo parte alta
    #2 i_cmd_from_micro = {BER_HIGH, 1'b0  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {BER_HIGH, 1'b1  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {BER_HIGH, 1'b0  , {(NB_DATA-1){1'b0}}}; 

    // LEER MEMORIA
    #2 i_data_log_from_mem = 32'd651;
    #2 i_cmd_from_micro = {RD_MEM, 1'b0  , {(NB_DATA-1-15){1'b0}}, 15'd250}; 
    #2 i_cmd_from_micro = {RD_MEM, 1'b1  , {(NB_DATA-1-15){1'b0}}, 15'd250}; 
    #2 i_cmd_from_micro = {RD_MEM, 1'b0  , {(NB_DATA-1-15){1'b0}}, 15'd250}; 

    #40;
    $finish;
end
always #1 clk = ~clk;

file_register
#(
    .NB_C0M  (NB_C0M ), //! numero de bits de comando de la instruccion
    .NB_DATA (NB_DATA), //! numero de bits de la data de la instruccion
    .NB_BER  (NB_BER ), //! numero de bits de ber
    .NB_INST (NB_INST)  //! numero de bits de instruccion
) 
    u_file_register
(
    .i_cmd_from_micro    (i_cmd_from_micro      ),    //! gpi0, comando del micro hacia el file register
    .o_data_to_micro     (o_data_to_micro       ),    //! gpo0, datos del file register hacia el micro
    .i_mem_full          (i_mem_full            ),    //! entrada del sistema de memoria llena
    .i_ber_samp_I        (i_ber_samp_I          ),    //! entrada de la cantidad de muestras I del BER
    .i_ber_samp_Q        (i_ber_samp_Q          ),    //! entrada de la cantidad de muestras Q del BER
    .i_ber_error_I       (i_ber_error_I         ),    //! entrada de la cantidad de errores I del BER
    .i_ber_error_Q       (i_ber_error_Q         ),    //! entrada de la cantidad de errores Q del BER
    .i_data_log_from_mem (i_data_log_from_mem   ),    //! entrada de los datos de log desde la memoria
    .o_reset             (o_reset_from_micro    ),    //! salida de reset del file register hacia el sistema
    .o_enbTx             (o_enbTx               ),
    .o_enbRx             (o_enbRx               ),
    .o_phase_sel         (o_phase_sel           ),
    .o_run_log           (o_run_log             ),
    .o_read_log          (o_read_log            ),
    .o_addr_log_to_mem   (o_addr_log_to_mem     ),
    .clock               (clk                   ),
    .reset               (reset                 )
);
endmodule