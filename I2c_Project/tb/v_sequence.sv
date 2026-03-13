// =============================================================================
// v_sequence.sv — I²C Virtual Sequences (TC-01 to TC-26)
//
// Base class: v_sequence
//   - Casts m_sequencer to v_sequencer
//   - Exposes apb_seqrh and i2c_seqrh for derived classes
//
// Each test case starts:
//   APB sequences  → on vseqrh.apb_seqrh (controller configuration)
//   I²C sequences  → on vseqrh.i2c_seqrh (slave response / bus events)
//   In fork-join to simulate concurrent controller + slave operation
//
// TC-16, TC-17: RESERVED (out-of-scope per VPlan v2.0)
// =============================================================================

// =============================================================================
// Base Virtual Sequence
// =============================================================================
class v_sequence extends uvm_sequence #(uvm_sequence_item);

    `uvm_object_utils(v_sequence)

    v_sequencer vseqrh;   // Populated after super.body() cast

    extern function new(string name = "v_sequence");
    extern task body;

endclass : v_sequence

function v_sequence::new(string name = "v_sequence");
    super.new(name);
endfunction : new

task v_sequence::body;
    if (!$cast(vseqrh, m_sequencer))
        `uvm_fatal("V_SEQ", "m_sequencer cast to v_sequencer failed")
endtask : body

// =============================================================================
// TC-01: Basic Single-Byte Write Transaction
// FRS: FR-PRO-004/007/009-015/018, FR-ADR-001/002/004, FR-ERR-001/002
// =============================================================================
class tc01_basic_write_v_seq extends v_sequence;
    `uvm_object_utils(tc01_basic_write_v_seq)
    function new(string name = "tc01_basic_write_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_ack_seq     i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.tx_data      = 8'hAB;
        apb_seq.byte_cnt_val = 1;

        i2c_seq = i2c_ack_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr = 7'h2A;
        i2c_seq.rw         = 1'b0;
        i2c_seq.num_bytes  = 1;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc01_basic_write_v_seq

// =============================================================================
// TC-02: Basic Single-Byte Read Transaction
// FRS: FR-PRO-004/007/009/014-016, FR-ADR-002, FR-ERR-001/002/005/006e
// =============================================================================
class tc02_basic_read_v_seq extends v_sequence;
    `uvm_object_utils(tc02_basic_read_v_seq)
    function new(string name = "tc02_basic_read_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_ack_seq     i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b1;
        apb_seq.byte_cnt_val = 1;

        i2c_seq = i2c_ack_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr    = 7'h2A;
        i2c_seq.rw            = 1'b1;
        i2c_seq.num_bytes     = 1;
        i2c_seq.read_data     = new[1];
        i2c_seq.read_data[0]  = 8'hC3;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc02_basic_read_v_seq

// =============================================================================
// TC-03: Multi-Byte Write (10 Bytes)
// FRS: FR-PRO-016/017, FR-ERR-001/002/004
// =============================================================================
class tc03_multi_byte_write_v_seq extends v_sequence;
    `uvm_object_utils(tc03_multi_byte_write_v_seq)
    function new(string name = "tc03_multi_byte_write_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_ack_seq     i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 10;

        i2c_seq = i2c_ack_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr = 7'h2A;
        i2c_seq.rw         = 1'b0;
        i2c_seq.num_bytes  = 10;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc03_multi_byte_write_v_seq

// =============================================================================
// TC-04: Multi-Byte Read (5 Bytes, NACK on last)
// FRS: FR-PRO-016/017, FR-ERR-001/004/005/006e
// =============================================================================
class tc04_multi_byte_read_v_seq extends v_sequence;
    `uvm_object_utils(tc04_multi_byte_read_v_seq)
    function new(string name = "tc04_multi_byte_read_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_ack_seq     i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b1;
        apb_seq.byte_cnt_val = 5;

        i2c_seq = i2c_ack_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr    = 7'h2A;
        i2c_seq.rw            = 1'b1;
        i2c_seq.num_bytes     = 5;
        i2c_seq.read_data     = new[5];
        foreach (i2c_seq.read_data[i]) i2c_seq.read_data[i] = 8'hA1 + i;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc04_multi_byte_read_v_seq

// =============================================================================
// TC-05: NACK on Unknown Address (no device at address)
// FRS: FR-ERR-005/006a/007
// =============================================================================
class tc05_nack_addr_v_seq extends v_sequence;
    `uvm_object_utils(tc05_nack_addr_v_seq)
    function new(string name = "tc05_nack_addr_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq  apb_seq;
        i2c_nack_addr_seq i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h7F;   // No device at this address
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 1;

        i2c_seq = i2c_nack_addr_seq::type_id::create("i2c_seq");

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc05_nack_addr_v_seq

// =============================================================================
// TC-06: Repeated START (Sr) — Combined Write then Read
// FRS: FR-PRO-002/003/004/006/007/018, FR-ADR-002
// =============================================================================
class tc06_repeated_start_v_seq extends v_sequence;
    `uvm_object_utils(tc06_repeated_start_v_seq)
    function new(string name = "tc06_repeated_start_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq1, apb_seq2;
        i2c_ack_seq     i2c_seq1, i2c_seq2;
        super.body;

        // First transaction: write
        apb_seq1 = apb_cfg_i2c_seq::type_id::create("apb_seq1");
        apb_seq1.target_addr  = 7'h2A;
        apb_seq1.rw           = 1'b0;
        apb_seq1.restart_req  = 1'b1;  // Issue Sr after write
        apb_seq1.byte_cnt_val = 1;

        i2c_seq1 = i2c_ack_seq::type_id::create("i2c_seq1");
        i2c_seq1.slave_addr = 7'h2A;
        i2c_seq1.rw         = 1'b0;
        i2c_seq1.num_bytes  = 1;

        // Second transaction: read (after Sr)
        apb_seq2 = apb_cfg_i2c_seq::type_id::create("apb_seq2");
        apb_seq2.target_addr  = 7'h2A;
        apb_seq2.rw           = 1'b1;
        apb_seq2.byte_cnt_val = 1;

        i2c_seq2 = i2c_ack_seq::type_id::create("i2c_seq2");
        i2c_seq2.slave_addr    = 7'h2A;
        i2c_seq2.rw            = 1'b1;
        i2c_seq2.num_bytes     = 1;
        i2c_seq2.read_data     = new[1];
        i2c_seq2.read_data[0]  = 8'h55;

        fork
            begin
                apb_seq1.start(vseqrh.apb_seqrh);
                apb_seq2.start(vseqrh.apb_seqrh);
            end
            begin
                i2c_seq1.start(vseqrh.i2c_seqrh);
                i2c_seq2.start(vseqrh.i2c_seqrh);
            end
        join
    endtask
endclass : tc06_repeated_start_v_seq

// =============================================================================
// TC-07: Clock Stretching by Target + NACK-Busy
// FRS: FR-PRO-019/020/021, FR-ERR-006b
// =============================================================================
class tc07_clock_stretch_v_seq extends v_sequence;
    `uvm_object_utils(tc07_clock_stretch_v_seq)
    function new(string name = "tc07_clock_stretch_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq  apb_seq;
        i2c_nack_busy_seq i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 2;
        apb_seq.stretch_en   = 1'b1;

        i2c_seq = i2c_nack_busy_seq::type_id::create("i2c_seq");
        i2c_seq.stretch_cyc = 20;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc07_clock_stretch_v_seq

// =============================================================================
// TC-08: SDA Spike/Glitch Rejection During SCL LOW
// FRS: FR-PHY-009
// =============================================================================
class tc08_sda_glitch_scl_low_v_seq extends v_sequence;
    `uvm_object_utils(tc08_sda_glitch_scl_low_v_seq)
    function new(string name = "tc08_sda_glitch_scl_low_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_ack_seq     i2c_seq;
        super.body;
        // Note: actual glitch injection is handled by force/release in test class
        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 1;

        i2c_seq = i2c_ack_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr = 7'h2A;
        i2c_seq.num_bytes  = 1;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc08_sda_glitch_scl_low_v_seq

// =============================================================================
// TC-09: Bus Hang Recovery (SDA stuck LOW — 9 SCL pulses)
// FRS: FR-ERR-008/009
// =============================================================================
class tc09_bus_hang_recovery_v_seq extends v_sequence;
    `uvm_object_utils(tc09_bus_hang_recovery_v_seq)
    function new(string name = "tc09_bus_hang_recovery_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq  apb_seq;
        i2c_recovery_seq i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 1;

        i2c_seq = i2c_recovery_seq::type_id::create("i2c_seq");

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc09_bus_hang_recovery_v_seq

// =============================================================================
// TC-10: General Call Address 0x00
// FRS: FR-ADR-009
// =============================================================================
class tc10_general_call_v_seq extends v_sequence;
    `uvm_object_utils(tc10_general_call_v_seq)
    function new(string name = "tc10_general_call_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_gen_call_seq i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h00;  // General Call
        apb_seq.rw           = 1'b0;
        apb_seq.tx_data      = 8'h04;  // GC command
        apb_seq.byte_cnt_val = 1;

        i2c_seq = i2c_gen_call_seq::type_id::create("i2c_seq");
        i2c_seq.cmd_byte = 8'h04;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc10_general_call_v_seq

// =============================================================================
// TC-11: Arbitration Loss Detection (Design Review + Force inject arb_lost)
// FRS: FR-ERR-011/012
// =============================================================================
class tc11_arb_loss_v_seq extends v_sequence;
    `uvm_object_utils(tc11_arb_loss_v_seq)
    function new(string name = "tc11_arb_loss_v_seq");
        super.new(name);
    endfunction

    task body;
        super.body;
        // Arbitration loss is a design review scenario for single-controller DUT
        // Force injection of arb_lost signal is done in tc11_arb_loss_test
        `uvm_info("TC11", "Arbitration loss — design review scenario (single-controller DUT)", UVM_LOW)
    endtask
endclass : tc11_arb_loss_v_seq

// =============================================================================
// TC-12: SCL Frequency Measurement (Standard-Mode timing verification)
// FRS: FR-SPD-001/002/003
// =============================================================================
class tc12_scl_timing_v_seq extends v_sequence;
    `uvm_object_utils(tc12_scl_timing_v_seq)
    function new(string name = "tc12_scl_timing_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_ack_seq     i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 1;

        i2c_seq = i2c_ack_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr = 7'h2A;
        i2c_seq.num_bytes  = 1;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
        // proto_mon.sv handles timing measurement for TC-12
    endtask
endclass : tc12_scl_timing_v_seq

// =============================================================================
// TC-13: Reserved Address Rejection (0x00–0x07 with gen_call_en=0, 0x78–0x7F)
// FRS: FR-ADR-013, FR-ADR-009 (negative case)
// =============================================================================
class tc13_reserved_addr_v_seq extends v_sequence;
    `uvm_object_utils(tc13_reserved_addr_v_seq)
    function new(string name = "tc13_reserved_addr_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq   apb_seq;
        i2c_nack_addr_seq i2c_seq;
        super.body;

        // Send reserved addresses — expect NACK from all targets
        foreach ({7'h01, 7'h78, 7'h7F}) begin
            apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
            apb_seq.target_addr  = 7'h01;
            apb_seq.rw           = 1'b0;
            apb_seq.byte_cnt_val = 1;

            i2c_seq = i2c_nack_addr_seq::type_id::create("i2c_seq");

            fork
                apb_seq.start(vseqrh.apb_seqrh);
                i2c_seq.start(vseqrh.i2c_seqrh);
            join
        end
    endtask
endclass : tc13_reserved_addr_v_seq

// =============================================================================
// TC-14: SDA Data Validity During SCL HIGH (Formal + Simulation)
// FRS: FR-PRO-010/011
// =============================================================================
class tc14_sda_validity_v_seq extends v_sequence;
    `uvm_object_utils(tc14_sda_validity_v_seq)
    function new(string name = "tc14_sda_validity_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_ack_seq     i2c_seq;
        super.body;
        // ASS-01 monitors SDA stability throughout this transaction
        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 1;

        i2c_seq = i2c_ack_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr = 7'h2A;
        i2c_seq.num_bytes  = 1;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc14_sda_validity_v_seq

// =============================================================================
// TC-15: Idle Bus State Verification (after reset)
// FRS: FR-PHY-005, FR-PRO-001
// =============================================================================
class tc15_idle_bus_v_seq extends v_sequence;
    `uvm_object_utils(tc15_idle_bus_v_seq)
    function new(string name = "tc15_idle_bus_v_seq");
        super.new(name);
    endfunction

    task body;
        super.body;
        // Simply observe that bus is IDLE (no APB transactions issued)
        // Test class applies reset and checks SDA=1, SCL=1 before any start_req
        `uvm_info("TC15", "Bus idle verification — no stimulus needed, observing reset state", UVM_LOW)
    endtask
endclass : tc15_idle_bus_v_seq

// =============================================================================
// TC-16, TC-17: RESERVED — Out of Scope (multi-controller scenarios)
// =============================================================================
// TC-16 intentionally omitted (multi-controller arbitration — OOS)
// TC-17 intentionally omitted (concurrent Sr — OOS)

// =============================================================================
// TC-18: Power-On / Cold Reset Bus Idle
// FRS: FR-PHY-005, FR-PRO-001
// =============================================================================
class tc18_cold_reset_v_seq extends v_sequence;
    `uvm_object_utils(tc18_cold_reset_v_seq)
    function new(string name = "tc18_cold_reset_v_seq");
        super.new(name);
    endfunction

    task body;
        super.body;
        // Reset assertion/deassertion handled by test class
        `uvm_info("TC18", "Cold reset — bus idle check after power-on reset", UVM_LOW)
    endtask
endclass : tc18_cold_reset_v_seq

// =============================================================================
// TC-19: Warm Reset Mid-Transfer
// FRS: FR-ERR-010
// =============================================================================
class tc19_warm_reset_v_seq extends v_sequence;
    `uvm_object_utils(tc19_warm_reset_v_seq)
    function new(string name = "tc19_warm_reset_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_ack_seq     i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 10;  // Long transfer — reset will interrupt it

        i2c_seq = i2c_ack_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr = 7'h2A;
        i2c_seq.num_bytes  = 10;

        // Note: test class will assert rst_n=0 after byte 3 ACK
        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc19_warm_reset_v_seq

// =============================================================================
// TC-20: stretch_en=0 — No Clock Stretch
// FRS: FR-PRO-021
// =============================================================================
class tc20_stretch_disabled_v_seq extends v_sequence;
    `uvm_object_utils(tc20_stretch_disabled_v_seq)
    function new(string name = "tc20_stretch_disabled_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_stretch_seq i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 10;
        apb_seq.stretch_en   = 1'b0;

        i2c_seq = i2c_stretch_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr     = 7'h2A;
        i2c_seq.stretch_en_val = 1'b0;  // stretch disabled
        i2c_seq.stretch_cyc    = 0;
        i2c_seq.num_bytes      = 10;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc20_stretch_disabled_v_seq

// =============================================================================
// TC-21: Mid-Write NACK on Byte N>1
// FRS: FR-ERR-005/007
// =============================================================================
class tc21_mid_write_nack_v_seq extends v_sequence;
    `uvm_object_utils(tc21_mid_write_nack_v_seq)
    function new(string name = "tc21_mid_write_nack_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq   apb_seq;
        i2c_nack_data_seq i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 5;

        i2c_seq = i2c_nack_data_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr   = 7'h2A;
        i2c_seq.nack_on_byte = 2;   // NACK on byte 3 (index 2)
        i2c_seq.cause        = NACK_OVERFLOW;
        i2c_seq.num_bytes    = 5;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc21_mid_write_nack_v_seq

// =============================================================================
// TC-22: SDA Glitch During SCL HIGH (false START/STOP check)
// FRS: FR-PHY-009
// =============================================================================
class tc22_sda_glitch_scl_high_v_seq extends v_sequence;
    `uvm_object_utils(tc22_sda_glitch_scl_high_v_seq)
    function new(string name = "tc22_sda_glitch_scl_high_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_ack_seq     i2c_seq;
        super.body;
        // Glitch injection handled by force/release in test class during SCL HIGH
        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 2;

        i2c_seq = i2c_ack_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr = 7'h2A;
        i2c_seq.num_bytes  = 2;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc22_sda_glitch_scl_high_v_seq

// =============================================================================
// TC-23: SCL Spike During Data Transfer
// FRS: FR-PHY-009
// =============================================================================
class tc23_scl_spike_v_seq extends v_sequence;
    `uvm_object_utils(tc23_scl_spike_v_seq)
    function new(string name = "tc23_scl_spike_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_ack_seq     i2c_seq;
        super.body;
        // SCL spike injection via force/release in test class
        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 1;

        i2c_seq = i2c_ack_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr = 7'h2A;
        i2c_seq.num_bytes  = 1;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc23_scl_spike_v_seq

// =============================================================================
// TC-24: Address Collision — Two Targets with Same own_addr
// FRS: FR-ADR-003
// =============================================================================
class tc24_addr_collision_v_seq extends v_sequence;
    `uvm_object_utils(tc24_addr_collision_v_seq)
    function new(string name = "tc24_addr_collision_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq;
        i2c_ack_seq     i2c_seq;
        super.body;
        // Two targets configured with same address — wired-AND ACK expected
        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.byte_cnt_val = 1;

        i2c_seq = i2c_ack_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr = 7'h2A;
        i2c_seq.num_bytes  = 1;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc24_addr_collision_v_seq

// =============================================================================
// TC-25: Unrecognised Command NACK (IP-Level)
// FRS: FR-ERR-006c
// =============================================================================
class tc25_unrecognised_cmd_v_seq extends v_sequence;
    `uvm_object_utils(tc25_unrecognised_cmd_v_seq)
    function new(string name = "tc25_unrecognised_cmd_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq   apb_seq;
        i2c_nack_data_seq i2c_seq;
        super.body;

        apb_seq = apb_cfg_i2c_seq::type_id::create("apb_seq");
        apb_seq.target_addr  = 7'h2A;
        apb_seq.rw           = 1'b0;
        apb_seq.tx_data      = 8'hFF;  // Unrecognised command
        apb_seq.byte_cnt_val = 1;

        i2c_seq = i2c_nack_data_seq::type_id::create("i2c_seq");
        i2c_seq.slave_addr   = 7'h2A;
        i2c_seq.nack_on_byte = 0;
        i2c_seq.cause        = NACK_BAD_CMD;
        i2c_seq.num_bytes    = 1;

        fork
            apb_seq.start(vseqrh.apb_seqrh);
            i2c_seq.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc25_unrecognised_cmd_v_seq

// =============================================================================
// TC-26: Back-to-Back Transactions at Minimum t_BUF
// FRS: FR-PRO-001/009
// =============================================================================
class tc26_min_tbuf_v_seq extends v_sequence;
    `uvm_object_utils(tc26_min_tbuf_v_seq)
    function new(string name = "tc26_min_tbuf_v_seq");
        super.new(name);
    endfunction

    task body;
        apb_cfg_i2c_seq apb_seq1, apb_seq2;
        i2c_ack_seq     i2c_seq1, i2c_seq2;
        super.body;

        // First transaction
        apb_seq1 = apb_cfg_i2c_seq::type_id::create("apb_seq1");
        apb_seq1.target_addr  = 7'h2A;
        apb_seq1.rw           = 1'b0;
        apb_seq1.byte_cnt_val = 1;

        i2c_seq1 = i2c_ack_seq::type_id::create("i2c_seq1");
        i2c_seq1.slave_addr = 7'h2A;
        i2c_seq1.num_bytes  = 1;

        fork
            apb_seq1.start(vseqrh.apb_seqrh);
            i2c_seq1.start(vseqrh.i2c_seqrh);
        join

        // Second transaction — issued exactly at t_BUF minimum boundary
        // Test class controls the inter-transaction gap timing
        apb_seq2 = apb_cfg_i2c_seq::type_id::create("apb_seq2");
        apb_seq2.target_addr  = 7'h2A;
        apb_seq2.rw           = 1'b0;
        apb_seq2.byte_cnt_val = 1;

        i2c_seq2 = i2c_ack_seq::type_id::create("i2c_seq2");
        i2c_seq2.slave_addr = 7'h2A;
        i2c_seq2.num_bytes  = 1;

        fork
            apb_seq2.start(vseqrh.apb_seqrh);
            i2c_seq2.start(vseqrh.i2c_seqrh);
        join
    endtask
endclass : tc26_min_tbuf_v_seq
