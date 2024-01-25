`timescale 1ns/100ps

module tb_conv_2d();
    reg clk;
    reg i_en_conv;
    reg i_nrst;
    reg i_load_knl;
    // reg signed [23:0] i_pixels;
    reg signed [7:0] i_data1;
    reg signed [7:0] i_data2;
    reg signed [7:0] i_data3;
    wire signed [20:0] o_pixel;

	always #5 clk = ~clk;

    initial begin
        clk  = 0;
        i_nrst = 0;
        i_en_conv = 0;
        i_data1 = 8'hAA;
        i_data2 = 8'hBB;
        i_data3 = 8'hCC;
        // i_pixels = 24'hAABBCC;
        #50     i_nrst = 1;
                i_en_conv = 1;
        
        // #50 i_pixels[0] = 8'd2;    
        #300    $finish;
    end


    conv_2d u_conv(
        .clk(clk),
        .i_en_conv(i_en_conv),
        .i_nrst(i_nrst),
        .i_load_knl(i_load_knl),
        .i_data1(i_data1),
        .i_data2(i_data2),
        .i_data3(i_data3),
        // .i_pixels(i_pixels),
        .o_pixel(o_pixel)
    );

endmodule