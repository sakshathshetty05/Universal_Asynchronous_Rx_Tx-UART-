module uart_tx (
    input  wire clk,         // System clock
    input  wire rst,         // Reset signal (active high)
    input  wire tx_start,    // Signal to start transmission
    input  wire [7:0] data,  // Byte of data to transmit
    output reg tx,           // UART transmit line
    output reg busy          // High while transmitting
);

    // Parameters
    parameter CLK_FREQ = 50000000;   // System clock = 50 MHz
    parameter BAUD_RATE = 9600;      // UART baud rate
    localparam BAUD_TICK = CLK_FREQ / BAUD_RATE; // Clock cycles per baud

    // Internal signals
    reg [12:0] baud_counter;  // Counter for baud timing
    reg baud_tick;            // High when baud_counter reaches limit

    reg [3:0] bit_index;      // Which bit is being transmitted (0-9)
    reg [9:0] shift_reg;      // Start bit + data bits + stop bit

    // Baud rate generator
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            baud_counter <= 0;
            baud_tick <= 0;
        end else if (baud_counter == BAUD_TICK - 1) begin
            baud_counter <= 0;
            baud_tick <= 1;
        end else begin
            baud_counter <= baud_counter + 1;
            baud_tick <= 0;
        end
    end

    // UART transmit state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx <= 1;          // Idle line = HIGH
            busy <= 0;
            bit_index <= 0;
            shift_reg <= 10'b1111111111;
        end else if (tx_start && !busy) begin
            // Load shift register with start + data + stop
            shift_reg <= {1'b1, data, 1'b0}; // [Stop][Data][Start]
            busy <= 1;
            bit_index <= 0;
        end else if (busy && baud_tick) begin
            tx <= shift_reg[0];               // Send LSB first
            shift_reg <= shift_reg >> 1;      // Shift right
            bit_index <= bit_index + 1;

            if (bit_index == 9) begin
                busy <= 0;  // Done after 10 bits
            end
        end
    end

endmodule

`timescale 1ns/1ps   // Simulation time unit = 1ns, precision = 1ps

module tb_uart_tx;

    // Testbench signals
    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] data;
    wire tx;
    wire busy;

    // Parameters (match DUT)
    parameter CLK_FREQ = 50000000;   // 50 MHz clock
    parameter BAUD_RATE = 9600;

    // Instantiate the Device Under Test (DUT)
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .data(data),
        .tx(tx),
        .busy(busy)
    );

    // Generate clock (50 MHz -> 20ns period)
    always #10 clk = ~clk;  // Toggle every 10ns => 50 MHz

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        tx_start = 0;
        data = 8'h00;

        // Apply reset for 100ns
        #100;
        rst = 0;

        // Wait a little before starting transmission
        #100;

        // Test 1: Send character 'A' (0x41 = 01000001)
        data = 8'h65;
        tx_start = 1;
        #20;              // Small pulse
        tx_start = 0;

        // Wait enough time for full transmission (10 bits @ 9600 baud ? 1.04ms)
        #120000;

        // Test 2: Send character 'Z' (0x5A)
        data = 8'h5A;
        tx_start = 1;
        #20;
        tx_start = 0;

        #120000;

        // End simulation
        $stop;
    end

endmodule