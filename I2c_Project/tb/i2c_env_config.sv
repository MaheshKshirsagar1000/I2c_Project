// =============================================================================
// i2c_env_config.sv — I²C Environment Configuration Object
// Created in the test layer, distributed via uvm_config_db to env and agents.
// =============================================================================

class i2c_env_config extends uvm_object;

    `uvm_object_utils(i2c_env_config)

    // -------------------------------------------------------------------------
    // Environment enable flags
    // -------------------------------------------------------------------------
    bit has_v_sequencer  = 1;
    bit has_apb_agent    = 1;
    bit has_i2c_agent    = 1;
    bit has_sb           = 1;
    bit has_proto_mon    = 1;

    // -------------------------------------------------------------------------
    // Agent configuration handles
    // -------------------------------------------------------------------------
    apb_agt_config  apb_cfg;    // APB agent config (vif + active/passive)
    i2c_agt_config  i2c_cfg;    // I²C agent config (vif + slave params)

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    extern function new(string name = "i2c_env_config");

endclass : i2c_env_config

function i2c_env_config::new(string name = "i2c_env_config");
    super.new(name);
endfunction : new
