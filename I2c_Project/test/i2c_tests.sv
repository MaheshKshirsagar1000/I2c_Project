// =============================================================================
// i2c_tests.sv — I²C UVM Test Classes (TC-01 to TC-26)
//
// Each test:
//   1. Extends i2c_base_test
//   2. Overrides run_phase to create and start the corresponding virtual seq
//   3. Special tests override build_phase for config tweaks
//      (e.g. TC-07 enables stretch_en, TC-10 enables gen_call_en)
//
// TC-16, TC-17: RESERVED — out of scope (multi-controller scenarios)
//
// Run a test:  +UVM_TESTNAME=tc01_basic_write_test
// =============================================================================

// =============================================================================
// TC-01: Basic Single-Byte Write
// =============================================================================
class tc01_basic_write_test extends i2c_base_test;
    `uvm_component_utils(tc01_basic_write_test)
    function new(string name = "tc01_basic_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc01_basic_write_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc01_basic_write_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc01_basic_write_test

// =============================================================================
// TC-02: Basic Single-Byte Read
// =============================================================================
class tc02_basic_read_test extends i2c_base_test;
    `uvm_component_utils(tc02_basic_read_test)
    function new(string name = "tc02_basic_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc02_basic_read_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc02_basic_read_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc02_basic_read_test

// =============================================================================
// TC-03: Multi-Byte Write (10 Bytes)
// =============================================================================
class tc03_multi_byte_write_test extends i2c_base_test;
    `uvm_component_utils(tc03_multi_byte_write_test)
    function new(string name = "tc03_multi_byte_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc03_multi_byte_write_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc03_multi_byte_write_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc03_multi_byte_write_test

// =============================================================================
// TC-04: Multi-Byte Read (5 Bytes)
// =============================================================================
class tc04_multi_byte_read_test extends i2c_base_test;
    `uvm_component_utils(tc04_multi_byte_read_test)
    function new(string name = "tc04_multi_byte_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc04_multi_byte_read_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc04_multi_byte_read_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc04_multi_byte_read_test

// =============================================================================
// TC-05: NACK on Unknown Address
// =============================================================================
class tc05_nack_addr_test extends i2c_base_test;
    `uvm_component_utils(tc05_nack_addr_test)
    function new(string name = "tc05_nack_addr_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc05_nack_addr_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc05_nack_addr_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc05_nack_addr_test

// =============================================================================
// TC-06: Repeated START Write then Read
// =============================================================================
class tc06_repeated_start_test extends i2c_base_test;
    `uvm_component_utils(tc06_repeated_start_test)
    function new(string name = "tc06_repeated_start_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc06_repeated_start_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc06_repeated_start_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc06_repeated_start_test

// =============================================================================
// TC-07: Clock Stretching — stretch_en=1 in config
// =============================================================================
class tc07_clock_stretch_test extends i2c_base_test;
    `uvm_component_utils(tc07_clock_stretch_test)
    function new(string name = "tc07_clock_stretch_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    // Enable clock stretching in i2c_cfg before env is built
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        i2c_cfg_h.stretch_en = 1'b1;
    endfunction
    task run_phase(uvm_phase phase);
        tc07_clock_stretch_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc07_clock_stretch_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc07_clock_stretch_test

// =============================================================================
// TC-08: SDA Spike Rejection During SCL LOW
// Glitch injection: force/release done inside run_phase after vseq starts
// =============================================================================
class tc08_sda_glitch_scl_low_test extends i2c_base_test;
    `uvm_component_utils(tc08_sda_glitch_scl_low_test)
    function new(string name = "tc08_sda_glitch_scl_low_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc08_sda_glitch_scl_low_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc08_sda_glitch_scl_low_v_seq::type_id::create("vseq");
        fork
            vseq.start(env_h.v_seqrh);
            begin
                // Wait for SCL to go LOW then inject a 2 ns SDA glitch
                @(negedge vif.scl);
                #1;
                force vif.sda_slv_drv = 1'b0;  // Glitch LOW
                #2;
                release vif.sda_slv_drv;         // Release back to HiZ
                `uvm_info("TC08", "SDA glitch injected during SCL LOW", UVM_LOW)
            end
        join
        phase.drop_objection(this);
    endtask
endclass : tc08_sda_glitch_scl_low_test

// =============================================================================
// TC-09: Bus Hang Recovery (SDA stuck LOW)
// =============================================================================
class tc09_bus_hang_recovery_test extends i2c_base_test;
    `uvm_component_utils(tc09_bus_hang_recovery_test)
    function new(string name = "tc09_bus_hang_recovery_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc09_bus_hang_recovery_v_seq vseq;
        phase.raise_objection(this);
        // Force SDA stuck LOW to simulate bus hang
        force vif.sda_slv_drv = 1'b0;
        `uvm_info("TC09", "SDA forced LOW — bus hang injected", UVM_LOW)
        @(posedge vif.pclk);
        vseq = tc09_bus_hang_recovery_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        release vif.sda_slv_drv;
        phase.drop_objection(this);
    endtask
endclass : tc09_bus_hang_recovery_test

// =============================================================================
// TC-10: General Call Address — gen_call_en=1 in config
// =============================================================================
class tc10_general_call_test extends i2c_base_test;
    `uvm_component_utils(tc10_general_call_test)
    function new(string name = "tc10_general_call_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        i2c_cfg_h.gen_call_en = 1'b1;  // Enable General Call recognition
    endfunction
    task run_phase(uvm_phase phase);
        tc10_general_call_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc10_general_call_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc10_general_call_test

// =============================================================================
// TC-11: Arbitration Loss Detection (design review + signal force)
// =============================================================================
class tc11_arb_loss_test extends i2c_base_test;
    `uvm_component_utils(tc11_arb_loss_test)
    function new(string name = "tc11_arb_loss_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc11_arb_loss_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc11_arb_loss_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        // TODO: Force arb_lost signal on DUT once RTL port is known
        //   force i2c_tb_top.dut.arb_lost = 1'b1;
        //   @(posedge vif.pclk);
        //   release i2c_tb_top.dut.arb_lost;
        phase.drop_objection(this);
    endtask
endclass : tc11_arb_loss_test

// =============================================================================
// TC-12: SCL Timing Verification (Standard-Mode — proto_mon checks timing)
// =============================================================================
class tc12_scl_timing_test extends i2c_base_test;
    `uvm_component_utils(tc12_scl_timing_test)
    function new(string name = "tc12_scl_timing_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc12_scl_timing_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc12_scl_timing_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc12_scl_timing_test

// =============================================================================
// TC-13: Reserved Address Rejection
// =============================================================================
class tc13_reserved_addr_test extends i2c_base_test;
    `uvm_component_utils(tc13_reserved_addr_test)
    function new(string name = "tc13_reserved_addr_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc13_reserved_addr_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc13_reserved_addr_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc13_reserved_addr_test

// =============================================================================
// TC-14: SDA Data Validity During SCL HIGH
// =============================================================================
class tc14_sda_validity_test extends i2c_base_test;
    `uvm_component_utils(tc14_sda_validity_test)
    function new(string name = "tc14_sda_validity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc14_sda_validity_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc14_sda_validity_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc14_sda_validity_test

// =============================================================================
// TC-15: Idle Bus State Verification (after reset)
// =============================================================================
class tc15_idle_bus_test extends i2c_base_test;
    `uvm_component_utils(tc15_idle_bus_test)
    function new(string name = "tc15_idle_bus_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc15_idle_bus_v_seq vseq;
        phase.raise_objection(this);
        apply_reset(10);
        @(posedge vif.pclk);
        // Check SDA=1 and SCL=1 after reset without any transactions
        if (vif.sda !== 1'b1 || vif.scl !== 1'b1)
            `uvm_error("TC15", "Bus not IDLE after reset (SDA or SCL != 1)")
        else
            `uvm_info("TC15", "Bus IDLE confirmed after reset (SDA=1, SCL=1)", UVM_LOW)
        vseq = tc15_idle_bus_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc15_idle_bus_test

// =============================================================================
// TC-16: RESERVED — Out of Scope
// TC-17: RESERVED — Out of Scope
// (multi-controller arbitration / concurrent Sr — not in VPlan v2.0 scope)
// =============================================================================

// =============================================================================
// TC-18: Power-On / Cold Reset Bus Idle
// =============================================================================
class tc18_cold_reset_test extends i2c_base_test;
    `uvm_component_utils(tc18_cold_reset_test)
    function new(string name = "tc18_cold_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc18_cold_reset_v_seq vseq;
        phase.raise_objection(this);
        apply_reset(20);  // Simulate cold reset (longer assertion)
        repeat(5) @(posedge vif.pclk);
        if (vif.sda !== 1'b1 || vif.scl !== 1'b1)
            `uvm_error("TC18", "Bus not IDLE after cold reset")
        else
            `uvm_info("TC18", "Cold reset OK — bus idle confirmed", UVM_LOW)
        vseq = tc18_cold_reset_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc18_cold_reset_test

// =============================================================================
// TC-19: Warm Reset Mid-Transfer
// =============================================================================
class tc19_warm_reset_test extends i2c_base_test;
    `uvm_component_utils(tc19_warm_reset_test)
    function new(string name = "tc19_warm_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc19_warm_reset_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc19_warm_reset_v_seq::type_id::create("vseq");
        fork
            vseq.start(env_h.v_seqrh);
            begin
                // Assert reset mid-transfer (after ~3 byte periods ≈ 240 SCL clocks)
                // 1 SCL cycle @ 100 kHz = 10 µs; 3 bytes = ~30 µs = 30000 ns
                #30000;
                apply_reset(5);
                `uvm_info("TC19", "Warm reset applied mid-transfer", UVM_LOW)
            end
        join
        // After reset: verify bus is idle
        repeat(5) @(posedge vif.pclk);
        if (vif.sda !== 1'b1 || vif.scl !== 1'b1)
            `uvm_error("TC19", "Bus not IDLE after warm reset mid-transfer")
        phase.drop_objection(this);
    endtask
endclass : tc19_warm_reset_test

// =============================================================================
// TC-20: stretch_en=0 — No Clock Stretch
// =============================================================================
class tc20_stretch_disabled_test extends i2c_base_test;
    `uvm_component_utils(tc20_stretch_disabled_test)
    function new(string name = "tc20_stretch_disabled_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        i2c_cfg_h.stretch_en = 1'b0;
    endfunction
    task run_phase(uvm_phase phase);
        tc20_stretch_disabled_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc20_stretch_disabled_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc20_stretch_disabled_test

// =============================================================================
// TC-21: Mid-Write NACK on Byte N>1
// =============================================================================
class tc21_mid_write_nack_test extends i2c_base_test;
    `uvm_component_utils(tc21_mid_write_nack_test)
    function new(string name = "tc21_mid_write_nack_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc21_mid_write_nack_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc21_mid_write_nack_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc21_mid_write_nack_test

// =============================================================================
// TC-22: SDA Glitch During SCL HIGH (false START/STOP)
// =============================================================================
class tc22_sda_glitch_scl_high_test extends i2c_base_test;
    `uvm_component_utils(tc22_sda_glitch_scl_high_test)
    function new(string name = "tc22_sda_glitch_scl_high_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc22_sda_glitch_scl_high_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc22_sda_glitch_scl_high_v_seq::type_id::create("vseq");
        fork
            vseq.start(env_h.v_seqrh);
            begin
                // Wait for SCL HIGH then inject a 2 ns SDA glitch
                @(posedge vif.scl);
                #1;
                force vif.sda_slv_drv = 1'b0;  // Brief SDA glitch during SCL HIGH
                #2;
                release vif.sda_slv_drv;
                `uvm_info("TC22", "SDA glitch injected during SCL HIGH", UVM_LOW)
            end
        join
        phase.drop_objection(this);
    endtask
endclass : tc22_sda_glitch_scl_high_test

// =============================================================================
// TC-23: SCL Spike During Data Transfer
// =============================================================================
class tc23_scl_spike_test extends i2c_base_test;
    `uvm_component_utils(tc23_scl_spike_test)
    function new(string name = "tc23_scl_spike_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc23_scl_spike_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc23_scl_spike_v_seq::type_id::create("vseq");
        fork
            vseq.start(env_h.v_seqrh);
            begin
                // Inject a 2 ns SCL spike while SCL is LOW
                @(negedge vif.scl);
                #3;
                force vif.scl_slv_drv = 1'b1;  // Spike HIGH
                #2;
                release vif.scl_slv_drv;
                `uvm_info("TC23", "SCL spike injected during SCL LOW", UVM_LOW)
            end
        join
        phase.drop_objection(this);
    endtask
endclass : tc23_scl_spike_test

// =============================================================================
// TC-24: Address Collision — Two Targets Same own_addr
// =============================================================================
class tc24_addr_collision_test extends i2c_base_test;
    `uvm_component_utils(tc24_addr_collision_test)
    function new(string name = "tc24_addr_collision_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc24_addr_collision_v_seq vseq;
        phase.raise_objection(this);
        // Note: second target (same 7'h2A) is modelled by having two i2c_seqs
        // respond in parallel — both drive ACK (wired-AND → ACK observed)
        vseq = tc24_addr_collision_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc24_addr_collision_test

// =============================================================================
// TC-25: Unrecognised Command NACK
// =============================================================================
class tc25_unrecognised_cmd_test extends i2c_base_test;
    `uvm_component_utils(tc25_unrecognised_cmd_test)
    function new(string name = "tc25_unrecognised_cmd_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc25_unrecognised_cmd_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc25_unrecognised_cmd_v_seq::type_id::create("vseq");
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc25_unrecognised_cmd_test

// =============================================================================
// TC-26: Back-to-Back Transactions at Minimum t_BUF
// =============================================================================
class tc26_min_tbuf_test extends i2c_base_test;
    `uvm_component_utils(tc26_min_tbuf_test)
    function new(string name = "tc26_min_tbuf_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        tc26_min_tbuf_v_seq vseq;
        phase.raise_objection(this);
        vseq = tc26_min_tbuf_v_seq::type_id::create("vseq");
        // Note: the 4.7 µs t_BUF minimum gap between transactions is enforced
        // by the APB driver waiting for STOP-to-START hold time.
        // Override env_cfg_h.min_tbuf_ns here if a tighter gap is needed.
        vseq.start(env_h.v_seqrh);
        phase.drop_objection(this);
    endtask
endclass : tc26_min_tbuf_test
