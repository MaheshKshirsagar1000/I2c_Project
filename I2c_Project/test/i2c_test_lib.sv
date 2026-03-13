// =============================================================================
// i2c_test_lib.sv — I²C UVM Base Test
//
// i2c_base_test:
//   - Creates all config objects and populates uvm_config_db
//   - Builds i2c_env
//   - Defines run_phase as empty (overridden by each TC test)
//   - Provides helper task apply_reset() for warm-reset tests
// =============================================================================

class i2c_base_test extends uvm_test;

    `uvm_component_utils(i2c_base_test)

    // -------------------------------------------------------------------------
    // Handles
    // -------------------------------------------------------------------------
    i2c_env        env_h;
    i2c_env_config env_cfg_h;
    apb_agt_config apb_cfg_h;
    i2c_agt_config i2c_cfg_h;

    // Virtual interface — obtained from config_db in build_phase
    virtual i2c_if vif;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name = "i2c_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    // -------------------------------------------------------------------------
    // build_phase
    // -------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // ------------------------------------------------------------------
        // 1. Create environment config
        // ------------------------------------------------------------------
        env_cfg_h = i2c_env_config::type_id::create("env_cfg_h");

        // ------------------------------------------------------------------
        // 2. APB agent config
        // ------------------------------------------------------------------
        apb_cfg_h             = apb_agt_config::type_id::create("apb_cfg_h");
        apb_cfg_h.is_active   = UVM_ACTIVE;

        if (!uvm_config_db #(virtual i2c_if)::get(
                this, "", "APB_VIF", apb_cfg_h.vif))
            `uvm_fatal("CFG", "APB VIF not found in config_db")

        // ------------------------------------------------------------------
        // 3. I²C agent config
        // ------------------------------------------------------------------
        i2c_cfg_h             = i2c_agt_config::type_id::create("i2c_cfg_h");
        i2c_cfg_h.is_active   = UVM_ACTIVE;
        i2c_cfg_h.own_addr    = 7'h2A;  // Default target address
        i2c_cfg_h.gen_call_en = 1'b0;
        i2c_cfg_h.stretch_en  = 1'b0;

        if (!uvm_config_db #(virtual i2c_if)::get(
                this, "", "I2C_VIF", i2c_cfg_h.vif))
            `uvm_fatal("CFG", "I2C VIF not found in config_db")

        // Convenience handle for reset helper
        vif = apb_cfg_h.vif;

        // ------------------------------------------------------------------
        // 4. Pack configs into env_config and publish to config_db
        // ------------------------------------------------------------------
        env_cfg_h.apb_cfg_h = apb_cfg_h;
        env_cfg_h.i2c_cfg_h = i2c_cfg_h;

        uvm_config_db #(i2c_env_config)::set(
            this, "env_h*", "ENV_CFG", env_cfg_h);
        uvm_config_db #(apb_agt_config)::set(
            this, "env_h.agt_top_h.apb_agt_h*", "APB_AGT_CFG", apb_cfg_h);
        uvm_config_db #(i2c_agt_config)::set(
            this, "env_h.agt_top_h.i2c_agt_h*", "I2C_AGT_CFG", i2c_cfg_h);

        // ------------------------------------------------------------------
        // 5. Create environment
        // ------------------------------------------------------------------
        env_h = i2c_env::type_id::create("env_h", this);

    endfunction : build_phase

    // -------------------------------------------------------------------------
    // connect_phase — nothing to connect at test level
    // -------------------------------------------------------------------------
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase

    // -------------------------------------------------------------------------
    // run_phase — base does nothing; derived tests override
    // -------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_name(), "Base test run_phase — no stimulus", UVM_MEDIUM)
        #100;
        phase.drop_objection(this);
    endtask : run_phase

    // -------------------------------------------------------------------------
    // Helper: apply_reset — asserts preset_n for N pclk cycles
    // Used by TC-18, TC-19 (cold/warm reset tests)
    // -------------------------------------------------------------------------
    task apply_reset(int unsigned cycles = 10);
        vif.preset_n = 1'b0;
        repeat(cycles) @(posedge vif.pclk);
        vif.preset_n = 1'b1;
        `uvm_info(get_name(),
            $sformatf("Reset released after %0d cycles", cycles), UVM_LOW)
    endtask : apply_reset

    // -------------------------------------------------------------------------
    // report_phase — print UVM summary
    // -------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        uvm_report_server rpt_srv;
        super.report_phase(phase);
        rpt_srv = uvm_report_server::get_server();
        if (rpt_srv.get_severity_count(UVM_FATAL)   == 0 &&
            rpt_srv.get_severity_count(UVM_ERROR)   == 0)
            `uvm_info(get_name(), "*** TEST PASSED ***", UVM_NONE)
        else
            `uvm_error(get_name(), "*** TEST FAILED — see error/fatal log above ***")
    endfunction : report_phase

endclass : i2c_base_test
