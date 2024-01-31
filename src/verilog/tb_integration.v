`timescale 1ns/100ps

module tb_integration;

    reg reset     ;
    reg clock      ;

    //!---------------- Comandos disponibles ----------------
    localparam [7 -1:0] KERNEL_SEL = 7'b0000000;
    localparam [7 -1:0] LOAD_FRAME = 7'b0000001;
    localparam [7 -1:0] END_FRAME = 7'b0000010;
    localparam [7 -1:0] IS_FRAME_READY = 7'b0000011;
    localparam [7 -1:0] GET_FRAME = 7'b0000100;
    //!------------------------------------------------------   

    reg [7:0] pixel;
    reg [31:0] gpi0;
    wire [31:0] gpo0;
    
    integer i;

    initial begin
        clock            = 0;
        reset           = 0;
        pixel             = 0;
        gpi0             = 0;
        
        #2 reset = 1;
        #2 reset = 0;
        #2;

        // carga de kernel de a un px
        for (i = 0; i<100; i = i+1) begin
            #2 gpi0 = {1'b0, LOAD_FRAME, {{(16) {1'b0}}, pixel}};
            #2 gpi0 = {1'b1, LOAD_FRAME, {{(16) {1'b0}}, pixel}};
            #2 gpi0 = {1'b0, LOAD_FRAME, {{(16) {1'b0}}, pixel}};
            #2;
            pixel = pixel + 1;
        end

        // preguntar si el frame esta ready

        #2 gpi0 = {1'b0, IS_FRAME_READY, {(24) {1'b0}}};
        #2 gpi0 = {1'b1, IS_FRAME_READY, {(24) {1'b0}}};
        #2 gpi0 = {1'b0, IS_FRAME_READY, {(24) {1'b0}}};

        // recuperar el frame de a un px
        // el primero se repite
        #2 gpi0 = {1'b0, GET_FRAME, {(24) {1'b0}}};
        #2 gpi0 = {1'b1, GET_FRAME, {(24) {1'b0}}};
        #2 gpi0 = {1'b0, GET_FRAME, {(24) {1'b0}}};
        #2;
        
        for (i = 0; i<100; i = i+1) begin
            #2 gpi0 = {1'b0, GET_FRAME, {(24) {1'b0}}};
            #2 gpi0 = {1'b1, GET_FRAME, {(24) {1'b0}}};
            #2 gpi0 = {1'b0, GET_FRAME, {(24) {1'b0}}};
            #2;

            pixel = gpo0[7:0];

            $display("pixels [0 1 2 3]: [ %d, %d, %d, %d ]", gpo0[31:24], gpo0[23:16], gpo0[15:8], pixel);
        end
        
        #100;
        $finish;
    end
    always #1 clock = ~clock;

    integration #(
        .NB_GPIOS(32)    ,
        .RAM_WIDTH(8)    ,
        .RAM_DEPTH(128) ,
        .NB_C0M(7)       ,
        .NB_DATA(24)     ,
        .NB_INST(32)     ,
        .IMAGE_WIDTH(10) ,
        .IMAGE_HEIGHT(10),
        .KERNEL_WIDTH(3)
    ) u_integration (
        .reset(reset)     ,
        .clock(clock)     ,
        .gpi0(gpi0)       ,
        .gpo0(gpo0)
    );



endmodule