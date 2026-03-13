// =============================================================================
// i2c_sequencer.sv — I²C Sequencer
// Used by the I²C Slave Driver to arbitrate slave response sequences
// =============================================================================

class i2c_sequencer extends uvm_sequencer #(i2c_xtn);

    `uvm_component_utils(i2c_sequencer)

    extern function new(string name = "i2c_sequencer", uvm_component parent);

endclass : i2c_sequencer

function i2c_sequencer::new(string name = "i2c_sequencer", uvm_component parent);
    super.new(name, parent);
endfunction : new
