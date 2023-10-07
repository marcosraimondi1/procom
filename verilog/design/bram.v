module bram #(
    parameter RAM_WIDTH =    32,    // Specify RAM data width
    parameter RAM_DEPTH = (2**15)   // 32767 Specify RAM depth (number of entries)
)
(
    input                                           clk,    //! Clock
    input                                         reset,    //! Reset
    input                                     i_run_log,    //! Start saving input data
    input                                    i_read_log,    //! 
    input  [RAM_WIDTH-1:0]             i_data_tx_to_mem,    //! data in [31:0]   
    input  [clogb2(RAM_DEPTH-1)-1:0]  i_addr_log_to_mem,    //! read address [14:0]
    
    output [RAM_WIDTH-1:0]          o_data_log_from_mem,    //! data out [31:0]
    output                                   o_mem_full     //! Memory full
);

  // Local Parameters
  localparam RAM_PERFORMANCE = "LOW_LATENCY";
  localparam INIT_FILE = "";
  localparam [1:0] idle  = 2'b00;
  localparam [1:0] start = 2'b01;
  localparam [1:0] full  = 2'b10;
  //localparam [1:0] stop  = 2'b11;

  // Inputs
  reg wea;
  reg ena;
  reg regcea;
  reg [RAM_WIDTH-1:0] dina;
  reg [clogb2(RAM_DEPTH-1)-1:0] addra;
  // reg [RAM_WIDTH-1:0] aux [RAM_DEPTH-1:0];
  reg   [2:0]                state_reg;
  
  // Outputs
  wire [RAM_WIDTH-1:0] douta;
  
  always @(posedge clk) begin
    if (reset) begin
        addra     <= 0;
        dina      <= 0;
        wea       <= 1'b0;
        ena       <= 1'b0;
        regcea    <= 1'b1;
        state_reg <=  2'b00;
    end
    else begin
        case (state_reg)

        idle:
            if(i_run_log) begin
                ena       <= 1'b1 ;
                addra     <= 0    ;
                //wea       <= 1'b1;
                state_reg <= start;
            end

        start:
            begin
            wea       <= 1'b1;
            dina      <= i_data_tx_to_mem;
            if(wea)
                addra     <= addra + 1;
            
            if(addra == RAM_DEPTH-1) begin
                // mem full 
                wea       <= 1'b0;
                state_reg <= full;
            end
            end

        full:
          begin
          if (i_read_log) begin
            regcea    <= 1'b1;
            addra     <= i_addr_log_to_mem; // direccion a leer
          end
          else if(i_run_log) begin
            regcea    <= 1'b0;
            addra     <= 0    ;
            state_reg <= start;
          end
          end
            
        default: 
          state_reg <= idle;
          
        endcase
    end
  end

assign o_mem_full = (state_reg == full) ? 1'b1 : 1'b0;
assign o_data_log_from_mem = douta;

  // Instantiate RAM
  xilinx_single_port_ram_no_change #(
    .RAM_WIDTH(RAM_WIDTH),
    .RAM_DEPTH(RAM_DEPTH),
    .RAM_PERFORMANCE(RAM_PERFORMANCE),
    .INIT_FILE(INIT_FILE)
  ) ram (
    .clka(clk),
    .wea(wea),
    .ena(ena),
    .rsta(reset),
    .regcea(regcea),
    .dina(dina),
    .addra(addra),
    .douta(douta)
  );

  // calcula cuantos bits de direccion hacen falta para direccionar la memoria
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction
    
endmodule