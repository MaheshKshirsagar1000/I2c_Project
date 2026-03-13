// =============================================================================
// v_sequencer.sv — I²C Virtual Sequencer
// Holds handles to both apb_sequencer and i2c_sequencer.
// Virtual sequences use these handles to start sub-sequences concurrently.
// =============================================================================

class v_sequencer extends uvm_sequencer #(uvm_sequence_item);

    `uvm_component_utils(v_sequencer)

    // Sub-sequencer handles (connected in i2c_env.sv connect_phase)
    apb_sequencer apb_seqrh;  // APB agent sequencer
    i2c_sequencer i2c_seqrh;  // I²C agent sequencer

    extern function new(string name = "v_sequencer", uvm_component parent);

endclass : v_sequencer

function v_sequencer::new(string name = "v_sequencer", uvm_component parent);
    super.new(name, parent);
endfunction : new
