// =============================================================================
// i2c_pkg.sv — I²C UVM Testbench Package
//
// Compile order (all files `include'd in dependency order):
//   1. Config objects
//   2. Transaction (sequence item) classes
//   3. APB agent components
//   4. I²C agent components
//   5. Agent top
//   6. TB layer: v_sequencer, virtual sequences
//   7. TB layer: protocol monitor, scoreboard, environment
//   8. Test layer: base test + all TC tests
// =============================================================================

package i2c_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // =========================================================================
    // 1. Configuration Objects
    // =========================================================================
    `include "../i2c_agt_top/apb_agt_config.sv"
    `include "../i2c_agt_top/i2c_agt_config.sv"
    `include "../tb/i2c_env_config.sv"

    // =========================================================================
    // 2. Transaction Classes
    // =========================================================================
    `include "../i2c_agt_top/apb_xtn.sv"
    `include "../i2c_agt_top/i2c_xtn.sv"

    // =========================================================================
    // 3. APB Agent Components
    //    Order: sequencer → sequence → driver → monitor → agent
    // =========================================================================
    `include "../i2c_agt_top/apb_sequencer.sv"
    `include "../i2c_agt_top/apb_sequence.sv"
    `include "../i2c_agt_top/apb_driver.sv"
    `include "../i2c_agt_top/apb_monitor.sv"
    `include "../i2c_agt_top/apb_agent.sv"

    // =========================================================================
    // 4. I²C Agent Components
    //    Order: sequencer → sequences → slave_driver → monitor → agent
    // =========================================================================
    `include "../i2c_agt_top/i2c_sequencer.sv"
    `include "../i2c_agt_top/i2c_sequence.sv"
    `include "../i2c_agt_top/i2c_slave_driver.sv"
    `include "../i2c_agt_top/i2c_monitor.sv"
    `include "../i2c_agt_top/i2c_agent.sv"

    // =========================================================================
    // 5. Agent Top
    // =========================================================================
    `include "../i2c_agt_top/i2c_agt_top.sv"

    // =========================================================================
    // 6. TB Layer — Virtual Sequencer + Virtual Sequences
    // =========================================================================
    `include "../tb/v_sequencer.sv"
    `include "../tb/v_sequence.sv"

    // =========================================================================
    // 7. TB Layer — Protocol Monitor, Scoreboard, Environment
    // =========================================================================
    `include "../tb/proto_mon.sv"
    `include "../tb/i2c_sb.sv"
    `include "../tb/i2c_sva.sv"
    `include "../tb/i2c_env.sv"

    // =========================================================================
    // 8. Test Layer
    // =========================================================================
    `include "i2c_test_lib.sv"
    `include "i2c_tests.sv"

endpackage : i2c_pkg
