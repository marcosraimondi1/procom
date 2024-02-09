`timescale 1ns/100ps

module tb_conv_2d #(
    parameter NB_COEFF    = 8,
    parameter NB_OUTPUT   = 8,
    parameter NB_DATA     = 8,
    parameter KERNEL_SIZE = 9
)();

    reg clk;
    reg i_rst;
    
    reg signed [NB_COEFF*3-1:0] kernel_fila2;
    reg signed [NB_COEFF*3-1:0] kernel_fila1;
    reg signed [NB_COEFF*3-1:0] kernel_fila0;

    reg signed [NB_DATA*3-1:0] data_fila2;
    reg signed [NB_DATA*3-1:0] data_fila1;
    reg signed [NB_DATA*3-1:0] data_fila0;
    
    wire     signed [NB_OUTPUT-1:0] o_pixel;

	always #1 clk = ~clk;

    integer i;

    initial begin
        clk = 0;
        i_rst = 0;

        kernel_fila0 = {8'b0, 8'b0, 8'b0};
        kernel_fila1 = {8'b0, 8'b1111111, 8'b0};
        kernel_fila2 = {8'b0, 8'b0, 8'b0};

        data_fila0 = {8'b0, 8'b0, 8'b0};
        data_fila1 = {8'b0, 8'b0, 8'b0};
        data_fila2 = {8'b0, 8'b0, 8'b0};

        #2 i_rst          = 1;
        #2 i_rst          = 0;

        #3;
        
        #2 data_fila1 = {8'b0, 8'h1, 8'b0};
        #2;
        $display("expected = %d , out = %d", data_fila1[15:8], o_pixel); 

        #2 data_fila1 = {8'b1, 8'h2, 8'b0};
        #2;
        $display("expected = %d , out = %d", data_fila1[15:8], o_pixel); 

        #2 data_fila1 = {8'b0, 8'h3, 8'b0};
        #2;
        $display("expected = %d , out = %d", data_fila1[15:8], o_pixel); 

        #2 data_fila1 = {8'b0, 8'h4, 8'b1};
        #2;
        $display("expected = %d , out = %d", data_fila1[15:8], o_pixel); 

        #2 data_fila1 = {8'b0, 8'h5, 8'b0};
        data_fila2 = {8'b0, 8'h6, 8'b0};
        #2;
        $display("expected = %d , out = %d", data_fila1[15:8], o_pixel); 

        #2 data_fila1 = {8'b0, 8'h6, 8'b0};
        data_fila2 = {8'b1, 8'h6, 8'b1};
        #2;
        $display("expected = %d , out = %d", data_fila1[15:8], o_pixel); 

        #2 data_fila1 = {8'b0, 8'h7, 8'b0};
        #2;
        $display("expected = %d , out = %d", data_fila1[15:8], o_pixel); 

        #20;
        $finish;
    end

    

    wire     signed [NB_COEFF*KERNEL_SIZE-1:0] i_kernel;    
    wire     signed [NB_DATA*KERNEL_SIZE-1:0] i_data;    

    
    assign i_kernel = {kernel_fila2, kernel_fila1, kernel_fila0};
    assign i_data = {data_fila2, data_fila1, data_fila0};

    conv_2d # (
        .NB_COEFF    (NB_COEFF),
        .NB_OUTPUT   (NB_OUTPUT),
        .NB_DATA     (NB_DATA),
        .KERNEL_SIZE (KERNEL_SIZE)
    )
    u_conv_2d (
        .clk(clk), 
        .i_rst(i_rst),   
        .i_kernel(i_kernel),    
        .i_data(i_data),    
        .o_pixel(o_pixel)            
        );


endmodule