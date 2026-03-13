// =============================================================================
// i2c_sequence.sv — I²C Slave Sequences
//
// All slave response sequences for the I²C agent.
// Each sequence configures the slave driver's behaviour for one transaction.
//
// Hierarchy:
//   i2c_base_seq       — base class
//   i2c_ack_seq        — normal ACK (write or read with data)
//   i2c_nack_addr_seq  — NACK on address (no device at address)
//   i2c_nack_data_seq  — NACK on data byte N (overflow / bad cmd)
//   i2c_nack_busy_seq  — NACK all bytes (target busy)
//   i2c_stretch_seq    — ACK + clock stretch for N cycles
//   i2c_gen_call_seq   — respond to General Call (0x00)
//   i2c_recovery_seq   — holds SDA LOW to trigger recovery sequence
//   i2c_nack_none_seq  — end-of-read NACK (controller-side, slave just ACKs)
// =============================================================================

// =============================================================================
// Base I²C Slave Sequence
// =============================================================================
class i2c_base_seq extends uvm_sequence #(i2c_xtn);

    `uvm_object_utils(i2c_base_seq)

    extern function new(string name = "i2c_base_seq");
    extern task body;

endclass : i2c_base_seq

function i2c_base_seq::new(string name = "i2c_base_seq");
    super.new(name);
endfunction : new

task i2c_base_seq::body;
    // Base body: override in derived classes
endtask : body

// =============================================================================
// Normal ACK Sequence — slave ACKs address and data bytes
// =============================================================================
class i2c_ack_seq extends i2c_base_seq;

    `uvm_object_utils(i2c_ack_seq)

    // Configuration: set before starting
    rand logic [6:0]  slave_addr  = 7'h2A;
    rand logic        rw          = 1'b0;
    rand logic [7:0]  read_data[] ;        // data slave will send (read path)
    rand int          num_bytes   = 1;
    bit               stretch_en  = 1'b0;
    int               stretch_cyc = 0;

    extern function new(string name = "i2c_ack_seq");
    extern task body;

endclass : i2c_ack_seq

function i2c_ack_seq::new(string name = "i2c_ack_seq");
    super.new(name);
    read_data = new[1];
    read_data[0] = 8'hC3;
endfunction : new

task i2c_ack_seq::body;
    req = i2c_xtn::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
        addr        == local::slave_addr;
        rw          == local::rw;
        byte_cnt    == local::num_bytes;
        nack_cause  == NACK_NONE;
        stretch_en  == local::stretch_en;
        stretch_cycles == local::stretch_cyc;
        tx_data.size() == local::num_bytes;
    }) else `uvm_fatal("I2C_ACK_SEQ", "Randomisation failed")
    // Populate read data for read path
    foreach (read_data[i])
        if (i < req.tx_data.size()) req.tx_data[i] = read_data[i];
    finish_item(req);
endtask : body

// =============================================================================
// NACK on Address — no device present (FR-ERR-006a, TC-05, TC-13)
// =============================================================================
class i2c_nack_addr_seq extends i2c_base_seq;

    `uvm_object_utils(i2c_nack_addr_seq)

    rand logic [6:0] slave_addr = 7'h7F;   // Use non-matching address

    extern function new(string name = "i2c_nack_addr_seq");
    extern task body;

endclass : i2c_nack_addr_seq

function i2c_nack_addr_seq::new(string name = "i2c_nack_addr_seq");
    super.new(name);
endfunction : new

task i2c_nack_addr_seq::body;
    req = i2c_xtn::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
        addr       == 7'h7F;   // No device at this address
        rw         == 1'b0;
        byte_cnt   == 1;
        nack_cause == NACK_NO_DEVICE;
    }) else `uvm_fatal("I2C_NACK_ADDR_SEQ", "Randomisation failed")
    finish_item(req);
endtask : body

// =============================================================================
// NACK on Data Byte (overflow or bad command) — FR-ERR-006c/d (TC-21, TC-25)
// =============================================================================
class i2c_nack_data_seq extends i2c_base_seq;

    `uvm_object_utils(i2c_nack_data_seq)

    logic [6:0]  slave_addr  = 7'h2A;
    int          nack_on_byte = 0;   // byte index at which to NACK (0-based)
    nack_cause_e cause        = NACK_OVERFLOW;
    int          num_bytes    = 5;

    extern function new(string name = "i2c_nack_data_seq");
    extern task body;

endclass : i2c_nack_data_seq

function i2c_nack_data_seq::new(string name = "i2c_nack_data_seq");
    super.new(name);
endfunction : new

task i2c_nack_data_seq::body;
    req = i2c_xtn::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
        addr       == local::slave_addr;
        rw         == 1'b0;
        byte_cnt   == local::num_bytes;
        nack_cause == local::cause;
    }) else `uvm_fatal("I2C_NACK_DATA_SEQ", "Randomisation failed")
    finish_item(req);
endtask : body

// =============================================================================
// NACK — Target Busy (FR-ERR-006b, TC-07)
// =============================================================================
class i2c_nack_busy_seq extends i2c_base_seq;

    `uvm_object_utils(i2c_nack_busy_seq)

    logic [6:0] slave_addr  = 7'h2A;
    int         stretch_cyc = 20;   // stretch then NACK

    extern function new(string name = "i2c_nack_busy_seq");
    extern task body;

endclass : i2c_nack_busy_seq

function i2c_nack_busy_seq::new(string name = "i2c_nack_busy_seq");
    super.new(name);
endfunction : new

task i2c_nack_busy_seq::body;
    req = i2c_xtn::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
        addr           == local::slave_addr;
        rw             == 1'b0;
        byte_cnt       == 2;
        nack_cause     == NACK_TARGET_BUSY;
        stretch_en     == 1'b1;
        stretch_cycles == local::stretch_cyc;
    }) else `uvm_fatal("I2C_NACK_BUSY_SEQ", "Randomisation failed")
    finish_item(req);
endtask : body

// =============================================================================
// Clock Stretch Sequence (FR-PRO-019/020, TC-07, TC-20)
// =============================================================================
class i2c_stretch_seq extends i2c_base_seq;

    `uvm_object_utils(i2c_stretch_seq)

    logic [6:0] slave_addr   = 7'h2A;
    logic       rw           = 1'b0;
    int         stretch_cyc  = 20;
    int         num_bytes    = 1;
    bit         stretch_en_val = 1'b1;

    extern function new(string name = "i2c_stretch_seq");
    extern task body;

endclass : i2c_stretch_seq

function i2c_stretch_seq::new(string name = "i2c_stretch_seq");
    super.new(name);
endfunction : new

task i2c_stretch_seq::body;
    req = i2c_xtn::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
        addr           == local::slave_addr;
        rw             == local::rw;
        byte_cnt       == local::num_bytes;
        nack_cause     == NACK_NONE;
        stretch_en     == local::stretch_en_val;
        stretch_cycles == local::stretch_cyc;
    }) else `uvm_fatal("I2C_STRETCH_SEQ", "Randomisation failed")
    finish_item(req);
endtask : body

// =============================================================================
// General Call Response Sequence (FR-ADR-009, TC-10)
// =============================================================================
class i2c_gen_call_seq extends i2c_base_seq;

    `uvm_object_utils(i2c_gen_call_seq)

    logic [7:0] cmd_byte = 8'h04;   // General Call command

    extern function new(string name = "i2c_gen_call_seq");
    extern task body;

endclass : i2c_gen_call_seq

function i2c_gen_call_seq::new(string name = "i2c_gen_call_seq");
    super.new(name);
endfunction : new

task i2c_gen_call_seq::body;
    req = i2c_xtn::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
        addr           == 7'h00;   // General Call address
        gen_call       == 1'b1;
        rw             == 1'b0;
        byte_cnt       == 1;
        nack_cause     == NACK_NONE;
        tx_data[0]     == local::cmd_byte;
    }) else `uvm_fatal("I2C_GEN_CALL_SEQ", "Randomisation failed")
    finish_item(req);
endtask : body

// =============================================================================
// Bus Recovery Sequence — holds SDA LOW to simulate bus hang (TC-09)
// =============================================================================
class i2c_recovery_seq extends i2c_base_seq;

    `uvm_object_utils(i2c_recovery_seq)

    extern function new(string name = "i2c_recovery_seq");
    extern task body;

endclass : i2c_recovery_seq

function i2c_recovery_seq::new(string name = "i2c_recovery_seq");
    super.new(name);
endfunction : new

task i2c_recovery_seq::body;
    // Signal to slave driver: hold SDA LOW to simulate mid-byte abort
    req = i2c_xtn::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
        addr       == 7'h2A;
        rw         == 1'b0;
        byte_cnt   == 1;
        nack_cause == NACK_NO_DEVICE;  // Used to indicate recovery scenario
    }) else `uvm_fatal("I2C_RECOVERY_SEQ", "Randomisation failed")
    finish_item(req);
endtask : body
