`timescale 1ns / 100ps

module tb_mem_fregister 
#(
    parameter RAM_WIDTH =   32,
    parameter RAM_DEPTH = 1024,
    parameter NB_C0M    =    8,
    parameter NB_DATA   =   24,
    parameter NB_BER    =   64,
    parameter NB_INST   =   32
)
(

);
reg                          clk                        ;    //! Clock
reg                          reset                      ;    //! Reset

reg     [NB_INST-1:0]        i_cmd_from_micro           ;   //! gpi0
wire    [NB_INST-1:0]        o_data_to_micro            ;   //! gpo0
reg     [NB_BER -1:0]        i_ber_samp_I               ;
reg     [NB_BER -1:0]        i_ber_samp_Q               ;
reg     [NB_BER -1:0]        i_ber_error_I              ;
reg     [NB_BER -1:0]        i_ber_error_Q              ;

wire                         o_reset_from_micro         ;
wire                         o_enbTx                    ;
wire                         o_enbRx                    ;
wire    [        1:0]        o_phase_sel                ;

// MEMORY MANAGEMENT
wire     [NB_INST-1:0]        data_log_from_mem_to_fr    ;
wire                          mem_full_from_mem_to_fr    ;
wire                         run_log_from_fr_to_mem     ;
wire                         read_log_from_fr_to_mem    ;
wire    [       14:0]        addr_log_from_fr_to_mem    ;
reg    [RAM_WIDTH-1:0]              i_data_tx_to_mem    ;

reg    [clogb2(RAM_DEPTH-1)-1:0]    addr_to_read        ;

localparam [NB_C0M -1:0] RESET   = 8'b00000001          ;
localparam [NB_C0M -1:0] EN_TX   = 8'b00000010          ;
localparam [NB_C0M -1:0] EN_RX   = 8'b00000011          ;
localparam [NB_C0M -1:0] PH_SEL  = 8'b00000100          ;
localparam [NB_C0M -1:0] RUN_MEM = 8'b00000101          ;
localparam [NB_C0M -1:0] RD_MEM  = 8'b00000110          ; // lee la memoria, en el campo data va la direccion
localparam [NB_C0M -1:0] IS_FULL = 8'b00000111          ; // ver si esta llena
localparam [NB_C0M -1:0] BER_S_I = 8'b00001000          ; // leer samples
localparam [NB_C0M -1:0] BER_S_Q = 8'b00001001          ; 
localparam [NB_C0M -1:0] BER_E_I = 8'b00001010          ; // leer errores
localparam [NB_C0M -1:0] BER_E_Q = 8'b00001011          ;
localparam [NB_C0M -1:0] BER_HIGH = 8'b00001100         ; // para leer la parte alta de la BER (lee la parte alta de la ultima lectura)


initial begin
    clk                             = 0     ;
    reset                           = 0     ;
    i_cmd_from_micro                = 0     ;
    i_data_tx_to_mem                = 0     ;
    addr_to_read                    = 9'b0  ;   
    
    #2  reset                       = 1     ;
    #10 reset                       = 0     ;

    // Envio comando run mem a la memoria.
    #2 i_cmd_from_micro = {RUN_MEM, 1'b0  , {(NB_DATA-1){1'b0}}};
    #2 i_cmd_from_micro = {RUN_MEM, 1'b1  , {(NB_DATA-1){1'b0}}};
    #2 i_cmd_from_micro = {RUN_MEM, 1'b0  , {(NB_DATA-1){1'b0}}};
    #2
    repeat (RAM_DEPTH) begin
        #2 i_data_tx_to_mem = i_data_tx_to_mem + 1;
    end
    #2;
    
    // pregunto desde el micro si esta llena la memoria
    #2 i_cmd_from_micro = {IS_FULL, 1'b0  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {IS_FULL, 1'b1  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {IS_FULL, 1'b0  , {(NB_DATA-1){1'b0}}}; 
    
    if (o_data_to_micro[0]) begin
        $display("Memory full");

        repeat (RAM_DEPTH) begin
            $display("------------------------");
            $display("addr_to_read = %d", addr_to_read);
            #2 addr_to_read = addr_to_read + 1;
            #2 i_cmd_from_micro = {RD_MEM, 1'b0  , {(NB_DATA-1-10){1'b0}}, addr_to_read}; 
            #2 i_cmd_from_micro = {RD_MEM, 1'b1  , {(NB_DATA-1-10){1'b0}}, addr_to_read}; 
            #2 i_cmd_from_micro = {RD_MEM, 1'b0  , {(NB_DATA-1-10){1'b0}}, addr_to_read}; 
            $display("data_to_micro = %d", o_data_to_micro);
        end
        
    end
    else 
        $display("Memory not full");

    #40;
    $finish;
end

// Clock generation
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
    .i_cmd_from_micro    (i_cmd_from_micro          ),    //! gpi0, comando del micro hacia el file register
    .o_data_to_micro     (o_data_to_micro           ),    //! gpo0, datos del file register hacia el micro
    .i_mem_full          (mem_full_from_mem_to_fr   ),    //! entrada del sistema de memoria llena
    .i_ber_samp_I        (i_ber_samp_I              ),    //! entrada de la cantidad de muestras I del BER
    .i_ber_samp_Q        (i_ber_samp_Q              ),    //! entrada de la cantidad de muestras Q del BER
    .i_ber_error_I       (i_ber_error_I             ),    //! entrada de la cantidad de errores I del BER
    .i_ber_error_Q       (i_ber_error_Q             ),    //! entrada de la cantidad de errores Q del BER
    .i_data_log_from_mem (data_log_from_mem_to_fr   ),    //! entrada de los datos de log desde la memoria
    .o_reset             (o_reset_from_micro        ),    //! salida de reset del file register hacia el sistema
    .o_enbTx             (o_enbTx                   ),
    .o_enbRx             (o_enbRx                   ),
    .o_phase_sel         (o_phase_sel               ),
    .o_run_log           (run_log_from_fr_to_mem    ),
    .o_read_log          (read_log_from_fr_to_mem   ),
    .o_addr_log_to_mem   (addr_log_from_fr_to_mem   ),
    .clock               (clk                       ),
    .reset               (reset                     )
);

bram #(
    .RAM_WIDTH(RAM_WIDTH),
    .RAM_DEPTH(RAM_DEPTH)
  ) u_bram (
    .clk                  (clk                      ),
    .reset                (reset                    ),
    .i_run_log            (run_log_from_fr_to_mem   ),
    .i_read_log           (read_log_from_fr_to_mem  ),
    .i_data_tx_to_mem     (i_data_tx_to_mem         ),
    .i_addr_log_to_mem    (addr_log_from_fr_to_mem  ),
    .o_data_log_from_mem  (data_log_from_mem_to_fr  ),
    .o_mem_full           (mem_full_from_mem_to_fr  )
  );

//  The following function calculates the address width based on specified RAM depth
// calcula cuantos bits de direccion hacen falta para direccionar la memoria
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction

endmodule