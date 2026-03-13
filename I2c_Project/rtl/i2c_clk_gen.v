// =============================================================================
// i2c_clk_gen.v — SCL Clock Generator with Stretch Support (STUB)
// Generates timing ticks for the controller FSM.
// CLK_DIV_STD = 250 → 50 MHz / (2×250) = 100 kHz SCL
// NOTE: RTL to be provided.
// =============================================================================

module i2c_clk_gen (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,         // Start SCL generation
    input  wire        stretch_en,     // Allow slave clock stretching
    input  wire        scl_in,         // Bus SCL (to detect stretch / release)

    output wire        scl_out,        // SCL drive to bus
    output wire        scl_oe,         // SCL output enable

    output wire        tick_low,       // T_LOW elapsed
    output wire        tick_high,      // T_HIGH elapsed
    output wire        tick_start,     // T_HD_STA elapsed
    output wire        tick_stop,      // T_SU_STO elapsed
    output wire        tick_buf        // T_BUF elapsed
);

    // TODO: RTL divider/counter implementation
    assign scl_out   = 1'b1;
    assign scl_oe    = 1'b0;
    assign tick_low  = 1'b0;
    assign tick_high = 1'b0;
    assign tick_start= 1'b0;
    assign tick_stop = 1'b0;
    assign tick_buf  = 1'b0;

endmodule : i2c_clk_gen
