// =============================================================================
// i2c_if.sv — I²C Verification Interface
//
// Contains two logical sections:
//   1. APB section  — synchronous (pclk), uses clocking blocks for driver/monitor
//   2. I²C bus section — asynchronous SDA/SCL open-drain wired-AND model
//
// Open-Drain Model:
//   SDA and SCL are declared as 'wire' (multi-driver resolved type).
//   Any driver wanting to assert (pull LOW) sets its drive signal to 0.
//   Any driver releasing the bus sets its tri-state output to 1'bz.
//   Pull-up resistors are instantiated in i2c_tb_top.sv:
//     pullup(i2c_if_inst.sda);
//     pullup(i2c_if_inst.scl);
//   The slave driver's open-drain model is implemented via continuous assign
//   inside this interface (sda_slv_drv / scl_slv_drv → sda / scl).
//   The DUT's tri-state outputs are connected in i2c_tb_top.sv.
//
// Modports:
//   APB_DRV_MP  — used by apb_driver.sv  (clocking block + reset)
//   APB_MON_MP  — used by apb_monitor.sv (clocking block + reset)
//   I2C_MON_MP  — used by i2c_monitor.sv (direct wire access, asynchronous)
//   I2C_SLV_MP  — used by i2c_slave_driver.sv (drives sda_slv_drv/scl_slv_drv)
// =============================================================================

interface i2c_if (
    input logic pclk,     // 50 MHz system/APB clock
    input logic rst_n     // Active-low synchronous reset
);

    // =========================================================================
    // APB Interface Signals
    // =========================================================================
    logic        Psel;        // Peripheral select
    logic        Penable;     // Enable phase strobe
    logic        Pwrite;      // 1=write, 0=read
    logic [31:0] Paddr;       // Register address (word-aligned)
    logic [31:0] Pwdata;      // Write data
    logic [31:0] Prdata;      // Read data (from DUT)
    logic        Pready;      // Transfer ready (from DUT)
    logic        Pslverr;     // Slave error (from DUT)

    // =========================================================================
    // I²C Bus Signals — Open-drain / Wired-AND topology
    // 'wire' type: supports multiple concurrent tri-state drivers
    // =========================================================================
    wire sda;    // Serial Data Line (bidirectional, open-drain)
    wire scl;    // Serial Clock Line (bidirectional, open-drain)

    // -------------------------------------------------------------------------
    // Slave-side drive control
    //   sda_slv_drv = 1 → release SDA (drive 1'bz → pulled HIGH by pullup)
    //   sda_slv_drv = 0 → assert SDA LOW (open-drain dominant 0)
    //   scl_slv_drv = 0 → hold SCL LOW (clock stretching)
    // -------------------------------------------------------------------------
    logic sda_slv_drv;   // Slave SDA drive control
    logic scl_slv_drv;   // Slave SCL drive control (clock stretch)

    // Tri-state continuous assign — implements slave open-drain drivers
    assign sda = sda_slv_drv ? 1'bz : 1'b0;
    assign scl = scl_slv_drv ? 1'bz : 1'b0;

    // =========================================================================
    // DUT Observable Outputs
    // Driven by DUT, read by monitor, scoreboard, and SVA module
    // =========================================================================
    logic        busy;            // Bus BUSY (set by START, cleared by STOP)
    logic        bus_free;        // Bus FREE (t_BUF elapsed after STOP)
    logic        nack_det;        // NACK was detected on address/data byte
    logic        start_cond;      // START or repeated START (Sr) on bus
    logic        stop_cond;       // STOP condition on bus
    logic        arb_lost;        // Arbitration loss detected
    logic        recovery_active; // Bus hang recovery sequence in progress
    logic [3:0]  recovery_cnt;    // Number of SCL pulses issued during recovery
    logic        IRQ;             // Interrupt output

    // -------------------------------------------------------------------------
    // Internal data-path observables (wired out for SVA / ASS-05, ASS-10, etc.)
    // -------------------------------------------------------------------------
    logic [3:0]  bit_cnt;         // Bit position 0(MSB)..7(LSB)..8(ACK/NACK)
    logic        sda_out;         // DUT's intended SDA value (before tri-state)
    logic        sda_oe;          // DUT SDA output enable (1=driving bus)
    logic        scl_out;         // DUT SCL drive value
    logic        tx_ack_phase;    // HIGH when DUT in transmit ACK release window
    logic        addr_ack_phase;  // HIGH during address-phase ACK window
    logic        addr_match;      // Received address matches programmed address
    logic [7:0]  tx_data;         // Programmed TX data byte (for ASS-05 MSB check)
    logic        ctrl_active;     // Controller is the active bus master
    logic        scl_period_ok;   // SCL period within spec (for ASS-14)

    // =========================================================================
    // APB Clocking Block — Driver
    // apb_driver.sv synchronises all APB output drives to posedge pclk
    // =========================================================================
    clocking apb_drv_cb @(posedge pclk);
        default input #1 output #1;
        output Psel, Penable, Pwrite, Paddr, Pwdata;
        input  Prdata, Pready, Pslverr;
    endclocking

    // =========================================================================
    // APB Clocking Block — Monitor
    // apb_monitor.sv samples all APB signals on posedge pclk
    // =========================================================================
    clocking apb_mon_cb @(posedge pclk);
        default input #1;
        input Psel, Penable, Pwrite, Paddr, Pwdata;
        input Prdata, Pready, Pslverr;
        input busy, bus_free, nack_det, start_cond, stop_cond, IRQ;
    endclocking

    // =========================================================================
    // Modports
    // =========================================================================

    // APB Driver modport — synchronous to pclk via clocking block
    modport APB_DRV_MP (
        clocking apb_drv_cb,
        input    pclk, rst_n
    );

    // APB Monitor modport — synchronous to pclk via clocking block
    modport APB_MON_MP (
        clocking apb_mon_cb,
        input    pclk, rst_n
    );

    // I²C Monitor modport — direct wire access (asynchronous event detection)
    // Monitor watches for SDA/SCL transitions independently of pclk
    modport I2C_MON_MP (
        input  sda, scl,
        input  busy, bus_free, nack_det, start_cond, stop_cond,
        input  arb_lost, recovery_active, recovery_cnt, IRQ,
        input  bit_cnt, sda_out, sda_oe, scl_out,
        input  tx_ack_phase, addr_ack_phase, addr_match, tx_data,
        input  ctrl_active, scl_period_ok,
        input  pclk, rst_n
    );

    // I²C Slave Driver modport — reads SDA/SCL, drives via sda_slv_drv/scl_slv_drv
    modport I2C_SLV_MP (
        input  sda, scl,
        input  pclk, rst_n,
        output sda_slv_drv, scl_slv_drv
    );

endinterface : i2c_if
