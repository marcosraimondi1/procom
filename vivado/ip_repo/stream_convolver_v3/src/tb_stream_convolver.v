module tb_stream_convolver #(
    IMAGE_HEIGHT = 12,
    KERNEL_WIDTH = 3,
    NB_COEFF = 8,
    NB_PIXEL = 8,
    DATA_WIDTH = 32
) ();

reg                          clk;
reg                          i_rstn;


reg s1_axis_valid;
reg m1_axis_ready;
reg [DATA_WIDTH-1:0] s1_axis_data;

wire [DATA_WIDTH-1:0]     data_from_micro; // to module
wire  [DATA_WIDTH-1:0]       data_to_micro; // from module

reg s0_axis_valid;
wire s0_axis_ready;
reg m0_axis_ready;
wire m0_axis_valid;

reg [7:0] pixels_in [0:3];
wire [7:0] pixels_out [0:3];
assign data_from_micro = {pixels_in[3], pixels_in[2], pixels_in[1], pixels_in[0]};

always #1 clk = ~clk;

initial begin
    clk = 0;
    i_rstn = 0;

    s1_axis_valid = 0;
    m1_axis_ready = 0;
    s1_axis_data = 0;

    #2 i_rstn = 1;
    m0_axis_ready= 1; //Siempre disponible para recibir data
    
    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd0; pixels_in[2] = 8'd0; pixels_in[3] = 8'd0; 
    s0_axis_valid= 1;
    
    #6 s0_axis_valid= 0;

    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd129; pixels_in[2] = 8'd130; pixels_in[3] = 8'd131;
        s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd135; pixels_in[2] = 8'd136; pixels_in[3] = 8'd137;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd141; pixels_in[2] = 8'd142; pixels_in[3] = 8'd143;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd147; pixels_in[2] = 8'd148; pixels_in[3] = 8'd149;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd153; pixels_in[2] = 8'd154; pixels_in[3] = 8'd155;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd159; pixels_in[2] = 8'd160; pixels_in[3] = 8'd161;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd165; pixels_in[2] = 8'd166; pixels_in[3] = 8'd167;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd171; pixels_in[2] = 8'd172; pixels_in[3] = 8'd173;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd177; pixels_in[2] = 8'd178; pixels_in[3] = 8'd179;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    
    
    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd183; pixels_in[2] = 8'd184; pixels_in[3] = 8'd185;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd0; pixels_in[2] = 8'd0; pixels_in[3] = 8'd0; 
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    //SEGUNDA COLUMNA

    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd0; pixels_in[2] = 8'd0; pixels_in[3] = 8'd0; 
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd132; pixels_in[1] = 8'd133; pixels_in[2] = 8'd134; pixels_in[3] = 8'd0;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd138; pixels_in[1] = 8'd139; pixels_in[2] = 8'd140; pixels_in[3] = 8'd0;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd144; pixels_in[1] = 8'd145; pixels_in[2] = 8'd146; pixels_in[3] = 8'd0;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd150; pixels_in[1] = 8'd151; pixels_in[2] = 8'd152; pixels_in[3] = 8'd0;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd156; pixels_in[1] = 8'd157; pixels_in[2] = 8'd158; pixels_in[3] = 8'd0;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd162; pixels_in[1] = 8'd163; pixels_in[2] = 8'd164; pixels_in[3] = 8'd0;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd168; pixels_in[1] = 8'd169; pixels_in[2] = 8'd170; pixels_in[3] = 8'd0;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
   

    #2 pixels_in[0] = 8'd174; pixels_in[1] = 8'd175; pixels_in[2] = 8'd176; pixels_in[3] = 8'd0;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd180; pixels_in[1] = 8'd181; pixels_in[2] = 8'd182; pixels_in[3] = 8'd0;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd186; pixels_in[1] = 8'd187; pixels_in[2] = 8'd188; pixels_in[3] = 8'd0;
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #2 pixels_in[0] = 8'd0; pixels_in[1] = 8'd0; pixels_in[2] = 8'd0; pixels_in[3] = 8'd0; 
    s0_axis_valid= 1;
    #6 s0_axis_valid= 0;
    

    #20;
    $finish;
end

wire m1_axis_valid;
wire s1_axis_ready;
wire [DATA_WIDTH-1:0] m1_axis_data;

assign pixels_out[0] = data_to_micro[7:0];
assign pixels_out[1] = data_to_micro[15:8];
assign pixels_out[2] = data_to_micro[23:16];
assign pixels_out[3] = data_to_micro[31:24];

axi_stream_convolver #(
    .IMAGE_HEIGHT   (IMAGE_HEIGHT),  // Image height with zero padding
    .KERNEL_WIDTH   (KERNEL_WIDTH),
    .NB_PIXEL       (NB_PIXEL),
    .NB_COEFF       (NB_COEFF),
    .DATA_WIDTH     (DATA_WIDTH)
) u_axi_stream_convolver (
    .axi_clk(clk),
    .axi_reset_n(i_rstn),

    // axi stream slav interface
    .s0_axis_valid(s0_axis_valid),
    .s0_axis_data(data_from_micro),
    .s0_axis_ready(s0_axis_ready), //output

    .s1_axis_valid(s1_axis_valid),
    .s1_axis_data (s1_axis_data) ,
    .s1_axis_ready(s1_axis_ready), //output

    // axi stream master interface
    .m0_axis_valid(m0_axis_valid), //output
    .m0_axis_data(data_to_micro), //output
    .m0_axis_ready(m0_axis_ready),

    .m1_axis_valid(m1_axis_valid), //output
    .m1_axis_data(m1_axis_data), //output
    .m1_axis_ready(m1_axis_ready)
);




endmodule