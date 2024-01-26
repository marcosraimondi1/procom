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

    reg [7:0] kernel [9:1];

	always #5 clk = ~clk;

    initial begin
        
    kernel[1] = 8'b0;
    kernel[2] = 8'b10000000;
    kernel[3] = 8'b0;
    kernel[4] = 8'b10000000;
    kernel[5] = 8'b00000101;
    kernel[6] = 8'b10000000;
    kernel[7] = 8'b0;
    kernel[8] = 8'b10000000;
    kernel[9] = 8'b0;

        clk  = 0;
        i_nrst = 0;
        i_en_conv = 0;
        i_load_knl = 0;
        i_data1 = kernel[1];
        i_data2 = kernel[4];
        i_data3 = kernel[7];
        // i_pixels = 24'hAABBCC;
        #50     i_nrst = 1;
                i_load_knl = 1;
        #10     i_data1 = kernel[2];   
                i_data2 = kernel[5];  
                i_data3 = kernel[8];  
        #10     i_data1 = kernel[3];         
                i_data2 = kernel[6];  
                i_data3 = kernel[9];         
        #10     i_load_knl = 0;
                i_en_conv = 1;
                i_data1 = 8'h44;
                i_data2 = 8'h55;
                i_data3 = 8'h66;
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