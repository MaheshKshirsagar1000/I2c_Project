// =============================================================================
// apb_agent.sv — APB Agent
// Instantiates: apb_driver, apb_sequencer, apb_monitor
// Active mode  → all three components
// Passive mode → monitor only
// =============================================================================

class apb_agent extends uvm_agent;

    `uvm_component_utils(apb_agent)

    apb_agt_config  agt_cfg;
    apb_sequencer   seqrh;
    apb_driver      drvh;
    apb_monitor     monh;

    extern function new(string name = "apb_agent", uvm_component parent);
    extern function void build_phase  (uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);

endclass : apb_agent

// -----------------------------------------------------------------------------
function apb_agent::new(string name = "apb_agent", uvm_component parent);
    super.new(name, parent);
endfunction : new

// -----------------------------------------------------------------------------
function void apb_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(apb_agt_config)::get(this, "", "apb_agt_config", agt_cfg))
        `uvm_fatal("APB_AGENT", "GET of apb_agt_config failed")

    monh = apb_monitor::type_id::create("monh", this);

    if (agt_cfg.is_active == UVM_ACTIVE) begin
        seqrh = apb_sequencer::type_id::create("seqrh", this);
        drvh  = apb_driver::type_id::create("drvh",  this);
    end
endfunction : build_phase

// -----------------------------------------------------------------------------
function void apb_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (agt_cfg.is_active == UVM_ACTIVE)
        drvh.seq_item_port.connect(seqrh.seq_item_export);
endfunction : connect_phase
