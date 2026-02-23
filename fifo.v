module fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk, reset,
    input rd, wr,
    input [DATA_WIDTH-1:0] w_data,
    output full, empty,
    output [DATA_WIDTH-1:0] r_data
);

    localparam DEPTH = 1 << ADDR_WIDTH;
    reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] w_ptr_reg, r_ptr_reg;
    reg [ADDR_WIDTH:0] count_reg; 

    // Sequential logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            w_ptr_reg <= 0;
            r_ptr_reg <= 0;
            count_reg <= 0;
        end else begin
            if (wr && !full) begin
                fifo_mem[w_ptr_reg] <= w_data;
                w_ptr_reg <= w_ptr_reg + 1;
            end
            if (rd && !empty) begin
                r_ptr_reg <= r_ptr_reg + 1;
            end
            
            // Count logic
            if (wr && !full && !(rd && !empty))
                count_reg <= count_reg + 1;
            else if (rd && !empty && !(wr && !full))
                count_reg <= count_reg - 1;
        end
    end

    // Combinational Output (Reduces latency for UART TX)
    assign r_data = fifo_mem[r_ptr_reg];
    assign full   = (count_reg == DEPTH);
    assign empty  = (count_reg == 0);

endmodule
