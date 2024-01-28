`timescale 1ns / 100ps

module tb_file_register
#(
    parameter NB_C0M  =  7,
    parameter NB_DATA = 24,
    parameter NB_INST = 32
)
(

);
reg                          clk                 ;    //! Clock
reg                          reset               ;    //! Reset

reg     [NB_INST-1:0]        i_cmd_from_micro    ;   //! gpi0
reg                          i_frame_ready       ;
reg     [NB_INST-1:0]        i_pixels_from_mem    ;

wire    [NB_INST-1:0]        o_data_to_micro     ;   //! gpo0
wire    [NB_DATA-1:0]        o_pixels_from_micro ; 
wire    [        1:0]        o_kernel_sel        ;
wire                         o_load              ;
wire                         o_get_pixels        ;
wire                         o_start_conv        ;

reg     [        23:0]        bram     [     2:0];

//!---------------- Comandos disponibles ----------------
localparam [NB_C0M -1:0] KERNEL_SEL     = 7'b0000000;
localparam [NB_C0M -1:0] LOAD_FRAME     = 7'b0000001;  
localparam [NB_C0M -1:0] END_FRAME      = 7'b0000010;
localparam [NB_C0M -1:0] IS_FRAME_READY = 7'b0000011;
localparam [NB_C0M -1:0] GET_FRAME      = 7'b0000100;
//!------------------------------------------------------

initial begin
    clk                 = 0     ;
    reset               = 0     ;
    i_cmd_from_micro    = 0     ;
    i_frame_ready       = 0     ;
    i_pixels_from_mem    = 0     ;

    #2  reset           = 1     ;
    #2  reset           = 0     ;
    #2;
    //                    {CMD  , ENABLE, DATA                    };
    
    // prueba de seleccion de kernels
    #2 i_cmd_from_micro = {1'b0, KERNEL_SEL,  {(NB_DATA-3){1'b0}},1'b1,1'b1};
    #2 i_cmd_from_micro = {1'b1, KERNEL_SEL,  {(NB_DATA-3){1'b0}},1'b1,1'b1};
    #2 i_cmd_from_micro = {1'b0, KERNEL_SEL,  {(NB_DATA-3){1'b0}},1'b1,1'b1};

    #2 i_cmd_from_micro = {1'b0, KERNEL_SEL,  {(NB_DATA-3){1'b0}},1'b1,1'b0};
    #2 i_cmd_from_micro = {1'b1, KERNEL_SEL,  {(NB_DATA-3){1'b0}},1'b1,1'b0};
    #2 i_cmd_from_micro = {1'b0, KERNEL_SEL,  {(NB_DATA-3){1'b0}},1'b1,1'b0};

    // prueba de frame ready
    #2 i_frame_ready = 1'b1;
    #2 i_cmd_from_micro = {1'b0, IS_FRAME_READY, {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {1'b1, IS_FRAME_READY, {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {1'b0, IS_FRAME_READY, {(NB_DATA-1){1'b0}}}; 

    #2 i_frame_ready = 1'b0;
    #2 i_cmd_from_micro = {1'b0, IS_FRAME_READY, {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {1'b1, IS_FRAME_READY, {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {1'b0, IS_FRAME_READY, {(NB_DATA-1){1'b0}}}; 

    // prueba de carga de frame
    #2 i_cmd_from_micro = {1'b0, LOAD_FRAME  , 24'b001010111111111100011101}; 
    #2 i_cmd_from_micro = {1'b1, LOAD_FRAME  , 24'b001010111111111100011101}; 
    #2 i_cmd_from_micro = {1'b0, LOAD_FRAME  , 24'b001010111111111100011101};

    #2 i_cmd_from_micro = {1'b0, LOAD_FRAME  , 24'b011111111010101111111111}; 
    #2 i_cmd_from_micro = {1'b1, LOAD_FRAME  , 24'b011111111010101111111111}; 
    #2 i_cmd_from_micro = {1'b0, LOAD_FRAME  , 24'b011111111010101111111111}; 

    #2 i_cmd_from_micro = {1'b0, END_FRAME   , 24'b000000001111111100000000}; 
    #2 i_cmd_from_micro = {1'b1, END_FRAME   , 24'b000000001111111100000000}; 
    #2 i_cmd_from_micro = {1'b0, END_FRAME   , 24'b000000001111111100000000}; 
    
    // prueba de get frame
    #2 i_frame_ready = 1'b1;
    #2 i_cmd_from_micro = {1'b0, IS_FRAME_READY , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {1'b1, IS_FRAME_READY , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {1'b0, IS_FRAME_READY , {(NB_DATA-1){1'b0}}}; 
    
    #2 i_cmd_from_micro = {1'b0,  GET_FRAME      , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {1'b1,  GET_FRAME      , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {1'b0,  GET_FRAME      , {(NB_DATA-1){1'b0}}}; 
    
    #2 i_cmd_from_micro = {1'b0,  GET_FRAME      , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {1'b1,  GET_FRAME      , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {1'b0,  GET_FRAME      , {(NB_DATA-1){1'b0}}}; 
    
    #2 i_cmd_from_micro = {1'b0,  GET_FRAME      , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {1'b1,  GET_FRAME      , {(NB_DATA-1){1'b0}}}; 
    #2 i_cmd_from_micro = {1'b0,  GET_FRAME      , {(NB_DATA-1){1'b0}}}; 
    

    #40;
    $finish;
end
always #1 clk = ~clk;


//Carga de bram
reg [2:0] i;
always @(posedge clk) begin
    if (reset)
        i <= 0;
    else
        if (o_load)
        begin
            bram[i] = o_pixels_from_micro;
            i <= i + 1;
        end
end

reg [2:0] j;
always @(posedge clk) begin
    if (reset)
        j <= 0;
    else
        if (o_get_pixels)
        begin
            i_pixels_from_mem = bram[j];
            j <= j+ 1;
        end
end

file_register
#(
    .NB_C0M  (NB_C0M ), //! numero de bits de comando de la instruccion
    .NB_DATA (NB_DATA), //! numero de bits de la data de la instruccion
    .NB_INST (NB_INST)  //! numero de bits de instruccion
) 
    u_file_register
(
    .o_kernel_sel(o_kernel_sel),
    .o_get_pixels(o_get_pixels),
    .o_load(o_load),
    .o_start_conv(o_start_conv),
    .o_pixels_from_micro(o_pixels_from_micro),
    .o_data_to_micro(o_data_to_micro),    //! gpo0
    .i_cmd_from_micro(i_cmd_from_micro),    //! gpi0
    .i_frame_ready(i_frame_ready),    
    .i_pixels_from_mem(i_pixels_from_mem),    
    .clock(clk),
    .reset(reset)
);
endmodule
