// =============================================================================
// apb_agt_config.sv — APB Agent Configuration Object
// Holds virtual interface handle and agent active/passive mode.
// Created in test layer, passed via uvm_config_db.
// =============================================================================

class apb_agt_config extends uvm_object;

    `uvm_object_utils(apb_agt_config)

    // Virtual interface handle (APB_DRV_MP / APB_MON_MP modport)
    virtual i2c_if vif;

    // Active = driver + sequencer + monitor; Passive = monitor only
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    extern function new(string name = "apb_agt_config");

endclass : apb_agt_config

function apb_agt_config::new(string name = "apb_agt_config");
    super.new(name);
endfunction : new
