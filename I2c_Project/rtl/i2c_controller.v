// =============================================================================
// i2c_controller.v — I²C Master Controller State Machine (STUB)
// Drives SDA/SCL via open-drain outputs (sda_out/sda_oe/scl_out)
// Configured via register interface (connected from i2c_top APB decoder)
// NOTE: RTL implementation to be provided.
// =============================================================================

module i2c_controller (
    input  wire        clk,
    input  wire        rst_n,

    // Register interface (from APB decoder in i2c_top)
    input  wire [6:0]  addr,          // Target address (7-bit)
    input  wire        rw,            // Transaction direction: 0=write, 1=read
    input  wire [7:0]  tx_data,       // Transmit data byte
    output wire [7:0]  rx_data,       // Received data byte
    input  wire        start_req,     // Initiate transaction
    input  wire        restart_req,   // Issue repeated START

    // Status outputs
    output wire        busy,
    output wire        bus_free,
    output wire        nack_det,
    output wire        start_cond,
    output wire        stop_cond,
    output wire        arb_lost,
    output wire        recovery_active,
    output wire [3:0]  recovery_cnt,
    output wire        IRQ,

    // I²C bus drive outputs (open-drain tri-state in i2c_top)
    output wire        sda_out,
    output wire        sda_oe,
    output wire        scl_out,

    // Observable internals
    output wire [3:0]  bit_cnt,
    output wire        tx_ack_phase,
    output wire        addr_ack_phase,
    output wire        addr_match,
    output wire        ctrl_active,

    // Clock generator tick inputs (from i2c_clk_gen)
    input  wire        tick_low,      // SCL LOW phase tick
    input  wire        tick_high,     // SCL HIGH phase tick
    input  wire        tick_start,    // t_HD_STA elapsed
    input  wire        tick_stop,     // t_SU_STO elapsed
    input  wire        tick_buf,      // t_BUF elapsed

    // SDA input from bus (sampled during SCL HIGH)
    input  wire        sda_in
);

    // TODO: RTL FSM implementation (CTRL_IDLE, CTRL_START, CTRL_ADDR,
    //       CTRL_DATA_TX, CTRL_DATA_RX, CTRL_ACK, CTRL_STOP, CTRL_RECOVERY)

    // Placeholder tie-offs
    assign rx_data        = 8'h0;
    assign busy           = 1'b0;
    assign bus_free       = 1'b1;
    assign nack_det       = 1'b0;
    assign start_cond     = 1'b0;
    assign stop_cond      = 1'b0;
    assign arb_lost       = 1'b0;
    assign recovery_active= 1'b0;
    assign recovery_cnt   = 4'h0;
    assign IRQ            = 1'b0;
    assign sda_out        = 1'b1;
    assign sda_oe         = 1'b0;
    assign scl_out        = 1'b1;
    assign bit_cnt        = 4'h0;
    assign tx_ack_phase   = 1'b0;
    assign addr_ack_phase = 1'b0;
    assign addr_match     = 1'b0;
    assign ctrl_active    = 1'b0;

endmodule : i2c_controller
