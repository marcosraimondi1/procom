module integration #(
    parameter NB_GPIOS  = 32        ,
    parameter RAM_WIDTH = 8         ,
    parameter RAM_DEPTH = 1024      ,
    parameter NB_C0M    = 7         ,
    parameter NB_DATA   = 24        ,
    parameter NB_INST   = 32        ,
    parameter IMAGE_WIDTH  = 10     ,
    parameter IMAGE_HEIGHT = 10     ,
    parameter KERNEL_WIDTH = 3
)
(
    input           reset   ,
    input           clock   ,
    input  [NB_GPIOS - 1 : 0]           gpi0    ,
    output [NB_GPIOS - 1 : 0]           gpo0    
    
);

    wire [NB_DATA-1:0] pixels_from_micro_to_mem;
    wire [        1:0] kernel_sel;
    wire               load_pixels_to_mem;
    wire               read_pixels_from_mem;
    wire               o_start_conv;
    wire               frame_ready_for_micro;


    wire [RAM_WIDTH-1:0] pixel_from_mem_to_micro;
    reg [NB_INST-1:0] pixels_from_mem_to_micro;


    always @(posedge clock) begin
        if (reset) begin
            pixels_from_mem_to_micro <= 0;
        end else begin
            if (frame_ready_for_micro) begin
                if (read_pixels_from_mem) begin
                    // shift pixels for every request
                    pixels_from_mem_to_micro <= {pixels_from_mem_to_micro[NB_INST-RAM_WIDTH-1:0], pixel_from_mem_to_micro};
                end
            end
        end
    end

   file_register #(
      .NB_C0M (NB_C0M),   //! numero de bits de comando de la instruccion
      .NB_DATA(NB_DATA),  //! numero de bits de la data de la instruccion
      .NB_INST(NB_INST)   //! numero de bits de instruccion
  ) u_file_register (
      .o_kernel_sel(kernel_sel),
      .o_get_pixels(read_pixels_from_mem),
      .o_load(load_pixels_to_mem),
      .o_start_conv(o_start_conv),
      .o_pixels_from_micro(pixels_from_micro_to_mem),
      .o_data_to_micro(gpo0),  //! gpo0
      .i_cmd_from_micro(gpi0),  //! gpi0
      .i_frame_ready(frame_ready_for_micro),  //frame listo para enviar a micro
      .i_pixels_from_mem(pixels_from_mem_to_micro),
      .clock(clock),
      .reset(reset)
  );


  wire [RAM_WIDTH-1:0] o_to_conv [KERNEL_WIDTH-1:0];
  wire o_valid_data_to_conv;
  
  // Instantiate BRAM
  bram_control #(
      .RAM_WIDTH(RAM_WIDTH),
      .RAM_DEPTH(RAM_DEPTH),
      .INIT_FILE(""),
      .KERNEL_WIDTH(KERNEL_WIDTH),
      .IMAGE_WIDTH(IMAGE_WIDTH),
      .IMAGE_HEIGHT(IMAGE_HEIGHT),
      .TO_PROCESS(0)
  ) u_bram_control (
      .clk              (clock),
      .reset            (reset),
      .i_load_valid     (load_pixels_to_mem),
      .i_data_to_mem    (pixels_from_micro_to_mem[7:0]),
      .i_read_valid     (read_pixels_from_mem),
      .o_data_from_mem  (pixel_from_mem_to_micro),

      .o_frame_ready    (frame_ready_for_micro),

      // convolver only
      .o_valid_data_to_conv(o_valid_data_to_conv),
      .o_to_conv0       (o_to_conv[0]),
      .o_to_conv1       (o_to_conv[1]),
      .o_to_conv2       (o_to_conv[2])
  );
     
endmodule
