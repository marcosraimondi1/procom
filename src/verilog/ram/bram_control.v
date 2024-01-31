module bram_control #(
    parameter RAM_WIDTH     = 8,          // Specify RAM data width
    parameter RAM_DEPTH     = (2 ** 16),  // 65536 Specify RAM depth (number of entries)
    parameter IMAGE_WIDTH   = 10,
    parameter IMAGE_HEIGHT  = 10,
    parameter INIT_FILE     = "",
    parameter KERNEL_WIDTH  = 3,
    parameter TO_PROCESS = 0
) (
    input                 clk,            //! Clock
    input                 reset,          //! Reset
    input                 i_load_valid,   //! Save input
    input [RAM_WIDTH-1:0] i_data_to_mem,  //! data in [7:0]
    input                 i_read_valid,   //! Valid to read

    output                 o_valid_data_to_conv, //! valid data to convolver (cuando esta en 1, el dato en los 3 puertos de salida es valido)
    output [RAM_WIDTH-1:0] o_data_from_mem,    //! data out to bram [7:0]
    output [RAM_WIDTH-1:0] o_to_conv0,            //! data to convolver (3 pixeles)
    output [RAM_WIDTH-1:0] o_to_conv1,
    output [RAM_WIDTH-1:0] o_to_conv2
);

  // Local Parameters
  localparam RAM_PERFORMANCE = "LOW_LATENCY";
  localparam [1:0] LOAD_FRAME = 2'b01;
  localparam [1:0] PROCESS_FRAME = 2'b10;
  localparam [1:0] GET_FRAME = 2'b11;

  localparam [clogb2(IMAGE_HEIGHT*IMAGE_WIDTH - 1) - 1:0] RESOLUTION = IMAGE_HEIGHT * IMAGE_WIDTH;

  // RAM Inputs
  reg                               wea;
  reg                               ena;
  reg                               regcea;
  reg  [             RAM_WIDTH-1:0] dina;
  reg  [   clogb2(RAM_DEPTH-1)-1:0] addra;  // direccion de memoria

  // RAM Outputs
  wire [             RAM_WIDTH-1:0] douta;

  // Variables
  reg  [                       2:0] state_reg;
  reg  [   clogb2(RAM_DEPTH-1)-1:0] current_col_addra;
  reg  [   clogb2(RAM_DEPTH-1)-1:0] current_row_addra;
  reg  [clogb2(KERNEL_WIDTH-1)-1:0] pixels_read_counter;
  reg                               read_rising_edge;
  reg  [             RAM_WIDTH-1:0] pixels_to_conv       [KERNEL_WIDTH-1:0];

  always @(posedge clk) begin
    if (reset) begin
      addra               <= 0;
      current_col_addra   <= 0;
      current_row_addra   <= 0;
      dina                <= 0;
      wea                 <= 1'b0;
      ena                 <= 1'b1;
      regcea              <= 1'b1;
      state_reg           <= LOAD_FRAME;
      
      pixels_read_counter <= 2'b0;
      pixels_to_conv[0] <= 0;
      pixels_to_conv[1] <= 0;
      pixels_to_conv[2] <= 0;
    end else begin
      case (state_reg)

        LOAD_FRAME: begin  // Carga de 1 pixel en la memoria
          if (i_load_valid) begin
            wea  <= 1'b1;
            dina <= i_data_to_mem;
            if (wea) addra <= addra + 1;
          end
          if (addra == RESOLUTION - 1) begin
            // frame complete in memory
            wea <= 1'b0;
            if (TO_PROCESS) state_reg <= PROCESS_FRAME;
            else state_reg <= GET_FRAME;

            addra             <= 0;
            current_col_addra <= 0;
            current_row_addra <= 0;
            regcea <= 1'b1;
          end
        end

        PROCESS_FRAME: begin  // Lee de 1 pixel en memoria en el orden de procesamiento del kernel
          
          if (i_read_valid) begin

            if (current_row_addra >= (RESOLUTION - IMAGE_WIDTH + current_col_addra + KERNEL_WIDTH - 1)) begin

              if (current_col_addra >= IMAGE_WIDTH - 3) begin
                // frame read complete
                regcea    <= 1'b0;
              end else begin
                // column read complete
                current_col_addra = current_col_addra + 1'b1;
                current_row_addra = current_col_addra;
              end
            end

            if (pixels_read_counter == KERNEL_WIDTH - 1) begin
              // finished reading 3 pixels, advance to next 3 pixels
              pixels_read_counter <= 0;
              current_row_addra   <= current_row_addra + IMAGE_WIDTH;

            end else begin
              // get next contiguous pixel
              pixels_read_counter <= pixels_read_counter + 1'b1;
            end

            addra <= current_row_addra + pixels_read_counter;
            
            pixels_to_conv[pixels_read_counter] <= douta;


          end

          if (regcea == 1'b0) begin
            state_reg <= LOAD_FRAME;
            addra <= 0;
          end
        end

        GET_FRAME: begin
          regcea <= 1'b1;
          if (read_rising_edge) begin
            addra <= addra + 1'b1;

            if (addra == RESOLUTION - 1) begin
              // frame read complete
              state_reg <= LOAD_FRAME;
              regcea    <= 1'b0;
              addra <= 0;
            end
          end
        end

        default: state_reg <= LOAD_FRAME;

      endcase
    end
  end

  reg last_read_state;

  always @(posedge clk) begin : detect_rising_edge
    if (reset) begin
      last_read_state  <= 0;
      read_rising_edge <= 0;
    end else begin
      last_read_state <= i_read_valid;

      if (last_read_state == 0 && i_read_valid == 1) read_rising_edge <= 1;
      else read_rising_edge <= 0;

    end
  end

  assign o_data_from_mem = douta;
  assign o_valid_data_to_conv = (pixels_read_counter == KERNEL_WIDTH - 1) ? 1'b1 : 1'b0; //TODO MAL
  assign o_to_conv1 = pixels_to_conv[0];
  assign o_to_conv2 = pixels_to_conv[1];
  assign o_to_conv0 = pixels_to_conv[2];

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
    for (clogb2 = 0; depth > 0; clogb2 = clogb2 + 1) depth = depth >> 1;
  endfunction

endmodule

/*
  IMAGEN DE 10x10:
  [
    [0  1  2  3  4  5  6  7  8  9 ]
    [10 11 12 13 14 15 16 17 18 19]   
    [20 21 22 23 24 25 26 27 28 29]   
    [30 31 32 33 34 35 36 37 38 39]
    [40 41 42 43 44 45 46 47 48 49]
    [50 51 52 53 54 55 56 57 58 59]
    [60 61 62 63 64 65 66 67 68 69]
    [70 71 72 73 74 75 76 77 78 79]
    [80 81 82 83 84 85 86 87 88 89]
    [90 91 92 93 94 95 96 97 98 99]    
  ]

  IMAGEN EN BRAM:
  [
    1
    2
    3 
    4
    5
    6
    7
    8
    9
    10
    11
    12
    13
    14
    15
    16
    17
    18
    19
    20
    21
    22
.....
]
  
WORKFLOW DE LECTURA DURANTE EL PROCESAMIENTO:
{
      ancho = 10
      altura = 10

      addr0 = 0
      actual = addr0

      // se piden 3 pixeles
      0 <-- actual
      1 <-- actual + 1
      2 <-- actual + 2

      actual = actual + ancho // actual = 10

      // se piden otros 3 pixeles
      10 <-- actual
      11 <-- actual + 1
      12 <-- actual + 2

      actual = actual + ancho // actual = 20

      // se piden otros 3 pixeles
      20 <-- actual
      21 <-- actual + 1
      22 <-- actual + 2

      .... hasta llegar a que actual >= altura*ancho
      // entonces se vuelve a empezar desde el principio aumentando en 1 addr0
      
      addr0 = addr0 + 1
      actual = addr0

      // se piden 3 pixeles
      1 <-- actual
      2 <-- actual + 1
      3 <-- actual + 2

      actual = actual + ancho // actual = 11

      // se piden otros 3 pixeles
      11 <-- actual
      12 <-- actual + 1
      13 <-- actual + 2

      actual = actual + ancho // actual = 21


      ... se repite hasta que actual >= altura*ancho
      // entonces se vuelve a empezar desde el principio aumentando en 1 addr0
        addr0 = addr0 + 1
      // addr0 se aumenta hasta que sea igual a ancho-2 (si ya tiene padding)

}
      
ESTADO DE CARGA: // LOAD_FRAME 01
- Para cargar el frame, se carga un pixel atras de otro aumentando en uno la direccion de memoria
- Necesitamos que nos de algun bit que nos de datos nuevos para cargar(valid/enable)

ESTADO DE PROCESAMIENTO: // PROCESS_FRAME 10
- Para saber si el frame esta listo se revisa la direccion de memoria (si alcanzo el numero de pixeles de la imagen) cuando se esta procesando
- Cuando se lea, se devolveran 3 pixeles (por el tamano del kernel) que son los tres pixeles contiguos (en la imagen original)


- cuando se piden 3 pixeles, se devuelven 3 pixeles seguidos de la bram (contiguos en la imagen original) 
  y se aumenta en 10 (ancho de la imagen) la direccion de memoria
- cuando la direccion de memoria llega al final de la imagen o supera el final de la imagen (ancho x altura),
  se vuelve la direccion de memoria al inicio anterior mas uno (seria que el kernel se mueve una columna a la derecha)
  

ESTADO DE LECTURA DEL FRAME COMPLETO (YA PROCESADO) para enviarlo al ublaze: // GET_FRAME 11
- Para leer el frame, se lee un pixel atras de otro aumentando en uno la direccion de memoria (valid/enable)
- Necesitamos que quede completa la memoria para poder leerla



*/


