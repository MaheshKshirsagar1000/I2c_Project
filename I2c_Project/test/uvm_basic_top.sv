// UVM basic topology setup code

import uvm.*;

class uvm_basic_top extends uvm_component {
    
    `uvm_component_utils(uvm_basic_top)
    
    uvm_basic_top(uvm_component parent, string name) {
        super.parent = parent;
        super.name = name;
    }
    
    function void build_phase(uvm_phase phase);
        `uvm_info(get_name(), "Building UVM basic topology...", UVM_MEDIUM);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        `uvm_info(get_name(), "Connecting UVM basic topology...", UVM_MEDIUM);
    endfunction
    
    function void run_phase(uvm_phase phase);
        `uvm_info(get_name(), "Running UVM basic topology...", UVM_MEDIUM);
    endfunction
}

// Top-level module for simulation
module test;
    uvm_basic_top top;
    initial begin
        uvm_root::set_verbosity_level(UVM_MEDIUM);
        top = uvm_basic_top::type_id::create("top");
        top.build();
        top.connect();
        top.run();
    end
endmodule