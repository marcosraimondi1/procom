module bram_control #(
    parameter RAM_WIDTH    = 8,          // Specify RAM data width
    parameter RAM_DEPTH    = (2 ** 16),  // 65536 Specify RAM depth (number of entries)
    parameter IMAGE_WIDTH  = 10,
    parameter IMAGE_HEIGHT = 10,
    parameter INIT_FILE    = "",
    parameter KERNEL_WIDTH = 3
) (
    input                 clk,                    //! Clock
    input                 reset,                  //! Reset
    input                 i_start_loading,        //! Start saving input data from ublaze
    input                 i_valid_get_frame,      //! Valid data from from file_register
    input [RAM_WIDTH-1:0] i_data_to_mem,          //! data in [7:0]        
    
    output [RAM_WIDTH-1:0] o_data_from_mem,       //! data out to bram [7:0]
    output                 o_is_frame_ready,      //! frame ya procesado y listo para leer
    
    // SEÑALES UTILES PARA EL CONVOLUCIONADOR
    input                  i_read_for_processing,  //! Valid to read for processing (un pulso por cada 3 pixeles)
    output                 o_valid_data_to_conv,  //! valid data to convolver (cuando esta en 1, el dato en los 3 puertos de salida es valido)    
    output [RAM_WIDTH-1:0] o_to_conv0,            //! data to convolver (3 pixeles)
    output [RAM_WIDTH-1:0] o_to_conv1,
    output [RAM_WIDTH-1:0] o_to_conv2
);

  // Local Parameters
  localparam RAM_PERFORMANCE = "LOW_LATENCY";
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] LOAD_FRAME = 2'b01;
  localparam [1:0] PROCESS_FRAME = 2'b10;
  localparam [1:0] GET_FRAME = 2'b11;

  localparam [clogb2(IMAGE_HEIGHT*IMAGE_WIDTH - 1) - 1:0] RESOLUTION = IMAGE_HEIGHT * IMAGE_WIDTH;

  // Inputs
  reg                               wea;
  reg                               ena;
  reg                               regcea;
  reg  [             RAM_WIDTH-1:0] dina;
  reg  [   clogb2(RAM_DEPTH-1)-1:0] addra;  // direccion de memoria
  reg  [   clogb2(RAM_DEPTH-1)-1:0] proc_state_addra;
  reg  [   clogb2(RAM_DEPTH-1)-1:0] proc_state_current_addra;
  reg  [                       2:0] state_reg;
  reg  [             RAM_WIDTH-1:0] pixels_to_conv                 [KERNEL_WIDTH-1:0];

  // Outputs
  wire [             RAM_WIDTH-1:0] douta;

  reg  [clogb2(KERNEL_WIDTH-1)-1:0] pixels_read_counter;

  always @(posedge clk) begin
    if (reset) begin
      addra                    <= 8'b0;
      proc_state_addra         <= 0;
      proc_state_current_addra <= 0;
      dina                     <= 0;
      wea                      <= 1'b0;
      ena                      <= 1'b1;
      regcea                   <= 1'b1;
      state_reg                <= 2'b00;
      pixels_read_counter      <= 2'b0;

      pixels_to_conv[0] <= 0;
      pixels_to_conv[1] <= 0;
      pixels_to_conv[2] <= 0;
      
    end else begin
      case (state_reg)

        IDLE:
        if (i_start_loading) begin
          ena       <= 1'b1;
          addra     <= 0;  // posicion inicial
          state_reg <= LOAD_FRAME;
        end

        LOAD_FRAME: begin //Carga de 1 pixel en la memoria
          wea  <= 1'b1;
          dina <= i_data_to_mem;
          if (wea) addra <= addra + 1;

          if (addra == RESOLUTION - 1) begin
            // frame complete in memory
            wea                      <= 1'b0;
            state_reg                <= PROCESS_FRAME;
            addra                    <= 0;
            proc_state_addra         <= 0;
            proc_state_current_addra <= 0;
          end
        end

        PROCESS_FRAME: begin //Envio de 3 pixel al convolver
          regcea <= 1'b1;
          if (i_read_for_processing) begin
            if (proc_state_current_addra >= (RESOLUTION - IMAGE_WIDTH + proc_state_addra + KERNEL_WIDTH - 1)) begin

              if (proc_state_addra >= IMAGE_WIDTH - 3) begin
                // frame read complete
                regcea    <= 1'b0;
                state_reg <= GET_FRAME;
              end else begin
                // column read complete
                proc_state_addra = proc_state_addra + 1'b1;
                proc_state_current_addra = proc_state_addra;
              end

            end

            if (pixels_read_counter == KERNEL_WIDTH - 1) begin
              // finished reading 3 pixels, advance to next 3 pixels
              pixels_read_counter <= 0;
              proc_state_current_addra <= proc_state_current_addra + IMAGE_WIDTH;

            end else begin
              // get next contiguous pixel
              pixels_read_counter <= pixels_read_counter + 1'b1;
            end

            addra <= proc_state_current_addra + pixels_read_counter; 
            
            pixels_to_conv[pixels_read_counter] <= douta;  

            // TODO: check output data when process state
            // TODO: i_read_for_processing should be a pulse signal (only get next 3 pixels when pulse is received)
            // TODO: check o_valid_data_to_conv when process state
            // TODO: maybe a valid singal is needed to know when the to load pixels in LOAD STATE

          end
        end

        GET_FRAME: begin
          if (i_valid_get_frame) begin
            regcea <= 1'b1;

            if (regcea) addra <= addra + 1'b1;

            if (addra == RESOLUTION - 1) begin
              // frame read complete
              regcea    <= 1'b0;
              state_reg <= IDLE;
            end
          end
        end

        default: state_reg <= IDLE;

      endcase
    end
  end

  assign o_is_frame_ready = (state_reg == GET_FRAME) ? 1'b1 : 1'b0;
  assign o_data_from_mem = douta;
  assign o_valid_data_to_conv = (pixels_read_counter == KERNEL_WIDTH - 1) ? 1'b1 : 1'b0; //TODO MAL
  assign o_to_conv0 = pixels_to_conv[0];
  assign o_to_conv1 = pixels_to_conv[1];
  assign o_to_conv2 = pixels_to_conv[2];

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


