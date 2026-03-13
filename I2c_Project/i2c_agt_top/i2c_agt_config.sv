// =============================================================================
// i2c_agt_config.sv — I²C Agent Configuration Object
// Holds virtual interface handle and slave device parameters.
// Created in test layer, passed via uvm_config_db.
// =============================================================================

class i2c_agt_config extends uvm_object;

    `uvm_object_utils(i2c_agt_config)

    // Virtual interface handle (I2C_SLV_MP / I2C_MON_MP modport)
    virtual i2c_if vif;

    // Active = slave_driver + sequencer + monitor; Passive = monitor only
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    // -------------------------------------------------------------------------
    // Slave Device Parameters
    // -------------------------------------------------------------------------
    logic [6:0] own_addr     = 7'h2A;   // Target's I²C address (default 0x2A)
    bit         gen_call_en  = 1'b0;    // 1 = respond to General Call (0x00)
    bit         stretch_en   = 1'b1;    // 1 = clock stretching allowed
    int         stretch_cycles = 0;     // Default stretch duration (0 = none)

    // -------------------------------------------------------------------------
    // Read data buffer (slave drives this on read requests)
    // -------------------------------------------------------------------------
    logic [7:0] rx_buf_data = 8'hC3;   // Default data slave returns on reads

    extern function new(string name = "i2c_agt_config");

endclass : i2c_agt_config

function i2c_agt_config::new(string name = "i2c_agt_config");
    super.new(name);
endfunction : new
