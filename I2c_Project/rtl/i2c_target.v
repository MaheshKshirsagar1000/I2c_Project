// =============================================================================
// i2c_target.v — I²C Target (Slave) State Machine (STUB)
// NOTE: This RTL module is NOT instantiated in the TB top for this
//       verification plan. The UVM I2C Agent (i2c_slave_driver.sv) provides
//       a behavioural slave model instead.
//       This stub is provided for completeness and future co-simulation.
// =============================================================================

module i2c_target (
    input  wire        clk,
    input  wire        rst_n,

    // Target configuration
    input  wire [6:0]  own_addr,      // This target's 7-bit address
    input  wire        gen_call_en,   // 1 = respond to General Call (0x00)
    input  wire        stretch_en,    // 1 = clock stretching enabled

    // Data buffers
    input  wire [7:0]  tx_buf,        // Data to transmit (read request)
    output wire [7:0]  rx_buf,        // Received data (write from controller)
    output wire        rx_valid,      // rx_buf has new valid data

    // I²C bus drive (open-drain, wired into top-level SDA/SCL wire)
    input  wire        sda_in,        // Bus SDA value
    output wire        sda_out,       // Target SDA drive value
    output wire        sda_oe,        // Target SDA output enable
    input  wire        scl_in,        // Bus SCL value
    output wire        scl_out,       // Target SCL output (for clock stretch)
    output wire        scl_oe         // Target SCL OE (for clock stretch)
);

    // TODO: RTL target FSM to be provided
    assign rx_buf  = 8'h0;
    assign rx_valid= 1'b0;
    assign sda_out = 1'b1;
    assign sda_oe  = 1'b0;
    assign scl_out = 1'b1;
    assign scl_oe  = 1'b0;

endmodule : i2c_target
