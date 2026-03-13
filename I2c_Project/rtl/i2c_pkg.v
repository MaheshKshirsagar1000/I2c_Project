// =============================================================================
// i2c_pkg.v — I²C Timing Parameters and Mode Constants
// Protocol : I²C Standard-mode (100 kbit/s)
// Reference: NXP UM10204 Rev 7.0 — Table 10
// System Clk: 50 MHz  →  20 ns per cycle
//
// NOTE: RTL implementation to be provided separately (FRS-I2C-001 v1.0).
//       All timing constants are parameterised here and imported by both
//       the RTL and the SVA assertions module (i2c_sva.sv).
//       DO NOT hard-code timing values anywhere else.
// =============================================================================

// ---------------------------------------------------------------------------
// Clock divider — Standard-mode 100 kHz SCL
//   SCL_freq = sys_clk / (2 × CLK_DIV_STD)
//   100 kHz  = 50 MHz  / (2 × 250)
// ---------------------------------------------------------------------------
parameter CLK_DIV_STD  = 250;

// ---------------------------------------------------------------------------
// Standard-mode timing minimums (in system clock cycles @ 50 MHz)
// UM10204 Table 10 values converted: t(ns) / 20 ns, rounded up
// ---------------------------------------------------------------------------
parameter T_HD_STA  = 200;   // START hold time         >= 4.0 µs  → 200 cyc
parameter T_LOW     = 235;   // SCL LOW  period         >= 4.7 µs  → 235 cyc
parameter T_HIGH    = 200;   // SCL HIGH period         >= 4.0 µs  → 200 cyc
parameter T_SU_STA  = 235;   // Repeated START setup    >= 4.7 µs  → 235 cyc
parameter T_HD_DAT  = 0;     // Data hold time          >= 0   ns  →   0 cyc
parameter T_SU_DAT  = 13;    // Data setup time         >= 250 ns  →  13 cyc
parameter T_SU_STO  = 200;   // STOP setup time         >= 4.0 µs  → 200 cyc
parameter T_BUF     = 235;   // Bus free time after STOP>= 4.7 µs  → 235 cyc

// ---------------------------------------------------------------------------
// Spike filter threshold (3-FF synchroniser chain)
// Glitches shorter than SPIKE_FILTER_NS are suppressed
// ---------------------------------------------------------------------------
parameter SPIKE_FILTER_CYC = 3;    // 3 clock cycles = 60 ns spike rejection

// ---------------------------------------------------------------------------
// Bus hang recovery
// ---------------------------------------------------------------------------
parameter RECOVERY_PULSES   = 9;   // SCL pulses to attempt SDA release
