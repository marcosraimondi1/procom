module ber (
    output  [63:0]  o_errors    ,
    output  [63:0]  o_bits      ,
    input           i_rx        , //! bit recibido
    input           i_ref       , //! bit de referencia
    input           i_valid     , //! senal de validacion
    input           clock       ,
    input           i_reset
);

// para sincronizacion
reg [510:0] ref_buffer          ; //! buffer de referencia
reg [8:0]   latency             ; //! latencia actual
reg [8:0]   counter             ; //! contador
reg [8:0]   sync_errors         ; //! contador de errores para sincronizacion
reg [8:0]   min_latency         ; //! valor minimo de latencia
reg [8:0]   min_error           ; //! valor minimo de errores
wire        synced              ; //! si esta sincronizado

// para contador de ber
reg [63:0]  error_count         ; //! error count
reg [63:0]  bit_count           ; //! bit count


always @(posedge clock)
begin
    if (i_reset)
        begin
            // sincronizacion
            latency     <= 0            ;
            sync_errors <= 0            ;
            min_latency <= 0            ;
            min_error   <= 510          ; // error maximo
            ref_buffer  <= {511{1'b0}}  ;
            counter     <= 0            ;

            // contador de ber
            error_count <= 64'b0        ;
            bit_count   <= 64'b0        ;
        end
    else
        begin
            if (i_valid)
                begin
                    counter     <= counter + 1 ;

                    // ingreso muestra al buffer de referencia
                    ref_buffer <= {ref_buffer[509:0], i_ref} ;

                    if (~synced)
                    begin
                            // sincronizacion --------------------------- 

                            // cuento error
                            sync_errors <= sync_errors + (ref_buffer[latency] ^ i_rx) ;

                            if (counter == 511)
                                begin
                                    counter <= 0 ;
                                    // verifico si es el minimo error
                                    if (sync_errors < min_error)
                                        begin
                                            min_error   <= sync_errors ;
                                            min_latency <= latency     ;
                                        end

                                    // reseteo contador de errores
                                    sync_errors <= 0 ;
                                    
                                    // incremento la latencia
                                    latency <= latency + 1 ;
                                end
                                                        
                        end
                    else
                        begin
                            // contador de ber ---------------------------
                            bit_count   <= bit_count   + 1 ;
                            error_count <= error_count + (ref_buffer[min_latency] ^ i_rx) ;
                        end
                end
            else
                begin
                    // sincronizacion
                    latency     <= latency      ;
                    sync_errors <= sync_errors  ;
                    min_latency <= min_latency  ;
                    min_error   <= min_error    ;
                    ref_buffer  <= ref_buffer   ;
                    counter     <= counter      ;

                    // contador de ber
                    error_count <= error_count ;
                    bit_count   <= bit_count   ;
                end
        end
end



assign synced   = latency == 511    ;
assign o_errors = error_count       ;
assign o_bits   = bit_count         ;

endmodule