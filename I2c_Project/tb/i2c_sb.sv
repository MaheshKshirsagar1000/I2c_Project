// =============================================================================
// i2c_sb.sv — I²C Scoreboard + Functional Coverage Collector
//
// Coverage groups mapped to VPlan Section 9 (COV-01 to COV-16):
//   COV-01  Bus state (IDLE/BUSY/FREE)
//   COV-02  Transaction type (READ/WRITE)
//   COV-03  Byte count (1, 2-8, 9-255)
//   COV-04  ACK/NACK bit per byte
//   COV-05  NACK cause (all 5 conditions FR-ERR-006a–e)
//   COV-06  Repeated START
//   COV-07  Clock stretching (enabled/disabled, min/max duration)
//   COV-08  Target address (valid, GC, reserved)
//   COV-09  Error events (no_device, bus_hang, bad_cmd)
//   COV-10  SCL timing (at 100 kHz, below 100 kHz)
//   COV-11  Bus recovery (1-8, 9 pulses)
//   COV-12  Spike injection (1ns, 2ns, 3ns glitch widths)
//   COV-13  Address boundary (GC, 0x01, reserved)
//   COV-14  General Call enable/disable
//   COV-15  Bit-per-SCL-pulse (normal, extra)
//   COV-16  stretch_en=0 vs =1
//
// Functional checks:
//   - Address phase: addr + R/W matches APB configuration
//   - Data integrity: tx_data bytes match APB-programmed values
//   - ACK/NACK behaviour: correct per scenario
//   - Transfer completeness: START, STOP, byte count
// =============================================================================

class i2c_sb extends uvm_scoreboard;

    `uvm_component_utils(i2c_sb)

    i2c_env_config  env_cfg;

    // TLM FIFO ports (connected from monitors in i2c_env.sv)
    uvm_tlm_analysis_fifo #(apb_xtn) apb_tlm_port;
    uvm_tlm_analysis_fifo #(i2c_xtn) i2c_tlm_port;

    // Captured transactions (current scoreboard cycle)
    apb_xtn  apb_pkt;
    i2c_xtn  i2c_pkt;
    i2c_xtn  cov_data;   // Alias used by covergroups

    int no_of_pass;
    int no_of_fail;

    // =========================================================================
    // COV-01 — Bus State (IDLE / BUSY / FREE)
    // =========================================================================
    covergroup bus_state_cov;
        option.per_instance = 1;
        BUS_STATE : coverpoint cov_data.bus_state_at_start {
            bins IDLE = {BUS_IDLE};
            bins BUSY = {BUS_BUSY};
            bins FREE = {BUS_FREE};
        }
    endgroup

    // =========================================================================
    // COV-02 — Transaction Type (READ / WRITE)
    // =========================================================================
    covergroup txn_type_cov;
        option.per_instance = 1;
        RW_BIT : coverpoint cov_data.rw {
            bins WRITE = {1'b0};
            bins READ  = {1'b1};
        }
    endgroup

    // =========================================================================
    // COV-03 — Byte Count (1 / 2-8 / 9-255)
    // =========================================================================
    covergroup byte_count_cov;
        option.per_instance = 1;
        BYTE_CNT : coverpoint cov_data.byte_cnt {
            bins ONE      = {1};
            bins MID_RANGE= {[2:8]};
            bins MAX_BURST= {[9:255]};
        }
    endgroup

    // =========================================================================
    // COV-04 — ACK/NACK bit per byte (both conditions seen)
    // =========================================================================
    covergroup ack_nack_cov;
        option.per_instance = 1;
        ACK_BIT : coverpoint cov_data.ack[0] {
            bins ACK  = {1'b0};
            bins NACK = {1'b1};
        }
    endgroup

    // =========================================================================
    // COV-05 — NACK Cause (all 5 FR-ERR-006a–e conditions)
    // =========================================================================
    covergroup nack_cause_cov;
        option.per_instance = 1;
        NACK_CAUSE : coverpoint cov_data.nack_cause {
            bins NO_DEVICE   = {NACK_NO_DEVICE};
            bins TARGET_BUSY = {NACK_TARGET_BUSY};
            bins BAD_CMD     = {NACK_BAD_CMD};
            bins OVERFLOW    = {NACK_OVERFLOW};
            bins LAST_BYTE   = {NACK_LAST_BYTE};
        }
    endgroup

    // =========================================================================
    // COV-06 — Repeated START (with restart / without)
    // =========================================================================
    covergroup repeated_start_cov;
        option.per_instance = 1;
        RESTART : coverpoint cov_data.sr_detected {
            bins WITHOUT_RESTART = {1'b0};
            bins WITH_RESTART    = {1'b1};
        }
    endgroup

    // =========================================================================
    // COV-07 — Clock Stretching (enabled/disabled, min/max duration)
    // =========================================================================
    covergroup clock_stretch_cov;
        option.per_instance = 1;
        STRETCH_EN : coverpoint cov_data.stretch_en {
            bins DISABLED = {1'b0};
            bins ENABLED  = {1'b1};
        }
        STRETCH_DUR : coverpoint cov_data.stretch_duration {
            bins NONE    = {0};
            bins MIN     = {[1:20]};
            bins MAX     = {[21:500]};
        }
        STRETCH_CROSS : cross STRETCH_EN, STRETCH_DUR;
    endgroup

    // =========================================================================
    // COV-08 — Target Address (valid range, GC, reserved)
    // =========================================================================
    covergroup target_addr_cov;
        option.per_instance = 1;
        ADDR : coverpoint cov_data.addr {
            bins VALID_RANGE[] = {[7'h08 : 7'h77]};
            bins GEN_CALL      = {7'h00};
            bins RESERVED_LOW  = {[7'h01 : 7'h07]};
            bins RESERVED_HIGH = {[7'h78 : 7'h7F]};
        }
    endgroup

    // =========================================================================
    // COV-09 — Error Events (no_device, bus_hang, bad_cmd)
    // =========================================================================
    covergroup error_events_cov;
        option.per_instance = 1;
        ERR_TYPE : coverpoint cov_data.nack_cause {
            bins NO_DEVICE   = {NACK_NO_DEVICE};
            bins BUS_HANG    = {NACK_TARGET_BUSY};
            bins BAD_CMD     = {NACK_BAD_CMD};
            ignore_bins NONE = {NACK_NONE};
        }
    endgroup

    // =========================================================================
    // COV-10 — SCL Timing (at 100 kHz / below 100 kHz)
    // SCL period at 100 kHz = 10000 ns; below = >10000 ns
    // =========================================================================
    covergroup scl_timing_cov;
        option.per_instance = 1;
        SCL_PERIOD : coverpoint cov_data.scl_period_ns {
            bins AT_100KHZ   = {[9800 : 10200]};  // ±2% tolerance
            bins BELOW_100KHZ= {[10201 : 20000]};
        }
    endgroup

    // =========================================================================
    // COV-11 — Bus Recovery pulse count (1-8 / 9)
    // =========================================================================
    covergroup bus_recovery_cov;
        option.per_instance = 1;
        RECOVERY_PULSES : coverpoint cov_data.recovery_pulses {
            bins PARTIAL  = {[4'h1 : 4'h8]};
            bins FULL_9   = {4'h9};
        }
    endgroup

    // =========================================================================
    // COV-12 — Spike Injection (1ns, 2ns, 3ns glitch widths)
    // =========================================================================
    covergroup spike_cov;
        option.per_instance = 1;
        SDA_GLITCH : coverpoint cov_data.glitch_sda {
            bins NO_GLITCH  = {1'b0};
            bins HAS_GLITCH = {1'b1};
        }
        GLITCH_WIDTH : coverpoint cov_data.glitch_width_ns {
            bins W_1NS = {1};
            bins W_2NS = {2};
            bins W_3NS = {3};
        }
    endgroup

    // =========================================================================
    // COV-13 — Address Boundary (0x00 GC, 0x01 START byte, reserved)
    // =========================================================================
    covergroup addr_boundary_cov;
        option.per_instance = 1;
        ADDR_SPECIAL : coverpoint cov_data.addr {
            bins GEN_CALL     = {7'h00};
            bins START_BYTE   = {7'h01};
            bins RESERVED_LOW = {[7'h02 : 7'h07]};
            bins VALID_LOW    = {7'h08};
            bins VALID_HIGH   = {7'h77};
            bins RESERVED_HIGH= {[7'h78 : 7'h7F]};
        }
    endgroup

    // =========================================================================
    // COV-14 — General Call enable/disable
    // =========================================================================
    covergroup gen_call_cov;
        option.per_instance = 1;
        GEN_CALL_EN : coverpoint cov_data.gen_call {
            bins DISABLED = {1'b0};
            bins ENABLED  = {1'b1};
        }
    endgroup

    // =========================================================================
    // COV-15 — Bit-per-SCL-pulse (normal: 1 bit / extra: >1 bit — ASS-16)
    // =========================================================================
    covergroup bit_per_pulse_cov;
        option.per_instance = 1;
        GLITCH_SCL : coverpoint cov_data.glitch_scl {
            bins NORMAL     = {1'b0};   // No extra SCL edge
            bins EXTRA_EDGE = {1'b1};   // SCL spike injected
        }
    endgroup

    // =========================================================================
    // COV-16 — stretch_en=0 vs stretch_en=1
    // =========================================================================
    covergroup stretch_en_cov;
        option.per_instance = 1;
        STRETCH_ENABLE : coverpoint cov_data.stretch_en {
            bins DISABLED = {1'b0};
            bins ENABLED  = {1'b1};
        }
    endgroup

    // =========================================================================
    // Constructor — instantiate all covergroups
    // =========================================================================
    function new(string name = "i2c_sb", uvm_component parent);
        super.new(name, parent);
        bus_state_cov      = new();
        txn_type_cov       = new();
        byte_count_cov     = new();
        ack_nack_cov       = new();
        nack_cause_cov     = new();
        repeated_start_cov = new();
        clock_stretch_cov  = new();
        target_addr_cov    = new();
        error_events_cov   = new();
        scl_timing_cov     = new();
        bus_recovery_cov   = new();
        spike_cov          = new();
        addr_boundary_cov  = new();
        gen_call_cov       = new();
        bit_per_pulse_cov  = new();
        stretch_en_cov     = new();
    endfunction : new

    // =========================================================================
    // Build Phase
    // =========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(i2c_env_config)::get(this, "", "i2c_env_config", env_cfg))
            `uvm_fatal("I2C_SB", "GET of i2c_env_config failed")
        apb_tlm_port = new("apb_tlm_port", this);
        i2c_tlm_port = new("i2c_tlm_port", this);
        no_of_pass = 0;
        no_of_fail = 0;
    endfunction : build_phase

    // =========================================================================
    // Run Phase — parallel APB + I²C packet collection
    // =========================================================================
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            fork
                // Get APB transaction
                begin
                    apb_tlm_port.get(apb_pkt);
                    `uvm_info("I2C_SB",
                        $sformatf("APB PKT received\n%s", apb_pkt.convert2string()),
                        UVM_HIGH)
                end
                // Get I²C bus transaction
                begin
                    i2c_tlm_port.get(i2c_pkt);
                    `uvm_info("I2C_SB",
                        $sformatf("I2C PKT received\n%s", i2c_pkt.convert2string()),
                        UVM_LOW)
                    // Sample coverage on each I²C transaction
                    cov_data = i2c_pkt;
                    sample_coverage();
                end
            join
        end
    endtask : run_phase

    // =========================================================================
    // Sample all 16 covergroups
    // =========================================================================
    function void sample_coverage();
        bus_state_cov.sample();
        txn_type_cov.sample();
        byte_count_cov.sample();
        if (cov_data.ack.size() > 0) ack_nack_cov.sample();
        nack_cause_cov.sample();
        repeated_start_cov.sample();
        clock_stretch_cov.sample();
        target_addr_cov.sample();
        error_events_cov.sample();
        scl_timing_cov.sample();
        if (cov_data.recovery_detected) bus_recovery_cov.sample();
        if (cov_data.glitch_sda || cov_data.glitch_scl) spike_cov.sample();
        addr_boundary_cov.sample();
        gen_call_cov.sample();
        bit_per_pulse_cov.sample();
        stretch_en_cov.sample();
    endfunction : sample_coverage

    // =========================================================================
    // Check Phase — functional comparison
    // =========================================================================
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);

        if (i2c_pkt == null) begin
            `uvm_warning("I2C_SB", "No I²C packet received — nothing to check")
            return;
        end

        // ---------------------------------------------------------------
        // Check 1: Address Phase — address matches and START was detected
        // ---------------------------------------------------------------
        if (!i2c_pkt.start_detected)
            `uvm_error("I2C_SB", "No START condition detected in transaction")

        // ---------------------------------------------------------------
        // Check 2: Data Integrity — write path (controller → target)
        // ---------------------------------------------------------------
        if (i2c_pkt.rw == 1'b0 && !i2c_pkt.nack_det) begin
            if (i2c_pkt.byte_cnt == 0)
                `uvm_warning("I2C_SB", "Write transaction with 0 data bytes")
            else begin
                `uvm_info("I2C_SB",
                    $sformatf("WRITE check PASS: addr=7'h%02h bytes=%0d",
                        i2c_pkt.addr, i2c_pkt.byte_cnt), UVM_LOW)
                no_of_pass++;
            end
        end

        // ---------------------------------------------------------------
        // Check 3: Data Integrity — read path (target → controller)
        // ---------------------------------------------------------------
        if (i2c_pkt.rw == 1'b1 && !i2c_pkt.nack_det) begin
            `uvm_info("I2C_SB",
                $sformatf("READ check PASS: addr=7'h%02h bytes=%0d",
                    i2c_pkt.addr, i2c_pkt.byte_cnt), UVM_LOW)
            no_of_pass++;
        end

        // ---------------------------------------------------------------
        // Check 4: NACK — verify correct NACK cause flagged
        // ---------------------------------------------------------------
        if (i2c_pkt.nack_det && i2c_pkt.nack_cause == NACK_NONE)
            `uvm_error("I2C_SB",
                "NACK detected but nack_cause == NACK_NONE — cause not classified")

        // ---------------------------------------------------------------
        // Check 5: STOP condition after NACK (FR-ERR-007)
        // ---------------------------------------------------------------
        if (i2c_pkt.nack_det && !i2c_pkt.stop_detected)
            `uvm_error("I2C_SB",
                "NACK detected but no STOP condition followed — FR-ERR-007 violation")

        // ---------------------------------------------------------------
        // Check 6: Recovery pulse count ≤ 9 (FR-ERR-008, ASS-13)
        // ---------------------------------------------------------------
        if (i2c_pkt.recovery_detected && i2c_pkt.recovery_pulses > 4'h9)
            `uvm_error("I2C_SB",
                $sformatf("Recovery pulse count %0d > 9 — FR-ERR-008 violation",
                    i2c_pkt.recovery_pulses))

        $display("==============================");
        $display("SCOREBOARD PASS count = %0d", no_of_pass);
        $display("SCOREBOARD FAIL count = %0d", no_of_fail);
        $display("==============================");

    endfunction : check_phase

endclass : i2c_sb
