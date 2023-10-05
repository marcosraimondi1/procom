`timescale 1ns / 100ps

module tb_bram;

  // Parameters
  parameter RAM_WIDTH = 18;
  parameter RAM_DEPTH = 1024;
  parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE";
  parameter INIT_FILE = "";

  // Inputs
  reg clk;
  reg wea;
  reg ena;
  reg rsta;
  reg regcea;
  reg [RAM_WIDTH-1:0] dina;
  reg [clogb2(RAM_DEPTH-1)-1:0] addra;
  reg [RAM_WIDTH-1:0] aux [RAM_DEPTH-1:0];   
  
  // Outputs
  wire [RAM_WIDTH-1:0] douta;

  // Instantiate the Unit Under Test (UUT)
  xilinx_single_port_ram_no_change #(
    .RAM_WIDTH(RAM_WIDTH),
    .RAM_DEPTH(RAM_DEPTH),
    .RAM_PERFORMANCE(RAM_PERFORMANCE),
    .INIT_FILE(INIT_FILE)
  ) uut (
    .clka(clk),
    .wea(wea),
    .ena(ena),
    .rsta(rsta),
    .regcea(regcea),
    .dina(dina),
    .addra(addra),
    .douta(douta)
  );

  // Clock generation
  always #1 clk = ~clk;

  // Write data to memory
  initial begin
    clk = 0;
    wea = 1;
    ena = 1;
    rsta = 0;
    regcea = 1'b1;
    dina = 0;
    addra = 9'b000000000;

    // Write data to memory
    #1 wea = 1;

    repeat (RAM_DEPTH) begin
      #1 addra = addra + 1; 
      #1 dina = addra;//% (2 ** RAM_WIDTH); 
      
      aux[addra] = dina;   
    end

    // Read data from memory
    #1 wea = 0;                  // habilita lectura 
    //#10;
    #2 addra = 9'b000000000;
    

    repeat (RAM_DEPTH) begin
      #4; //Posee una latencia de 2 ciclos para sinconizacion de lectura
      if (douta != aux[addra])
      begin
        //$display("Data mismatch at address: %d  dout: %d  aux[addra]: %d", addra, dout, aux[addra]);
        $display("Data mismatch at address: %d", addra);
        $display("Data douta: %d", douta);
        $display("Data aux: %d", aux[addra]);
      end
      #2 addra = addra + 1;
    end

    $display("Memory test passed");
    $finish;
  end

//  The following function calculates the address width based on specified RAM depth
// calcula cuantos bits de direccion hacen falta para direccionar la memoria
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction
endmodule