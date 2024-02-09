`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.02.2024 08:42:16
// Design Name: 
// Module Name: axi_stream
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi_stream #(
    parameter DATA_WIDTH=32
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

    integer i;
    always @(posedge axi_clk) begin
        if (s_axis_ready & s_axis_valid) begin
            for (i = 0; i<DATA_WIDTH/8; i=i+1) begin
                m_axis_data[i*8 +: 8] <= s_axis_data[i*8 +: 8]; // (loopback)
            end
        end
    end

    always @(posedge axi_clk) begin
        m_axis_valid <= s_axis_valid & s_axis_ready; // slave accepted data, so master has valid data to send (loopback)
    end




endmodule