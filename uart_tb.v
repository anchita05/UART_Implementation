`timescale 1ns / 1ps

module chu_uart_tb();
    // Parameters
    localparam T = 20; // 50 MHz clock
    localparam FIFO_BIT = 4;
    
    // Signals
    reg clk, reset;
    reg cs, read, write;
    reg [4:0] addr;
    reg [31:0] wr_data;
    wire [31:0] rd_data;
    wire tx;
    reg rx; // Stimulate this for the Receiver

    // Instantiate the Wrapper
    chu_uart #(.FIFO_DEPTH_BIT(FIFO_BIT)) dut (
        .clk(clk), .reset(reset),
        .cs(cs), .read(read), .write(write),
        .addr(addr), .wr_data(wr_data),
        .rd_data(rd_data),
        .tx(tx), .rx(rx)
    );

    // Clock generation
    always begin
        clk = 1'b0; #(T/2);
        clk = 1'b1; #(T/2);
    end

    // Test Procedure
    initial begin
        // --- 1. Initialization ---
        reset = 1'b1;
        cs = 1'b0; read = 1'b0; write = 1'b0;
        addr = 0; wr_data = 0;
        rx = 1'b1; // UART Idle state is HIGH
        #(2*T);
        reset = 1'b0;
        #(2*T);

        // --- 2. Configure Baud Rate (DVSR) ---
        // Let's assume a small DVSR for simulation speed (e.g., 2)
        // Formula: Tick happens every (DVSR + 1) clocks
        write_reg(5'b00001, 32'd2); 

        // --- 3. Transmit Data (Write to TX FIFO) ---
        // Writing 0x41 ('A') to addr 2'b10
        write_reg(5'b00010, 32'h41);
        
        // Wait for transmission to finish (simplified wait)
        #(500*T);

        // --- 4. Receive Data (Loopback Simulation) ---
        // We manually drive the 'rx' line to simulate an incoming byte 0x42 ('B')
        // Start bit (0)
        receive_bit(1'b0); 
        // Data bits (01000010 - LSB first)
        receive_bit(1'b0); receive_bit(1'b1); receive_bit(1'b0); receive_bit(1'b0);
        receive_bit(1'b0); receive_bit(1'b0); receive_bit(1'b1); receive_bit(1'b0);
        // Stop bit (1)
        receive_bit(1'b1);

        #(100*T);

        // --- 5. Read from RX FIFO ---
        // Check status first (addr 0x00)
        read_reg(5'b00000);
        // Read the data (addr 0x10)
        read_reg(5'b00010);

        #(100*T);
        $stop;
    end

    // --- Helper Tasks ---

    task write_reg(input [4:0] a, input [31:0] d);
        begin
            @(negedge clk);
            addr = a;
            wr_data = d;
            cs = 1'b1;
            write = 1'b1;
            #(T);
            write = 1'b0;
            cs = 1'b0;
        end
    endtask

    task read_reg(input [4:0] a);
        begin
            @(negedge clk);
            addr = a;
            cs = 1'b1;
            read = 1'b1;
            #(T);
            read = 1'b0;
            cs = 1'b0;
        end
    endtask

    // Simulates one bit period (DVSR=2, 16x sampling)
    task receive_bit(input bit_val);
        begin
            rx = bit_val;
            // Wait: (DVSR+1) * 16 * T
            #(3 * 16 * T); 
        end
    endtask

endmodule
