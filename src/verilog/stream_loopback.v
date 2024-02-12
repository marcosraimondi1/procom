`timescale 1ns / 1ps

// THIS MODULE TESTS AXI STREAM INTERFACE WITH A LOOPBACK 

module axi_stream_loopback #(
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

  integer i;
  always @(posedge axi_clk) begin
    if (s_axis_ready & s_axis_valid) begin
      for (i = 0; i < DATA_WIDTH / 8; i = i + 1) begin
        m_axis_data[i*8+:8] <= s_axis_data[i*8+:8];
      end
    end
  end

  always @(posedge axi_clk) begin
    m_axis_valid <= s_axis_valid & s_axis_ready; // slave accepted data, so master has valid data to send in the next clock
  end
endmodule
