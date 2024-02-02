//`define INPUT_FILE_PATH "/home/manu/repos/procom/src/python/test1_input.txt"
//`define RESULT_FILE_PATH "/home/manu/repos/procom/src/python/test1_output.txt"
`define INPUT_FILE_PATH "C:/Users/agusb/OneDrive/Escritorio/PROCOM/tpfinal/procom/src/verilog/py_input.txt"
`define RESULT_FILE_PATH "C:/Users/agusb/OneDrive/Escritorio/PROCOM/tpfinal/procom/src/verilog/py_output.txt"
`define OUTPUT_FILE_PATH "C:/Users/agusb/OneDrive/Escritorio/PROCOM/tpfinal/procom/src/verilog/verilog_output.txt"
`timescale 1ns/100ps

module tb_conv_2d();

    localparam IMAGE_HEIGHT = 10+2;  //Alto de la imagen + padding
    localparam IMAGE_WIDTH  = 1+2;  //Ancho de la imagen + padding

    reg clk;
    reg i_en_conv;
    reg i_nrst;
    reg i_load_knl;
    reg i_data_valid;
    
    reg signed [7:0] i_data1;
    reg signed [7:0] i_data2;
    reg signed [7:0] i_data3;
    wire signed [7:0] o_pixel;

    reg [7:0] kernel [9:1];
    reg [7:0] padded_frame [IMAGE_HEIGHT-1:0][IMAGE_WIDTH-1:0];
    reg [7:0] conv_image   [(IMAGE_HEIGHT-2)*(IMAGE_WIDTH-2) - 1:0]; //imagen convolucionada (sin padding)
    reg [31:0] addr;

    integer fd_input, fd_result, fd_output;
    integer i, j;   

	always #5 clk = ~clk;

    initial begin
       fd_input  = $fopen(`INPUT_FILE_PATH,"r");
       fd_result  = $fopen(`RESULT_FILE_PATH,"r");
       fd_output  = $fopen(`OUTPUT_FILE_PATH,"w");
       if (fd_input && fd_result)
           $display("Files were opened successfully : %0d %0d %0d",fd_input, fd_result, fd_output);
       else begin
           $display("Could not open files successfully : %0d %0d %0d",fd_input, fd_result, fd_output);
           $finish;
       end
        $display("");
        $display("Simulation Started");

        for (j=0;j<IMAGE_WIDTH;j=j+1) begin
           for (i=0;i<IMAGE_HEIGHT;i=i+1) begin
               $fscanf(fd_input,"%b\n", padded_frame[i][j]);
                // $display("%d %d: %b ",i,j, padded_frame[i][j]);
           end
       end


        kernel[1] = 8'b0;
        kernel[2] = 8'b0;
        kernel[3] = 8'b0;
        kernel[4] = 8'b0;
        kernel[5] = 8'b1111111;
        kernel[6] = 8'b0;
        kernel[7] = 8'b0;
        kernel[8] = 8'b0;
        kernel[9] = 8'b0;

                clk  = 0;
                i_nrst = 0;
                i_en_conv = 0;
                i_load_knl = 0;
                i_data_valid = 0;
                i_data1 = kernel[9];
                i_data2 = kernel[8];
                i_data3 = kernel[7];
        //Cargo el kernel
        #50     i_nrst = 1;
                i_load_knl = 1;
        #10     i_data1 = kernel[6];   
                i_data2 = kernel[5];  
                i_data3 = kernel[4];  
        #10     i_data1 = kernel[3];         
                i_data2 = kernel[2];  
                i_data3 = kernel[1];   
        //Cargo los primeros valores del subframe      
        #10     i_load_knl = 0;
                
		//Cargo los pixeles de a filas
				for (j=0;j<IMAGE_WIDTH-2;j=j+1) begin
					for (i=0;i<IMAGE_HEIGHT;i=i+1) begin
					    i_data1 = padded_frame[i][j];   
						i_data2 = padded_frame[i][j+1];  
						i_data3 = padded_frame[i][j+2];  
                        if(i > 2)
                            i_data_valid = 1;   //se cargaron las 3 filas
                        else i_data_valid = 0;
                        // if(i_data_valid) begin
                        //     $fdisplay(fd_output, "%b\n", o_pixel);
                        //     $display("%b\n", o_pixel);
                        // end
                        #10;
                	end
                end
				i_data1 = 8'b0; 
				i_data2 = 8'b0;
				i_data3 = 8'b0;

        #60     $fclose(fd_input);
                $fclose(fd_result);
                $fclose(fd_output);
                $finish;
    end
    
    always @ (posedge clk) begin
        if(i_data_valid) begin
            $fdisplay(fd_output, "%b", o_pixel);
            $display("%b", o_pixel);
        end
    end

    conv_2d u_conv(
        .clk(clk),
        .i_en_conv(i_en_conv),
        .i_nrst(i_nrst),
        .i_load_knl(i_load_knl),
        .i_data_valid(i_data_valid),
        .i_data1(i_data1),
        .i_data2(i_data2),
        .i_data3(i_data3),
        .o_pixel(o_pixel)
    );


endmodule