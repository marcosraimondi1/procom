`define INPUT_FILE_PATH "C:/Users/agusb/OneDrive/Escritorio/PROCOM/tpfinal/procom/src/verilog/test1_input.txt"
`define RESULT_FILE_PATH "C:/Users/agusb/OneDrive/Escritorio/PROCOM/tpfinal/procom/src/verilog/test1.txt"
`timescale 1ns/100ps

module tb_conv_2d();

    localparam IMAGE_HEIGHT = 1+2;  //Alto de la imagen 
    localparam IMAGE_WIDTH  = 10+2;  //Ancho de la imagen 

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
    reg [7:0] padded_frame [IMAGE_HEIGHT-1:0][IMAGE_WIDTH-1:0];

    integer fd_input, fd_result;
    integer i, j;   

	always #5 clk = ~clk;

    initial begin
       fd_input  = $fopen(`INPUT_FILE_PATH,"r");
       fd_result  = $fopen(`RESULT_FILE_PATH,"r");
       if (fd_input && fd_result)
           $display("Files were opened successfully : %0d %0d",fd_input, fd_result);
       else begin
           $display("Could not open files successfully : %0d %0d",fd_input, fd_result);
           $finish;
       end
        $display("");
        $display("Simulation Started");

        // $readmemb("preprocessed.txt", padded_frame);
       for (i=0;i<IMAGE_HEIGHT;i=i+1) begin
           for (j=0;j<IMAGE_WIDTH;j=j+1) begin
               $fscanf(fd_input,"%b\n", padded_frame[i][j]);
                $display("%d %d: %b ",i,j, padded_frame[i][j]);
           end
       end


        kernel[1] = 8'b0;
        kernel[2] = 8'b0;
        kernel[3] = 8'b0;
        kernel[4] = 8'b0;
        kernel[5] = 8'b1;
        kernel[6] = 8'b0;
        kernel[7] = 8'b0;
        kernel[8] = 8'b0;
        kernel[9] = 8'b0;

                clk  = 0;
                i_nrst = 0;
                i_en_conv = 0;
                i_load_knl = 0;
                i_data1 = kernel[1];
                i_data2 = kernel[4];
                i_data3 = kernel[7];
        //Cargo el kernel
        #50     i_nrst = 1;
                i_load_knl = 1;
        #10     i_data1 = kernel[2];   
                i_data2 = kernel[5];  
                i_data3 = kernel[8];  
        #10     i_data1 = kernel[3];         
                i_data2 = kernel[6];  
                i_data3 = kernel[9];   
        //Cargo los primeros valores del subframe      
        #10     i_load_knl = 0;
                i_en_conv = 1;
		//Cargo los pixeles de a columnas
				for (i=0;i<IMAGE_HEIGHT-2;i=i+1) begin
					for (j=0;j<IMAGE_WIDTH;j=j+1) begin
					    i_data1 = padded_frame[i][j];   
						i_data2 = padded_frame[i+1][j];  
						i_data3 = padded_frame[i+2][j];  
						#10;
                	end
                end
				i_data1 = 8'b0; 
				i_data2 = 8'b0;
				i_data3 = 8'b0;

        #40    $finish;
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