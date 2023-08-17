//! @title FIR Filter - Testbench
//! @file filtro_fir.v
//! @author Advance Digital Design - Ariel Pola
//! @date 29-08-2021
//! @version Unit02 - Modelo de Implementacion

//! - Fir polifasic filter with 6 coefficients 
//! - **i_srst** is the system reset.
//! - **i_en** controls the enable (1) of the FIR. The value (0) stops the systems without change of the current state of the FIR.
//! - Coefficients from raised cosine filter

`timescale 1ns/1ps

module tb_filtro_fir ();

  parameter NB_INPUT   = 8; //! NB of input
  parameter NBF_INPUT  = 7; //! NBF of input
  parameter NB_OUTPUT  = 8; //! NB of output
  parameter NBF_OUTPUT = 7; //! NBF of output
  parameter NB_COEFF   = 8; //! NB of Coefficients
  parameter NBF_COEFF  = 7; //! NBF of Coefficients
 
  reg                 tb_clock = 1'b1 ;
  reg                 tb_enable       ;
  reg                 tb_reset        ;
  reg  [NB_INPUT-1:0] tb_i_data       ;

  wire [NB_OUTPUT-1:0] tb_o_data;

  reg             aux_tb_enable;
  reg             aux_tb_reset;
  reg  [NB_INPUT-1:0] aux_tb_i_data;

  //! Instance of FIR
  filtro_fir
    #(
      .NB_INPUT   (NB_INPUT), //! NB of input
      .NBF_INPUT  (NBF_INPUT), //! NBF of input
      .NB_OUTPUT  (NB_OUTPUT), //! NB of output
      .NBF_OUTPUT (NBF_OUTPUT), //! NBF of output
      .NB_COEFF   (NB_COEFF), //! NB of Coefficients
      .NBF_COEFF  (NBF_COEFF)  //! NBF of Coefficients
    )
    u_filtro_fir 
      (
        .o_data  (tb_o_data),
        .i_data  (tb_i_data),
        .i_reset (tb_reset),
        .i_enable(tb_enable),
        .clock   (tb_clock)
      );

  // Clock
  always #20 tb_clock = ~tb_clock;

  always @(posedge tb_clock) begin
    tb_enable     <= aux_tb_enable  ;
    tb_reset      <= aux_tb_reset   ;
    tb_i_data     <= aux_tb_i_data  ;
  end

  // Stimulus
  real i;
  real aux;
  initial begin
    $display("");
    $display("Simulation Started");
    //$dumpfile("./verification/tb_filtro_fir/waves.vcd");
    //$dumpvars(0, tb_filtro_fir);
    #5
    aux_tb_enable      = 1'b1;
    aux_tb_reset       = 1'b1;
    
    #40;
    aux_tb_enable      = 1'b1;
    aux_tb_reset       = 1'b0;
    
    #1000
    for (i=0;i<1000;i=i+1) begin
      aux = aux == 0.9 ? -0.9 : 0.9;
      aux_tb_i_data = aux * (2**NBF_INPUT);
      #40;
    end
    $display("Simulation Finished");
    $display("");
    $finish;
  end

endmodule
