// =============================================================================
// apb_driver.sv — APB Driver
// Translates apb_xtn sequence items into pin-level APB bus stimulus.
// APB Protocol:
//   Phase 1 (SETUP): Assert Psel, set Paddr/Pwrite/Pwdata
//   Phase 2 (ACCESS): Assert Penable, wait for Pready=1
//   Sample Prdata/Pslverr, deassert Psel/Penable
// =============================================================================

class apb_driver extends uvm_driver #(apb_xtn);

    `uvm_component_utils(apb_driver)

    apb_agt_config agt_cfg;
    virtual i2c_if.APB_DRV_MP vif;

    extern function new(string name = "apb_driver", uvm_component parent);
    extern function void build_phase   (uvm_phase phase);
    extern function void connect_phase (uvm_phase phase);
    extern task          run_phase     (uvm_phase phase);
    extern task          reset_apb;
    extern task          drive_apb     (apb_xtn xtn);

endclass : apb_driver

// -----------------------------------------------------------------------------
function apb_driver::new(string name = "apb_driver", uvm_component parent);
    super.new(name, parent);
endfunction : new

// -----------------------------------------------------------------------------
function void apb_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(apb_agt_config)::get(this, "", "apb_agt_config", agt_cfg))
        `uvm_fatal("APB_DRIVER", "GET of apb_agt_config failed")
endfunction : build_phase

// -----------------------------------------------------------------------------
function void apb_driver::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vif = agt_cfg.vif;
endfunction : connect_phase

// -----------------------------------------------------------------------------
task apb_driver::run_phase(uvm_phase phase);
    reset_apb();
    forever begin
        seq_item_port.get_next_item(req);
        drive_apb(req);
        seq_item_port.item_done();
    end
endtask : run_phase

// -----------------------------------------------------------------------------
// Deassert all APB outputs during / after reset
task apb_driver::reset_apb;
    @(vif.apb_drv_cb);
    vif.apb_drv_cb.Psel    <= 1'b0;
    vif.apb_drv_cb.Penable <= 1'b0;
    vif.apb_drv_cb.Pwrite  <= 1'b0;
    vif.apb_drv_cb.Paddr   <= 32'h0;
    vif.apb_drv_cb.Pwdata  <= 32'h0;
    // Wait for reset de-assertion
    @(posedge vif.rst_n);
    @(vif.apb_drv_cb);
endtask : reset_apb

// -----------------------------------------------------------------------------
// Drive a single APB transaction (two-phase: SETUP → ACCESS)
task apb_driver::drive_apb(apb_xtn xtn);
    `uvm_info("APB_DRIVER", $sformatf("\n%s", xtn.convert2string()), UVM_MEDIUM)

    // ---- SETUP phase ----
    vif.apb_drv_cb.Psel   <= 1'b1;
    vif.apb_drv_cb.Pwrite <= xtn.Pwrite;
    vif.apb_drv_cb.Paddr  <= xtn.Paddr;
    vif.apb_drv_cb.Pwdata <= xtn.Pwdata;
    @(vif.apb_drv_cb);

    // ---- ACCESS phase ----
    vif.apb_drv_cb.Penable <= 1'b1;

    // Wait for DUT to assert Pready (slave ready)
    while (vif.apb_drv_cb.Pready !== 1'b1) @(vif.apb_drv_cb);

    // Capture read data / error on completion
    if (xtn.Pwrite == 1'b0) begin
        xtn.Prdata  = vif.apb_drv_cb.Prdata;
        xtn.Pslverr = vif.apb_drv_cb.Pslverr;
        // Return response so sequence can read Prdata
        seq_item_port.put_response(xtn);
    end else begin
        xtn.Pslverr = vif.apb_drv_cb.Pslverr;
    end

    // ---- Idle phase ----
    vif.apb_drv_cb.Psel    <= 1'b0;
    vif.apb_drv_cb.Penable <= 1'b0;
    vif.apb_drv_cb.Pwrite  <= 1'b0;
    @(vif.apb_drv_cb);
endtask : drive_apb
