// =============================================================================
// i2c_env.sv — I²C UVM Environment
//
// Instantiates:
//   - i2c_agt_top (APB agent + I²C agent)
//   - v_sequencer (virtual sequencer — coordinates APB + I²C sequences)
//   - i2c_sb      (scoreboard + 16 functional covergroups)
//   - proto_mon   (protocol monitor — precise timing, SDA/SCL waveform decode)
//
// Analysis connections:
//   APB monitor   → scoreboard (apb TLM FIFO port)
//   I²C monitor   → scoreboard (i2c TLM FIFO port)
//   I²C monitor   → protocol monitor (i2c TLM FIFO port)
// =============================================================================

class i2c_env extends uvm_env;

    `uvm_component_utils(i2c_env)

    i2c_env_config  env_cfg;

    v_sequencer     vseqrh;
    i2c_agt_top     agt_toph;
    i2c_sb          sbh;
    proto_mon       proto_monh;

    extern function new(string name = "i2c_env", uvm_component parent);
    extern function void build_phase  (uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);

endclass : i2c_env

// -----------------------------------------------------------------------------
function i2c_env::new(string name = "i2c_env", uvm_component parent);
    super.new(name, parent);
endfunction : new

// -----------------------------------------------------------------------------
function void i2c_env::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(i2c_env_config)::get(this, "", "i2c_env_config", env_cfg))
        `uvm_fatal("I2C_ENV", "GET of i2c_env_config failed")

    // Pass env_cfg down to agent top
    uvm_config_db #(i2c_env_config)::set(
        this, "agt_toph", "i2c_env_config", env_cfg);

    // Create sub-components
    if (env_cfg.has_v_sequencer)
        vseqrh = v_sequencer::type_id::create("vseqrh", this);

    if (env_cfg.has_apb_agent || env_cfg.has_i2c_agent)
        agt_toph = i2c_agt_top::type_id::create("agt_toph", this);

    if (env_cfg.has_sb)
        sbh = i2c_sb::type_id::create("sbh", this);

    if (env_cfg.has_proto_mon)
        proto_monh = proto_mon::type_id::create("proto_monh", this);

endfunction : build_phase

// -----------------------------------------------------------------------------
function void i2c_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // -----------------------------------------------------------------
    // Virtual sequencer → sub-sequencer handles
    // -----------------------------------------------------------------
    if (env_cfg.has_v_sequencer && env_cfg.has_apb_agent)
        vseqrh.apb_seqrh = agt_toph.apb_agth.seqrh;

    if (env_cfg.has_v_sequencer && env_cfg.has_i2c_agent)
        vseqrh.i2c_seqrh = agt_toph.i2c_agth.seqrh;

    // -----------------------------------------------------------------
    // Analysis connections to scoreboard
    // -----------------------------------------------------------------
    if (env_cfg.has_sb && env_cfg.has_apb_agent)
        agt_toph.apb_agth.monh.apb_analysis_port.connect(
            sbh.apb_tlm_port.analysis_export);

    if (env_cfg.has_sb && env_cfg.has_i2c_agent)
        agt_toph.i2c_agth.monh.i2c_analysis_port.connect(
            sbh.i2c_tlm_port.analysis_export);

    // -----------------------------------------------------------------
    // Analysis connections to protocol monitor
    // -----------------------------------------------------------------
    if (env_cfg.has_proto_mon && env_cfg.has_i2c_agent)
        agt_toph.i2c_agth.monh.i2c_analysis_port.connect(
            proto_monh.i2c_tlm_port.analysis_export);

endfunction : connect_phase
