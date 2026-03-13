// =============================================================================
// apb_sequence.sv — APB Sequences
//
// Hierarchy:
//   apb_base_seq          — base class, inherits from uvm_sequence #(apb_xtn)
//   apb_write_seq         — single register write
//   apb_read_seq          — single register read
//   apb_cfg_write_seq     — configure I²C controller (write + start_req)
//   apb_cfg_read_seq      — read back I²C controller status
//
// Register Address Map (PLACEHOLDER — update when RTL spec is provided)
// All addresses are 32-bit word-aligned (byte offset × 4).
// TODO: Replace with actual register map from FRS register spec
// =============================================================================

// ---------------------------------------------------------------------------
// Placeholder Register Address Map
// TODO: Update with actual values from RTL design spec
// ---------------------------------------------------------------------------
parameter APB_REG_CTRL      = 32'h00;  // Control: start_req, rw, addr[6:0]
parameter APB_REG_TX_DATA   = 32'h04;  // TX Data: tx_data[7:0]
parameter APB_REG_RX_DATA   = 32'h08;  // RX Data: rx_data[7:0] (read)
parameter APB_REG_STATUS    = 32'h0C;  // Status:  busy, nack_det, bus_free
parameter APB_REG_CFG       = 32'h10;  // Config:  stretch_en, byte_cnt
parameter APB_REG_ADDR      = 32'h14;  // Address: target_addr[6:0], rw
parameter APB_REG_IRQ       = 32'h18;  // IRQ:     interrupt status / clear

// ---------------------------------------------------------------------------
// Control register bit fields (placeholder bit positions)
// ---------------------------------------------------------------------------
parameter CTRL_START_REQ    = 0;       // Bit 0: initiate transaction
parameter CTRL_RESTART_REQ  = 1;       // Bit 1: issue repeated START
parameter CTRL_RW_BIT       = 2;       // Bit 2: 0=write, 1=read

// =============================================================================
// Base APB Sequence
// =============================================================================
class apb_base_seq extends uvm_sequence #(apb_xtn);

    `uvm_object_utils(apb_base_seq)

    extern function new(string name = "apb_base_seq");
    extern task body;

endclass : apb_base_seq

function apb_base_seq::new(string name = "apb_base_seq");
    super.new(name);
endfunction : new

task apb_base_seq::body;
    // Base class body is empty — override in derived classes
endtask : body

// =============================================================================
// Single APB Write Sequence
// =============================================================================
class apb_write_seq extends apb_base_seq;

    `uvm_object_utils(apb_write_seq)

    rand logic [31:0] addr;
    rand logic [31:0] data;

    extern function new(string name = "apb_write_seq");
    extern task body;

endclass : apb_write_seq

function apb_write_seq::new(string name = "apb_write_seq");
    super.new(name);
endfunction : new

task apb_write_seq::body;
    req = apb_xtn::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
        Paddr  == local::addr;
        Pwrite == 1'b1;
        Pwdata == local::data;
    }) else `uvm_fatal("APB_WRITE_SEQ", "Randomisation failed")
    finish_item(req);
endtask : body

// =============================================================================
// Single APB Read Sequence
// =============================================================================
class apb_read_seq extends apb_base_seq;

    `uvm_object_utils(apb_read_seq)

    rand logic [31:0] addr;
    logic [31:0]      rdata;  // captured after read

    extern function new(string name = "apb_read_seq");
    extern task body;

endclass : apb_read_seq

function apb_read_seq::new(string name = "apb_read_seq");
    super.new(name);
endfunction : new

task apb_read_seq::body;
    req = apb_xtn::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
        Paddr  == local::addr;
        Pwrite == 1'b0;
        Pwdata == 32'h0;
    }) else `uvm_fatal("APB_READ_SEQ", "Randomisation failed")
    finish_item(req);
    get_response(req);
    rdata = req.Prdata;
endtask : body

// =============================================================================
// I²C Controller Configuration Sequence
// Writes target address, direction, data, then asserts start_req.
// Used by virtual sequences for every directed test case.
// =============================================================================
class apb_cfg_i2c_seq extends apb_base_seq;

    `uvm_object_utils(apb_cfg_i2c_seq)

    // Parameters set by virtual sequence before calling body
    logic [6:0]  target_addr  = 7'h2A; // Target 7-bit address
    logic        rw           = 1'b0;  // 0=write, 1=read
    logic [7:0]  tx_data      = 8'hAB; // Byte to transmit (write path)
    logic        restart_req  = 1'b0;  // Issue repeated START
    int          byte_cnt_val = 1;     // Number of bytes (written to CFG reg)
    bit          stretch_en   = 1'b1;  // Stretch enable

    extern function new(string name = "apb_cfg_i2c_seq");
    extern task body;

endclass : apb_cfg_i2c_seq

function apb_cfg_i2c_seq::new(string name = "apb_cfg_i2c_seq");
    super.new(name);
endfunction : new

task apb_cfg_i2c_seq::body;
    apb_xtn xtn;

    // Step 1: Write target address + rw to address register
    // TODO: Bit field positions subject to actual register map
    xtn = apb_xtn::type_id::create("xtn");
    start_item(xtn);
    assert(xtn.randomize() with {
        Paddr  == APB_REG_ADDR;
        Pwrite == 1'b1;
        Pwdata == {25'h0, local::target_addr[6:0]};
    }) else `uvm_fatal("APB_CFG","Addr reg randomise failed")
    finish_item(xtn);

    // Step 2: Write TX data register
    xtn = apb_xtn::type_id::create("xtn");
    start_item(xtn);
    assert(xtn.randomize() with {
        Paddr  == APB_REG_TX_DATA;
        Pwrite == 1'b1;
        Pwdata == {24'h0, local::tx_data};
    }) else `uvm_fatal("APB_CFG","TX data randomise failed")
    finish_item(xtn);

    // Step 3: Write config register (byte count, stretch_en)
    xtn = apb_xtn::type_id::create("xtn");
    start_item(xtn);
    assert(xtn.randomize() with {
        Paddr  == APB_REG_CFG;
        Pwrite == 1'b1;
        Pwdata == {23'h0, local::stretch_en, local::byte_cnt_val[7:0]};
    }) else `uvm_fatal("APB_CFG","CFG reg randomise failed")
    finish_item(xtn);

    // Step 4: Assert start_req in control register to trigger transfer
    xtn = apb_xtn::type_id::create("xtn");
    start_item(xtn);
    assert(xtn.randomize() with {
        Paddr  == APB_REG_CTRL;
        Pwrite == 1'b1;
        // start_req[0]=1, restart_req[1]=restart, rw[2]=rw
        Pwdata == {29'h0, local::rw, local::restart_req, 1'b1};
    }) else `uvm_fatal("APB_CFG","CTRL reg randomise failed")
    finish_item(xtn);

endtask : body

// =============================================================================
// APB Status Read Sequence (reads busy/nack_det/bus_free from STATUS reg)
// =============================================================================
class apb_status_read_seq extends apb_base_seq;

    `uvm_object_utils(apb_status_read_seq)

    logic [31:0] status_val;
    logic        busy_obs;
    logic        nack_det_obs;
    logic        bus_free_obs;

    extern function new(string name = "apb_status_read_seq");
    extern task body;

endclass : apb_status_read_seq

function apb_status_read_seq::new(string name = "apb_status_read_seq");
    super.new(name);
endfunction : new

task apb_status_read_seq::body;
    req = apb_xtn::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
        Paddr  == APB_REG_STATUS;
        Pwrite == 1'b0;
        Pwdata == 32'h0;
    }) else `uvm_fatal("APB_STATUS","Randomise failed")
    finish_item(req);
    get_response(req);
    status_val    = req.Prdata;
    // TODO: Decode bit fields once register map is final
    busy_obs      = status_val[0];
    nack_det_obs  = status_val[1];
    bus_free_obs  = status_val[2];
endtask : body
