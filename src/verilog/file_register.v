module file_register #(
    parameter NB_C0M  = 7,   //! numero de bits de comando
    parameter NB_DATA = 24,  //! numero de bits de data
    parameter NB_INST = 32   //! numero de bits de instruccion
) (
    output [NB_INST-1:0] o_data_to_micro,      //! gpo0
    output [        1:0] o_kernel_sel,
    output               o_load,
    output               o_get_pixels,
    output [NB_DATA-1:0] o_pixels_from_micro,  //! pixels from micro, 3 per instruction
    output               o_start_conv,

    input [NB_INST-1:0] i_cmd_from_micro,   //! gpi0
    input               i_frame_ready,
    input [NB_INST-1:0] i_pixels_from_mem,  //! pixels to gpo0, 4 pixels per call
    input               clock,
    input               reset
);


  //!---------------- Comandos disponibles ----------------
  localparam [NB_C0M -1:0] KERNEL_SEL = 7'b0000000;
  localparam [NB_C0M -1:0] LOAD_FRAME = 7'b0000001;
  localparam [NB_C0M -1:0] END_FRAME = 7'b0000010;
  localparam [NB_C0M -1:0] IS_FRAME_READY = 7'b0000011;
  localparam [NB_C0M -1:0] GET_FRAME = 7'b0000100;
  //!------------------------------------------------------

  reg  [        1:0] kernel_sel;
  reg  [NB_INST-1:0] data_to_micro;
  reg  [NB_DATA-1:0] pixels_to_process;

  reg                state_enable;  //! Detector de flanco ascendente
  reg                get_pixels;
  reg                is_loading;
  reg                start_conv;

  wire [NB_DATA-1:0] data_from_micro;
  wire [NB_C0M -1:0] command_from_micro;
  wire               enable_from_micro;

  always @(posedge clock) begin
    if (reset) begin
      kernel_sel    <= 0;
      data_to_micro <= 0;
      state_enable  <= 0;
      get_pixels    <= 0;
      is_loading    <= 0;
      start_conv    <= 0;
    end else begin
      if ((enable_from_micro == 1'b1) && (state_enable == 1'b0)) begin
        // flanco de subida del enable detectado
        // se toma la instruccion
        case (command_from_micro)
          KERNEL_SEL: kernel_sel <= data_from_micro[1:0];

          LOAD_FRAME: is_loading <= 1'b1;

          END_FRAME: begin
            is_loading <= 1'b1;
            start_conv <= 1'b1;
          end

          IS_FRAME_READY: data_to_micro <= i_frame_ready;

          GET_FRAME:
          if (i_frame_ready) begin
            get_pixels <= 1'b1;
            data_to_micro <= i_pixels_from_mem;
          end

        endcase
      end else begin
        is_loading <= 1'b0;
        get_pixels <= 1'b0;
        start_conv <= 1'b0;
      end
      state_enable <= enable_from_micro;
    end

  end

  assign o_data_to_micro     = data_to_micro;
  assign o_kernel_sel        = kernel_sel;
  assign o_load              = is_loading;
  assign o_get_pixels        = get_pixels;
  assign o_pixels_from_micro = data_from_micro;
  assign o_start_conv        = start_conv;

  assign command_from_micro  = i_cmd_from_micro[NB_INST-2:NB_DATA];
  assign data_from_micro     = i_cmd_from_micro[NB_DATA-1:0];
  assign enable_from_micro   = i_cmd_from_micro[NB_INST-1];

endmodule
