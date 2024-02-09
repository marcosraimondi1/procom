`timescale 1ns/100ps

module tb_top_convolver #(
    IMAGE_HEIGHT = 200,  // Image height with zero padding
    KERNEL_WIDTH = 3,
    NB_PIXEL = 8,
    NB_COEFF = 8,
    KERNEL_SIZE = 9,
    NB_CONV = KERNEL_SIZE * NB_PIXEL,
    NB_DATA = 32
)();
    reg clk;
    reg i_rst;

    wire [NB_DATA-1:0] o_axi_data;
    reg [NB_DATA-1:0] i_axi_data;
    always #1 clk = ~clk;
    reg i_valid;


    initial begin
        clk = 0;
        i_rst = 0;
        i_valid = 0;

        #2 i_rst          = 1;
        #2 i_rst          = 0;
        #2 i_axi_data = 32'hff000000; i_valid=1;
        #2 i_valid =0;
        #4 i_axi_data = 32'h0f000000; i_valid=1;
        #2 i_valid =0;
        #4 i_axi_data = 32'b1111; i_valid=1;
        #2 i_valid =0;
        #4 i_axi_data = 32'b1000; i_valid=1;
        #2 i_valid =0;
        #4 i_axi_data = 32'b1000; i_valid=1;
        #2 i_valid =0;

        #2 i_axi_data = 32'b1000; i_valid=1;
        #2 i_valid =0;

        #2 i_axi_data = 32'b1000; i_valid=1;
        #2 i_valid =0;




        #20;
        $finish; 
    end

top_convolver #(
    .IMAGE_HEIGHT (IMAGE_HEIGHT),  // Image height with zero padding
    .KERNEL_WIDTH (KERNEL_WIDTH),
    .NB_PIXEL (NB_PIXEL),
    .NB_COEFF(NB_COEFF),
    .KERNEL_SIZE (KERNEL_SIZE),
    .NB_CONV(NB_CONV),
    .NB_DATA (NB_DATA)
) 
u_top_convolver(
    .i_clk     (clk),
    .i_reset   (i_rst),
    .i_axi_data(i_axi_data),
    .i_valid   (i_valid),
    .o_axi_data(o_axi_data)

);
endmodule