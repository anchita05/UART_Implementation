`include "uart.v"

module chu_uart #(
    parameter FIFO_DEPTH_BIT = 8  // # addr bits of FIFO
)(
    input clk,
    input reset,

    // slot interface
    input cs,
    input read,
    input write,
    input [4:0] addr,
    input [31:0] wr_data,
    output [31:0] rd_data,
    output tx,
    input rx
);

    // Signal declarations
    wire wr_uart, rd_uart, wr_dvsr;
    wire tx_full, rx_empty;
    wire [7:0] r_data;
    reg [10:0] dvsr_reg;

    // Instantiate UART module
    UART #(
        .DBIT(8),
        .SB_TICK(16),
        .FIFO_W(FIFO_DEPTH_BIT)
    ) uart_unit (
        .clk(clk),
        .reset(reset),
        .rd_uart(rd_uart),
        .wr_uart(wr_uart),
        .rx(rx),
        .tx_full(tx_full),
        .rx_empty(rx_empty),
        .tx(tx),
        .r_data(r_data),
        .w_data(wr_data[7:0]),
        .dvsr(dvsr_reg)
    );

    // DVSR register logic
    always @(posedge clk or posedge reset) begin
        if (reset)
            dvsr_reg <= 11'd0; 
        else if (wr_dvsr)
            dvsr_reg <= wr_data[10:0];
    end

    // Decoding logic
    // Addr 00: Status (Read only)
    // Addr 01: DVSR (Write only)
    // Addr 10: FIFO Data (Write to TX / Read from RX)
    
    assign wr_dvsr = (write && cs && (addr[1:0] == 2'b01));
    assign wr_uart = (write && cs && (addr[1:0] == 2'b10));
    
    // FIXED: rd_uart must be triggered by a READ pulse at the data address
    assign rd_uart = (read && cs && (addr[1:0] == 2'b10));

    // Slot read interface
    // addr 2'b00 returns status; addr 2'b10 returns data
    assign rd_data = (addr[1:0] == 2'b00) ? 
                      {22'b0, tx_full, rx_empty, 8'b0} : // Status
                      {24'b0, r_data};                  // Data

endmodule
