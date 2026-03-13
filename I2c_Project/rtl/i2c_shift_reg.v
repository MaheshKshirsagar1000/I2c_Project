// =============================================================================
// i2c_shift_reg.v — 8-bit TX/RX Shift Register, MSB-first (STUB)
// NOTE: RTL to be provided.
// =============================================================================

module i2c_shift_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        load,           // Parallel load tx_data into SR
    input  wire        shift,          // Shift on each SCL clock (MSB first)
    input  wire [7:0]  din,            // Parallel data in (TX path)
    input  wire        sda_in,         // Serial data in (RX path, via SDA)

    output wire [7:0]  dout,           // Parallel data out (RX captured byte)
    output wire        sda_bit,        // Current TX bit to SDA
    output wire [3:0]  bit_cnt         // Current bit position (0=MSB → 7=LSB → 8=ACK)
);

    // TODO: RTL implementation
    assign dout    = 8'h0;
    assign sda_bit = 1'b1;
    assign bit_cnt = 4'h0;

endmodule : i2c_shift_reg
