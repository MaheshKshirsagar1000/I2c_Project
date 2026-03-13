// =============================================================================
// apb_monitor.sv — APB Monitor
// Passively observes APB bus activity.
// Captures complete transactions on ACCESS phase completion (Pready=1).
// Sends captured apb_xtn to scoreboard via analysis port.
// =============================================================================

class apb_monitor extends uvm_monitor;

    `uvm_component_utils(apb_monitor)

    apb_agt_config agt_cfg;
    virtual i2c_if.APB_MON_MP vif;

    // Analysis port to scoreboard
    uvm_analysis_port #(apb_xtn) apb_analysis_port;

    extern function new(string name = "apb_monitor", uvm_component parent);
    extern function void build_phase  (uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task          run_phase    (uvm_phase phase);
    extern task          capture_xtn  (apb_xtn xtn);

endclass : apb_monitor

// -----------------------------------------------------------------------------
function apb_monitor::new(string name = "apb_monitor", uvm_component parent);
    super.new(name, parent);
endfunction : new

// -----------------------------------------------------------------------------
function void apb_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(apb_agt_config)::get(this, "", "apb_agt_config", agt_cfg))
        `uvm_fatal("APB_MON", "GET of apb_agt_config failed")
    apb_analysis_port = new("apb_analysis_port", this);
endfunction : build_phase

// -----------------------------------------------------------------------------
function void apb_monitor::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vif = agt_cfg.vif;
endfunction : connect_phase

// -----------------------------------------------------------------------------
task apb_monitor::run_phase(uvm_phase phase);
    apb_xtn xtn;
    @(posedge vif.rst_n); // Wait for reset release
    forever begin
        xtn = apb_xtn::type_id::create("xtn");
        capture_xtn(xtn);
        `uvm_info("APB_MON", $sformatf("\n%s", xtn.convert2string()), UVM_HIGH)
        apb_analysis_port.write(xtn);
    end
endtask : run_phase

// -----------------------------------------------------------------------------
// Capture one complete APB transaction
task apb_monitor::capture_xtn(apb_xtn xtn);
    // Wait for SETUP phase: Psel=1, Penable=0
    @(vif.apb_mon_cb iff (vif.apb_mon_cb.Psel === 1'b1 &&
                           vif.apb_mon_cb.Penable === 1'b0));
    xtn.Paddr  = vif.apb_mon_cb.Paddr;
    xtn.Pwrite = vif.apb_mon_cb.Pwrite;
    xtn.Pwdata = vif.apb_mon_cb.Pwdata;

    // Wait for ACCESS phase completion: Psel=1, Penable=1, Pready=1
    @(vif.apb_mon_cb iff (vif.apb_mon_cb.Psel    === 1'b1 &&
                           vif.apb_mon_cb.Penable === 1'b1 &&
                           vif.apb_mon_cb.Pready  === 1'b1));
    xtn.Prdata  = vif.apb_mon_cb.Prdata;
    xtn.Pslverr = vif.apb_mon_cb.Pslverr;
endtask : capture_xtn
