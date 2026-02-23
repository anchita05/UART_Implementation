module baud_gen (
    input clk,
    input reset,
    input [10:0] dvsr,
    output tick
);

    reg [10:0] r_reg;
    wire [10:0] r_next;

    always @(posedge clk or posedge reset) begin
        if (reset)
            r_reg <= 0;
        else
            r_reg <= r_next;
    end

    // Use a comparison to dvsr to reset the counter
    assign r_next = (r_reg == dvsr) ? 11'b0 : r_reg + 1'b1;
    
    // Tick is high for one clock cycle when counter wraps around
    assign tick = (r_reg == dvsr);

endmodule
