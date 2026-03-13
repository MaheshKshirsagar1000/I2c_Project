// =============================================================================
// i2c_agt_top.sv — I²C Agent Top
// Contains: apb_agent (APB controller interface) + i2c_agent (I²C bus)
// Receives uart_env_config, distributes per-agent configs via uvm_config_db
// =============================================================================

class i2c_agt_top extends uvm_component;

    `uvm_component_utils(i2c_agt_top)

    i2c_env_config  env_cfg;

    apb_agent       apb_agth;   // APB agent — configures I²C controller
    i2c_agent       i2c_agth;   // I²C agent — slave driver + bus monitor

    extern function new(string name = "i2c_agt_top", uvm_component parent);
    extern function void build_phase(uvm_phase phase);

endclass : i2c_agt_top

// -----------------------------------------------------------------------------
function i2c_agt_top::new(string name = "i2c_agt_top", uvm_component parent);
    super.new(name, parent);
endfunction : new

// -----------------------------------------------------------------------------
function void i2c_agt_top::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(i2c_env_config)::get(this, "", "i2c_env_config", env_cfg))
        `uvm_fatal("I2C_AGT_TOP", "GET of i2c_env_config failed")

    // ---------------------------------------------------------
    // Distribute APB agent configuration
    // ---------------------------------------------------------
    if (env_cfg.has_apb_agent) begin
        uvm_config_db #(apb_agt_config)::set(
            this, "apb_agth*", "apb_agt_config", env_cfg.apb_cfg);
        apb_agth = apb_agent::type_id::create("apb_agth", this);
    end

    // ---------------------------------------------------------
    // Distribute I²C agent configuration
    // ---------------------------------------------------------
    if (env_cfg.has_i2c_agent) begin
        uvm_config_db #(i2c_agt_config)::set(
            this, "i2c_agth*", "i2c_agt_config", env_cfg.i2c_cfg);
        i2c_agth = i2c_agent::type_id::create("i2c_agth", this);
    end

endfunction : build_phase
