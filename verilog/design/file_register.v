module file_register
#(
    parameter NB_C0M  =  8,
    parameter NB_DATA = 24,
    parameter NB_BER  = 64,
    parameter NB_INST = 32
) 
(
    input   [NB_INST-1:0]   i_cmd_from_micro    ,    //! gpi0

    output  [NB_INST-1:0]   o_data_to_micro     ,    //! gpo0

    input                   i_mem_full          ,
    input   [NB_BER -1:0]   i_ber_samp_I        ,
    input   [NB_BER -1:0]   i_ber_samp_Q        ,
    input   [NB_BER -1:0]   i_ber_error_I       ,
    input   [NB_BER -1:0]   i_ber_error_Q       ,
    input   [NB_INST-1:0]   i_data_log_from_mem ,

    output                  o_reset             ,
    output                  o_enbTx             ,
    output                  o_enbRx             ,
    output  [        1:0]   o_phase_sel         ,
    output                  o_run_log           ,
    output                  o_read_log          ,
    output  [       14:0]   o_addr_log_to_mem   ,

    input                   clock               ,
    input                   i_reset             ,
);

reg                 enbTx           ;
reg                 enbRx           ;
reg [        1:0]   phase_sel       ;
reg                 run_log         ;
reg                 read_log        ;
reg [       14:0]   addr_log_to_mem ;
reg [NB_INST-1:0]   data_to_micro   ;
reg [NB_BER -1:0]   ber_buffer      ;
//!----------------Comandos disponibles----------------
localparam [NB_C0M -1:0] RESET   = 8'b00000001;
localparam [NB_C0M -1:0] EN_TX   = 8'b00000010;
localparam [NB_C0M -1:0] EN_RX   = 8'b00000011;
localparam [NB_C0M -1:0] PH_SEL  = 8'b00000100;
localparam [NB_C0M -1:0] RUN_MEM = 8'b00000010;
localparam [NB_C0M -1:0] RD_MEM  = 8'b00000011; // lee la memoria
localparam [NB_C0M -1:0] IS_FULL = 8'b00000100; // ver si esta llena
localparam [NB_C0M -1:0] BER_S_I = 8'b00000101; // leer samples
localparam [NB_C0M -1:0] BER_S_Q = 8'b00000110; 
localparam [NB_C0M -1:0] BER_E_I = 8'b00000111; // leer errores
localparam [NB_C0M -1:0] BER_E_Q = 8'b00001000;

//!----------------------------------------------------
wire [NB_DATA-1:0]  data_from_micro     ;
wire [NB_C0M -1:0]  command_from_micro  ;
wire                enable_from_micro   ;


reg state_enable;
reg flag;

assign command_from_micro  = i_cmd_from_micro[31:24];
assign data_from_micro     = i_cmd_from_micro[23:0] ;
assign enable_from_micro   = i_cmd_from_micro[24]   ;

always @(posedge clock) begin
    if (reset)
    begin
        enbTx           <= 0;
        enbRx           <= 0;
        phase_sel       <= 0;
        run_log         <= 0;
        read_log        <= 0;
        addr_log_to_mem <= 0;
        data_to_micro   <= 0;
        state_enable    <= 0;
    end
    else
    begin
        if ((enable_from_micro == 1'b1) && (state_enable == 1'b0))begin
            // flanco de subida del enable detectado
            // se toma la instruccion
            case (command_from_micro)
                RESET   :
                    reset <= data_from_micro[0];
                
                EN_TX   :
                    enbTx   <= data_from_micro[0];
                
                EN_RX   :
                    enbRx   <= data_from_micro[0];
                
                PH_SEL  :
                    phase_sel <= data_from_micro[1:0];

                RUN_MEM :
                    begin
                    read_log <= 1'b0;
                    run_log <= 1'b1;
                    end 
                
                RD_MEM  :
                    if (~i_mem_full) begin
                        read_log <= 1'b1;
                        addr_log_to_mem <= data_from_micro[14:0];
                    end

                IS_FULL :
                    data_to_micro <= i_mem_full;

                BER_S_I :
                    begin
                    data_to_micro <= i_ber_samp_I[31:0];
                    ber_buffer <= i_ber_samp_I;
                    flag <= 1'b1;
                    end

                BER_S_Q :
                    begin
                    data_to_micro <= i_ber_samp_Q[31:0];
                    ber_buffer <= i_ber_samp_Q;
                    flag <= 1'b1;
                    end

                BER_E_I :
                    begin
                    data_to_micro <= i_ber_error_I[31:0];
                    ber_buffer <= i_ber_error_I;
                    flag <= 1'b1;
                    end

                BER_E_Q :
                    begin
                    data_to_micro <= i_ber_error_Q[31:0];
                    ber_buffer <= i_ber_error_Q;
                    flag <= 1'b1;
                    end

            endcase
            
            else if (run_log) begin: one_clock_run
                run_log<= 1'b0;
            end
            else if (flag)begin
                data_to_micro <= ber_buffer[63:32];  
                flag <= 1'b0;
            end
        end

        state_enable <= enable_from_micro;
    end
end

assign o_reset           = reset           ;
assign o_enbTx           = enbTx           ;
assign o_enbRx           = enbRx           ;
assign o_phase_sel       = phase_sel       ;
assign o_run_log         = run_log         ;
assign o_read_log        = read_log        ;
assign o_addr_log_to_mem = addr_log_to_mem ;
assign o_data_to_micro   = data_to_micro   ;

endmodule