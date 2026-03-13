// =============================================================================
// i2c_agent.sv — I²C Agent
// Instantiates: i2c_slave_driver, i2c_sequencer, i2c_monitor
// =============================================================================

class i2c_agent extends uvm_agent;

    `uvm_component_utils(i2c_agent)

    i2c_agt_config  agt_cfg;
    i2c_sequencer   seqrh;
    i2c_slave_driver drvh;
    i2c_monitor     monh;

    extern function new(string name = "i2c_agent", uvm_component parent);
    extern function void build_phase  (uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);

endclass : i2c_agent

// -----------------------------------------------------------------------------
function i2c_agent::new(string name = "i2c_agent", uvm_component parent);
    super.new(name, parent);
endfunction : new

// -----------------------------------------------------------------------------
function void i2c_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(i2c_agt_config)::get(this, "", "i2c_agt_config", agt_cfg))
        `uvm_fatal("I2C_AGENT", "GET of i2c_agt_config failed")

    monh = i2c_monitor::type_id::create("monh", this);

    if (agt_cfg.is_active == UVM_ACTIVE) begin
        seqrh = i2c_sequencer::type_id::create("seqrh", this);
        drvh  = i2c_slave_driver::type_id::create("drvh",  this);
    end
endfunction : build_phase

// -----------------------------------------------------------------------------
function void i2c_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (agt_cfg.is_active == UVM_ACTIVE)
        drvh.seq_item_port.connect(seqrh.seq_item_export);
endfunction : connect_phase
