// =============================================================================
// i2c_sva.sv — I²C SVA Assertions Module
//
// All 16 SystemVerilog Assertions (ASS-01 to ASS-16) from VPlan Section 10.
// Bound to DUT interface signals via the i2c_if interface.
// All timing parameters sourced from i2c_pkg.v — NO hard-coded values.
//
// Formal verification scope (VPlan v2.0):
//   ASS-01, ASS-02, ASS-03, ASS-07, ASS-09, ASS-12, ASS-13
//
// Instantiated in i2c_tb_top.sv as: i2c_sva sva_inst(...)
// =============================================================================

`include "i2c_pkg.v"

module i2c_sva (
    input logic        clk,
    input logic        rst_n,

    // I²C bus signals
    input wire         sda,
    input wire         scl,

    // DUT observable signals
    input logic        sda_out,
    input logic        sda_oe,
    input logic        scl_out,
    input logic        busy,
    input logic        bus_free,
    input logic        start_cond,
    input logic        stop_cond,
    input logic        arb_lost,
    input logic        recovery_active,
    input logic [3:0]  recovery_cnt,
    input logic [3:0]  bit_cnt,
    input logic        tx_ack_phase,
    input logic        addr_ack_phase,
    input logic        addr_match,
    input logic [7:0]  tx_data,
    input logic        ctrl_active,
    input logic        restart
);

    // =========================================================================
    // ASS-01 — SDA Data Validity (FR-PRO-010, FR-PRO-011) [FORMAL]
    // SDA must not change while SCL is HIGH, except during START/STOP conditions
    // =========================================================================
    property p_sda_stability;
        @(posedge clk)
        (scl && !start_cond && !stop_cond) |-> $stable(sda_out);
    endproperty
    ASS_01_SDA_DATA_VALID : assert property (p_sda_stability)
        else `uvm_error("ASS_01", "SDA changed while SCL=HIGH (not START/STOP) — FR-PRO-010/011 violated")

    // =========================================================================
    // ASS-02 — START Condition Waveform (FR-PRO-004) [FORMAL EXPANDED v2.0]
    // START valid only when SCL HIGH and SDA has falling edge
    // =========================================================================
    property p_start_condition;
        @(posedge clk)
        start_cond |-> (scl_out && $fell(sda_out));
    endproperty
    ASS_02_START_CONDITION : assert property (p_start_condition)
        else `uvm_error("ASS_02", "Invalid START: SCL not HIGH or SDA did not fall — FR-PRO-004")

    // =========================================================================
    // ASS-03 — STOP Condition Waveform (FR-PRO-007) [FORMAL EXPANDED v2.0]
    // STOP valid only when SCL HIGH and SDA has rising edge
    // =========================================================================
    property p_stop_condition;
        @(posedge clk)
        stop_cond |-> (scl_out && $rose(sda_out));
    endproperty
    ASS_03_STOP_CONDITION : assert property (p_stop_condition)
        else `uvm_error("ASS_03", "Invalid STOP: SCL not HIGH or SDA did not rise — FR-PRO-007")

    // =========================================================================
    // ASS-04 — 9 SCL Pulses Per Byte (FR-PRO-013, FR-PRO-016)
    // On 9th SCL falling edge, controller must be in ACK phase
    // =========================================================================
    property p_9_scl_per_byte;
        @(negedge scl)
        (bit_cnt == 4'd8) |-> tx_ack_phase;
    endproperty
    ASS_04_9_SCL_PULSES : assert property (p_9_scl_per_byte)
        else `uvm_error("ASS_04", "bit_cnt==8 but not in ACK phase — FR-PRO-013 violated")

    // =========================================================================
    // ASS-05 — MSB First Transmission (FR-PRO-015)
    // First bit driven on SDA must match tx_data[7]
    // =========================================================================
    property p_msb_first;
        @(posedge scl)
        (bit_cnt == 4'd0) |-> (sda_out == tx_data[7]);
    endproperty
    ASS_05_MSB_FIRST : assert property (p_msb_first)
        else `uvm_error("ASS_05", "First bit on SDA != tx_data[7] — MSB-first violated FR-PRO-015")

    // =========================================================================
    // ASS-06 — Bus Busy After START (FR-PRO-002)
    // bus_busy must be asserted one clock after START condition
    // =========================================================================
    property p_bus_busy_after_start;
        @(posedge clk)
        start_cond |-> ##1 busy;
    endproperty
    ASS_06_BUS_BUSY : assert property (p_bus_busy_after_start)
        else `uvm_error("ASS_06", "bus_busy not set after START — FR-PRO-002 violated")

    // =========================================================================
    // ASS-07 — Bus Free After STOP (FR-PRO-001, FR-PRO-009) [FORMAL EXPANDED]
    // bus_free must be asserted within [T_BUF : T_BUF+2] cycles of STOP
    // =========================================================================
    property p_bus_free_after_stop;
        @(posedge clk)
        stop_cond |-> ##[T_BUF : T_BUF+2] bus_free;
    endproperty
    ASS_07_BUS_FREE : assert property (p_bus_free_after_stop)
        else `uvm_error("ASS_07", "bus_free not set within T_BUF after STOP — FR-PRO-001/009")

    // =========================================================================
    // ASS-08 — ACK Timing t_SU_DAT (FR-ERR-003)
    // ACK bit must be stable for at least T_SU_DAT before SCL rising edge
    // =========================================================================
    property p_ack_timing;
        @(posedge scl)
        addr_ack_phase |-> $stable(sda_out)[*T_SU_DAT];
    endproperty
    ASS_08_ACK_TIMING : assert property (p_ack_timing)
        else `uvm_error("ASS_08", "ACK/NACK not stable for T_SU_DAT before SCL rise — FR-ERR-003")

    // =========================================================================
    // ASS-09 — No START on Busy Bus (FR-PRO-006) [FORMAL]
    // No START generated when bus is BUSY unless it is a repeated START
    // =========================================================================
    property p_no_start_on_busy;
        @(posedge clk)
        ($rose(start_cond) && busy && !restart) |-> !start_cond;
    endproperty
    ASS_09_NO_START_BUSY : assert property (p_no_start_on_busy)
        else `uvm_error("ASS_09", "START generated while bus BUSY (not Sr) — FR-PRO-006 violated")

    // =========================================================================
    // ASS-10 — No SDA Drive During ACK Window (FR-ERR-001)
    // Transmitter must release SDA output enable during ACK window
    // =========================================================================
    property p_sda_release_ack;
        @(posedge clk)
        tx_ack_phase |-> !sda_oe;
    endproperty
    ASS_10_SDA_RELEASE_ACK : assert property (p_sda_release_ack)
        else `uvm_error("ASS_10", "Transmitter driving SDA during ACK window — FR-ERR-001 violated")

    // =========================================================================
    // ASS-11 — Target ACK on Address Match (FR-ADR-004)
    // SDA must be LOW on address ACK phase when address matches
    // =========================================================================
    property p_target_ack_on_match;
        @(posedge scl)
        (addr_ack_phase && addr_match) |-> (sda == 1'b0);
    endproperty
    ASS_11_TARGET_ACK : assert property (p_target_ack_on_match)
        else `uvm_error("ASS_11", "Target did not ACK on address match — FR-ADR-004 violated")

    // =========================================================================
    // ASS-12 — No STOP After Arbitration Loss (FR-ERR-012) [FORMAL]
    // Controller must not generate STOP when arb_lost is asserted
    // =========================================================================
    property p_no_stop_on_arb_loss;
        @(posedge clk)
        arb_lost |-> !stop_cond;
    endproperty
    ASS_12_NO_STOP_ARB_LOSS : assert property (p_no_stop_on_arb_loss)
        else `uvm_error("ASS_12", "STOP generated after arb_lost — FR-ERR-012 violated")

    // =========================================================================
    // ASS-13 — Recovery Pulse Count ≤ 9 (FR-ERR-008) [FORMAL EXPANDED]
    // During bus hang recovery, SCL pulse count must not exceed 9
    // =========================================================================
    property p_recovery_count;
        @(posedge clk)
        recovery_active |-> (recovery_cnt <= 4'd9);
    endproperty
    ASS_13_RECOVERY_COUNT : assert property (p_recovery_count)
        else `uvm_error("ASS_13",
            $sformatf("recovery_cnt=%0d > 9 — FR-ERR-008 violated", recovery_cnt))

    // =========================================================================
    // ASS-14 — SCL Frequency Bound (FR-SPD-002)
    // SCL period must be >= CLK_DIV_STD system cycles (100 kHz max)
    // =========================================================================
    property p_scl_freq;
        @(posedge scl)
        1 |-> ##[CLK_DIV_STD : CLK_DIV_STD*2] $rose(scl);
    endproperty
    ASS_14_SCL_FREQ : assert property (p_scl_freq)
        else `uvm_error("ASS_14", "SCL period < CLK_DIV_STD — exceeds 100 kHz FR-SPD-002")

    // =========================================================================
    // ASS-15 — STOP Only By Controller (NEW v2.0, FR-PRO-008)
    // STOP condition can only occur when controller is actively driving bus
    // =========================================================================
    property p_stop_only_by_ctrl;
        @(posedge clk)
        stop_cond |-> ctrl_active;
    endproperty
    ASS_15_STOP_BY_CTRL_ONLY : assert property (p_stop_only_by_ctrl)
        else `uvm_error("ASS_15", "STOP generated when ctrl_active=0 — FR-PRO-008 violated")

    // =========================================================================
    // ASS-16 — 1 Bit Per SCL Pulse (NEW v2.0, FR-PRO-012)
    // bit_cnt must increment by exactly 1 on each SCL rising edge
    // =========================================================================
    property p_1bit_per_scl;
        @(posedge scl)
        $rose(scl) |-> ##1 (bit_cnt == $past(bit_cnt) + 1);
    endproperty
    ASS_16_1BIT_PER_SCL : assert property (p_1bit_per_scl)
        else `uvm_error("ASS_16", "bit_cnt did not increment by 1 on SCL rise — FR-PRO-012")

endmodule : i2c_sva
