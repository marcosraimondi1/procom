`timescale 1ns / 1ps

// THIS MODULE USES AXI STREAM INTERFACE FOR 2D CONVOLUTION of frames

module axi_stream_convolver #(
    parameter IMAGE_HEIGHT = 200,  // Image height with zero padding
    parameter KERNEL_WIDTH = 3,
    parameter NB_PIXEL = 8,
    parameter NB_COEFF = 8,
    parameter KERNEL_SIZE = KERNEL_WIDTH * KERNEL_WIDTH,
    parameter NB_CONV = KERNEL_SIZE * NB_PIXEL,
    parameter DATA_WIDTH = 32
) (
    input axi_clk,
    input axi_reset_n,

    // axi stream slav interface
    input s_axis_valid,
    input [DATA_WIDTH-1:0] s_axis_data,
    output s_axis_ready,

    // axi stream master interface
    output reg m_axis_valid,
    output reg [DATA_WIDTH-1:0] m_axis_data,
    input m_axis_ready
);

  assign s_axis_ready = m_axis_ready; // slave is ready to receive data when master can send data (loopback)

  wire i_rst;
  assign i_rst = ~axi_reset_n;

  wire [DATA_WIDTH-1:0] data_from_convolver_to_master_out;

  integer i;
  always @(posedge axi_clk) begin
    if (s_axis_ready & s_axis_valid) begin
      for (i = 0; i < DATA_WIDTH / 8; i = i + 1) begin
        m_axis_data[i*8+:8] <= data_from_convolver_to_master_out[i*8+:8];
      end
    end
  end

  always @(posedge axi_clk) begin
    m_axis_valid <= s_axis_valid & s_axis_ready; // slave accepted data, so master has valid data to send in the next clock
  end


  top_convolver #(
      .IMAGE_HEIGHT(IMAGE_HEIGHT),  // Image height with zero padding
      .KERNEL_WIDTH(KERNEL_WIDTH),
      .NB_PIXEL(NB_PIXEL),
      .NB_COEFF(NB_COEFF),
      .KERNEL_SIZE(KERNEL_SIZE),
      .NB_CONV(NB_CONV),
      .NB_DATA(DATA_WIDTH)
  ) u_top_convolver (
      .i_clk     (axi_clk),
      .i_reset   (i_rst),
      .i_axi_data(s_axis_data),
      .i_valid   (s_axis_valid),
      .o_axi_data(data_from_convolver_to_master_out)
  );


endmodule
