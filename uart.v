`include "brg.v"
`include "rx.v"
`include "tx.v"
`include "fifo.v"

module UART #(
    parameter DBIT = 8,
    parameter SB_TICK = 16,
    parameter FIFO_W = 2
)(
    input clk, reset, rd_uart, wr_uart, rx,
    input [7:0] w_data,
    input [10:0] dvsr,
    output tx_full, rx_empty, tx,
    output [7:0] r_data
);

    // Internal signals
    wire tick, rx_done_tick, tx_done_tick;
    wire tx_empty;
    wire [7:0] tx_fifo_out, rx_data_out;

    // Baud generator
    baud_gen baud_gen_unit (
        .clk(clk), .reset(reset), .dvsr(dvsr), .tick(tick)
    );

    // Receiver
    uart_rx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_rx_unit (
        .clk(clk), .reset(reset), .rx(rx), .s_tick(tick),
        .rx_done_tick(rx_done_tick), .dout(rx_data_out)
    );

    // Transmitter - Ensure the module name here matches your tx.v (uart_tx or uart_tx_logic)
    uart_tx_logic #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_tx_unit (
        .clk(clk), .reset(reset),
        .tx_start(~tx_empty), // Starts when FIFO is not empty
        .s_tick(tick),
        .din(tx_fifo_out),
        .tx_done_tick(tx_done_tick),
        .tx(tx)
    );

    // RX FIFO
    fifo #(.DATA_WIDTH(DBIT), .ADDR_WIDTH(FIFO_W)) fifo_rx_unit (
        .clk(clk), .reset(reset),
        .rd(rd_uart), .wr(rx_done_tick),
        .w_data(rx_data_out), .empty(rx_empty),
        .full(), .r_data(r_data)
    );

    // TX FIFO
    fifo #(.DATA_WIDTH(DBIT), .ADDR_WIDTH(FIFO_W)) fifo_tx_unit (
        .clk(clk), .reset(reset),
        .rd(tx_done_tick), .wr(wr_uart),
        .w_data(w_data), .empty(tx_empty),
        .full(tx_full), .r_data(tx_fifo_out)
    );

endmodule
