// =============================================================================
// i2c_xtn.sv — I²C Decoded Transaction Class
// Represents one complete I²C transfer decoded from SDA/SCL bus activity.
// Populated by: i2c_monitor (from SDA/SCL waveform decoding)
// Consumed by : scoreboard, protocol monitor, coverage collector
//
// Enums:
//   nack_cause_e — maps to VPlan COV-05 (FR-ERR-006a–e)
//   bus_state_e  — maps to VPlan COV-01
// =============================================================================

// ---------------------------------------------------------------------------
// NACK Cause Enumeration (VPlan COV-05, FR-ERR-006a–e)
// ---------------------------------------------------------------------------
typedef enum logic [2:0] {
    NACK_NONE        = 3'd0,   // No NACK (ACK received)
    NACK_NO_DEVICE   = 3'd1,   // FR-ERR-006a: No device at address
    NACK_TARGET_BUSY = 3'd2,   // FR-ERR-006b: Target busy (stretch + NACK)
    NACK_BAD_CMD     = 3'd3,   // FR-ERR-006c: Unrecognised command byte
    NACK_OVERFLOW    = 3'd4,   // FR-ERR-006d: Target buffer overflow
    NACK_LAST_BYTE   = 3'd5    // FR-ERR-006e: Controller NACK on last read byte
} nack_cause_e;

// ---------------------------------------------------------------------------
// Bus State Enumeration (VPlan COV-01)
// ---------------------------------------------------------------------------
typedef enum logic [1:0] {
    BUS_IDLE  = 2'd0,          // Before first transaction
    BUS_BUSY  = 2'd1,          // Between START and STOP
    BUS_FREE  = 2'd2           // t_BUF elapsed after STOP
} bus_state_e;

// ---------------------------------------------------------------------------
// Transaction class
// ---------------------------------------------------------------------------
class i2c_xtn extends uvm_sequence_item;

    `uvm_object_utils(i2c_xtn)

    // =========================================================================
    // Stimulus / Randomisable fields (used by i2c_sequence for slave config)
    // =========================================================================
    rand logic [6:0]  addr;           // 7-bit target address (MSB in bit[6])
    rand logic        rw;             // 0 = write (ctrl→target), 1 = read (target→ctrl)
    rand logic [7:0]  tx_data[];      // Data bytes to send (write path, dynamic array)
    rand int          byte_cnt;       // Number of data bytes in this transfer
    rand logic        gen_call;       // 1 = General Call (addr 0x00) transaction
    rand logic        repeated_start; // 1 = followed by Sr (no STOP)
    rand bit          stretch_en;     // Slave stretch_en configuration
    rand int          stretch_cycles; // How many cycles slave holds SCL LOW

    // =========================================================================
    // Observed / Captured fields (populated by i2c_monitor)
    // =========================================================================
    logic [7:0]  rx_data[];      // Data bytes received (read path, captured from bus)
    logic        ack[];          // ACK(0)/NACK(1) per byte: [0]=addr, [1..N]=data bytes
    logic        nack_det;       // 1 = NACK was detected somewhere in this transfer
    nack_cause_e nack_cause;     // Reason for NACK (for COV-05)

    // Condition flags
    logic        start_detected;  // START condition seen at beginning
    logic        stop_detected;   // STOP condition seen at end
    logic        sr_detected;     // Repeated START (Sr) seen within transfer

    // Bus state at time of transaction
    bus_state_e  bus_state_at_start; // COV-01

    // Recovery
    logic        recovery_detected; // Bus hang recovery sequence was triggered
    logic [3:0]  recovery_pulses;   // Number of recovery SCL pulses generated

    // Clock stretch
    logic        stretch_detected;  // Slave held SCL LOW during this transfer
    int          stretch_duration;  // Duration of stretch in clock cycles

    // Timing measurements (real, in ns — measured by protocol monitor)
    real         scl_period_ns;      // Measured SCL period (for COV-10, ASS-14)
    real         t_low_ns;           // Measured SCL LOW  period (for TC-12)
    real         t_high_ns;          // Measured SCL HIGH period (for TC-12)
    real         t_buf_ns;           // Measured bus free time   (for ASS-07)
    real         t_hd_sta_ns;        // Measured START hold time
    real         t_su_dat_ns;        // Measured data setup time

    // Spike injection (for COV-12)
    logic        glitch_sda;         // SDA glitch injected during this transfer
    logic        glitch_scl;         // SCL glitch injected during this transfer
    int          glitch_width_ns;    // Measured or injected glitch width

    // =========================================================================
    // Constraints (for slave sequence generation / directed-test parameters)
    // =========================================================================
    // Valid 7-bit non-reserved address range
    constraint valid_addr_c {
        if (!gen_call) addr inside {[7'h08 : 7'h77]};
        else           addr == 7'h00;
    }

    // Byte count: at least 1, max 255 (FR-PRO-017 max burst)
    constraint byte_cnt_c {
        byte_cnt inside {[1 : 255]};
    }

    // tx_data array size matches byte_cnt
    constraint data_size_c {
        tx_data.size() == byte_cnt;
    }

    // Stretch cycles bounded
    constraint stretch_c {
        stretch_cycles inside {[0 : 500]};
    }

    // =========================================================================
    // Constructor
    // =========================================================================
    extern function new(string name = "i2c_xtn");

    // =========================================================================
    // UVM field methods
    // =========================================================================
    extern function void   do_copy   (uvm_object rhs);
    extern function bit    do_compare(uvm_object rhs, uvm_comparer comparer);
    extern function string convert2string();
    extern function void   do_print  (uvm_printer printer);

endclass : i2c_xtn

// -----------------------------------------------------------------------------
function i2c_xtn::new(string name = "i2c_xtn");
    super.new(name);
    nack_cause        = NACK_NONE;
    bus_state_at_start= BUS_IDLE;
    byte_cnt          = 1;
endfunction : new

// -----------------------------------------------------------------------------
function void i2c_xtn::do_copy(uvm_object rhs);
    i2c_xtn rhs_;
    super.do_copy(rhs);
    if (!$cast(rhs_, rhs)) `uvm_fatal("I2C_XTN", "do_copy cast failed")
    this.addr             = rhs_.addr;
    this.rw               = rhs_.rw;
    this.tx_data          = rhs_.tx_data;
    this.rx_data          = rhs_.rx_data;
    this.ack              = rhs_.ack;
    this.byte_cnt         = rhs_.byte_cnt;
    this.nack_det         = rhs_.nack_det;
    this.nack_cause       = rhs_.nack_cause;
    this.start_detected   = rhs_.start_detected;
    this.stop_detected    = rhs_.stop_detected;
    this.sr_detected      = rhs_.sr_detected;
    this.recovery_detected= rhs_.recovery_detected;
    this.recovery_pulses  = rhs_.recovery_pulses;
    this.stretch_detected = rhs_.stretch_detected;
    this.stretch_duration = rhs_.stretch_duration;
    this.scl_period_ns    = rhs_.scl_period_ns;
    this.t_buf_ns         = rhs_.t_buf_ns;
endfunction : do_copy

// -----------------------------------------------------------------------------
function bit i2c_xtn::do_compare(uvm_object rhs, uvm_comparer comparer);
    i2c_xtn rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (super.do_compare(rhs, comparer)   &&
            (this.addr      === rhs_.addr)     &&
            (this.rw        === rhs_.rw)       &&
            (this.tx_data   ==  rhs_.tx_data)  &&
            (this.nack_det  === rhs_.nack_det));
endfunction : do_compare

// -----------------------------------------------------------------------------
function string i2c_xtn::convert2string();
    string s;
    s = $sformatf(
        "I2C_XTN: addr=7'h%02h rw=%0b byte_cnt=%0d nack=%0b cause=%0s\n",
        addr, rw, byte_cnt, nack_det, nack_cause.name());
    s = {s, $sformatf("  start=%0b stop=%0b sr=%0b stretch=%0b(%0d cyc)\n",
        start_detected, stop_detected, sr_detected,
        stretch_detected, stretch_duration)};
    foreach (tx_data[i])
        s = {s, $sformatf("  tx_data[%0d]=0x%02h ack=%0b\n",
             i, tx_data[i], (ack.size() > i+1) ? ack[i+1] : 1'bx)};
    foreach (rx_data[i])
        s = {s, $sformatf("  rx_data[%0d]=0x%02h\n", i, rx_data[i])};
    return s;
endfunction : convert2string

// -----------------------------------------------------------------------------
function void i2c_xtn::do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field_int("addr",      addr,      7,  UVM_HEX);
    printer.print_field_int("rw",        rw,        1,  UVM_BIN);
    printer.print_field_int("byte_cnt",  byte_cnt,  32, UVM_DEC);
    printer.print_field_int("nack_det",  nack_det,  1,  UVM_BIN);
    printer.print_string   ("nack_cause",nack_cause.name());
endfunction : do_print
