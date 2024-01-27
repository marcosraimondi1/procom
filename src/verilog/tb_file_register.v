`timescale 1ns / 100ps

module tb_file_register
#(
    parameter NB_C0M  =  8,
    parameter NB_DATA = 24,
    parameter NB_INST = 32
)
(

);
reg                          clk                 ;    //! Clock
reg                          reset               ;    //! Reset

reg     [NB_INST-1:0]        i_cmd_from_micro    ;   //! gpi0
reg                          i_frame_ready       ;
reg     [NB_INST-1:0]        i_frame_from_mem    ;

wire    [NB_INST-1:0]        o_data_to_micro     ;   //! gpo0
wire    [NB_DATA-1:0]        o_frame_from_micro  ; 
wire    [        1:0]        o_kernel_sel        ;
wire                         o_load              ;
wire                         o_start_conv        ;


//!---------------- Comandos disponibles ----------------
localparam [NB_C0M -1:0] KERNEL_SEL     = 8'b00000000;
localparam [NB_C0M -1:0] LOAD_FRAME     = 8'b00000001;
localparam [NB_C0M -1:0] END_FRAME      = 8'b00000010;
localparam [NB_C0M -1:0] IS_FRAME_READY = 8'b00000011;
localparam [NB_C0M -1:0] GET_FRAME      = 8'b00000100;
//!------------------------------------------------------

initial begin
    clk                 = 0     ;
    reset               = 0     ;
    i_cmd_from_micro    = 0     ;
    i_frame_ready       = 0     ;
    i_frame_from_mem    = 0     ;

    #2  reset           = 1     ;
    #2  reset           = 0     ;
    #2;
    //                    {CMD  , ENABLE, DATA                    };
    
    // prueba de seleccion de kernels
    #2 i_cmd_from_micro = {KERNEL_SEL, 1'b0  , {(NB_DATA-3){1'b0}},1'b1,1'b1};
    #2 i_cmd_from_micro = {KERNEL_SEL, 1'b1  , {(NB_DATA-3){1'b0}},1'b1,1'b1};
    #2 i_cmd_from_micro = {KERNEL_SEL, 1'b0  , {(NB_DATA-3){1'b0}},1'b1,1'b1};

    #2 i_cmd_from_micro = {KERNEL_SEL, 1'b0  , {(NB_DATA-3){1'b0}},1'b1,1'b0};
    #2 i_cmd_from_micro = {KERNEL_SEL, 1'b1  , {(NB_DATA-3){1'b0}},1'b1,1'b0};
    #2 i_cmd_from_micro = {KERNEL_SEL, 1'b0  , {(NB_DATA-3){1'b0}},1'b1,1'b0};

    // prueba de frame ready
    #2 i_frame_ready = 1'b1;
    #2 i_cmd_from_micro = {IS_FRAME_READY, 1'b0  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {IS_FRAME_READY, 1'b1  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {IS_FRAME_READY, 1'b0  , {(NB_DATA-1){1'b0}}}; 

    #2 i_frame_ready = 1'b0;
    #2 i_cmd_from_micro = {IS_FRAME_READY, 1'b0  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {IS_FRAME_READY, 1'b1  , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {IS_FRAME_READY, 1'b0  , {(NB_DATA-1){1'b0}}}; 

    // todo: LOAD_FRAME, END_FRAME, GET_FRAME

    #40;
    $finish;
end
always #1 clk = ~clk;

file_register
#(
    .NB_C0M  (NB_C0M ), //! numero de bits de comando de la instruccion
    .NB_DATA (NB_DATA), //! numero de bits de la data de la instruccion
    .NB_INST (NB_INST)  //! numero de bits de instruccion
) 
    u_file_register
(
    .o_kernel_sel(o_kernel_sel),
    .o_load(o_load),
    .o_start_conv(o_start_conv),
    .o_frame_from_micro(o_frame_from_micro),
    .o_data_to_micro(o_data_to_micro),    //! gpo0
    .i_cmd_from_micro(i_cmd_from_micro),    //! gpi0
    .i_frame_ready(i_frame_ready),    
    .i_frame_from_mem(i_frame_from_mem),    
    .clock(clk),
    .reset(reset)
);
endmodule
