`timescale 1ns / 100ps

module bram_tb;

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
  reg [RAM_WIDTH-1:0] BRAM [clogb2(RAM_DEPTH-1)-1:0];   
  
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
  always #5 clk = ~clk;

  // Write data to memory
  initial begin
    clk = 0;
    wea = 1;
    ena = 1;
    rsta = 0;
    regcea = 0;
    dina = 0;
    addra = 0;

    // Write data to memory
    repeat (RAM_DEPTH) begin
      dina = $random;
      addra = addra + 1;
      BRAM[addra] = dina;
      #1 wea = 0;
      #1 wea = 1;
    end

    // Read data from memory
    addra = 0;
    wea = 1;
    repeat (RAM_DEPTH) begin
      #1 addra = addra + 1;
      #1 wea = 0;
      #1 wea = 1;
     //      
      if (douta != BRAM[addra])
      begin
        $display("Data mismatch at address %d", addra);
      end
    end

    $display("Memory test passed");
    $finish;
  end

//  The following function calculates the address width based on specified RAM depth
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction
endmodule