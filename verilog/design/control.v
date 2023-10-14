module control #(
    parameter NB_COUNT = 2
)(
    output  o_valid,
    input   clock,
    input   i_reset
);

    reg [NB_COUNT-1:0]  counter;

    always @(posedge clock) begin
        if (i_reset)
            counter <= 0;
        else begin
            counter <= (counter == {NB_COUNT{1'b1}}) ? 0 : counter + 1; 
        end
    end
    
    assign o_valid = (counter == {NB_COUNT{1'b1}});

endmodule