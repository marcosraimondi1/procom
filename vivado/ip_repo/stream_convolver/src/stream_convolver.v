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
    input s0_axis_valid,
    input [DATA_WIDTH-1:0] s0_axis_data,
    output s0_axis_ready,

    input s1_axis_valid,
    input [DATA_WIDTH-1:0] s1_axis_data,
    output s1_axis_ready,

    // axi stream master interface
    output reg m0_axis_valid,
    output reg [DATA_WIDTH-1:0] m0_axis_data,
    input m0_axis_ready,

    output reg m1_axis_valid,
    output reg [DATA_WIDTH-1:0] m1_axis_data,
    input m1_axis_ready
);

  assign s0_axis_ready = m0_axis_ready; // slave is ready to receive data when master can send data (loopback)
  assign s1_axis_ready = 1'b1; // always ready to receive kernel

  wire i_rst;
  assign i_rst = ~axi_reset_n;

  reg [1:0] kernel_sel_from_slave1;

  wire [DATA_WIDTH-1:0] data_from_convolver_to_master0_out;

  integer i;
  always @(posedge axi_clk) begin:send_frame_to_master0
    if (s0_axis_ready & s0_axis_valid) begin
      for (i = 0; i < DATA_WIDTH / 8; i = i + 1) begin
        m0_axis_data[i*8+:8] <= data_from_convolver_to_master0_out[i*8+:8];
      end
    end
  end

  always @(posedge axi_clk) begin
    m0_axis_valid <= s0_axis_valid & s0_axis_ready; // slave accepted data, so master has valid data to send in the next clock
    m1_axis_valid <= s1_axis_valid & s1_axis_ready; // slave accepted data, so master has valid data to send in the next clock
  end


  always @(posedge axi_clk) begin:receive_kernel
    if (i_rst) begin
      kernel_sel_from_slave1 = 0;
    end 
    else begin
      if (s1_axis_ready & s1_axis_valid) begin
        kernel_sel_from_slave1 <= s1_axis_data[1:0];
      end
    end
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
      .i_axi_data(s0_axis_data),
      .i_valid   (s0_axis_valid),
      .i_kernel_sel(kernel_sel_from_slave1),
      .o_axi_data(data_from_convolver_to_master0_out)
  );


endmodule
