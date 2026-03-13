// =============================================================================
// i2c_tb_top.sv — I²C UVM Testbench Top Module
//
// Responsibilities:
//   - Generate 50 MHz system clock (pclk) and synchronous reset (preset_n)
//   - Instantiate i2c_if with open-drain pullups on SDA and SCL
//   - Instantiate DUT stub (i2c_top) — TODO: connect actual ports when RTL provided
//   - Bind i2c_sva assertions to DUT
//   - Set uvm_config_db virtual interfaces for all agents
//   - Invoke run_test
// =============================================================================

`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

// Pull in the full TB package (all classes compiled in order)
`include "../test/i2c_pkg.sv"

module i2c_tb_top;

    // =========================================================================
    // Clock & Reset
    // =========================================================================
    parameter CLK_PERIOD = 20;   // 50 MHz → 20 ns period

    logic pclk;
    logic preset_n;

    // 50 MHz clock
    initial pclk = 1'b0;
    always #(CLK_PERIOD/2) pclk = ~pclk;

    // Synchronous, active-low reset — assert for 10 cycles then release
    initial begin
        preset_n = 1'b0;
        repeat(10) @(posedge pclk);
        @(negedge pclk);
        preset_n = 1'b1;
    end

    // =========================================================================
    // Interface Instantiation
    // Open-drain lines: pulled HIGH externally; drive LOW via tri-state logic
    // inside i2c_if.sv (assign sda = sda_slv_drv ? 1'bz : 1'b0)
    // =========================================================================
    wire sda;
    wire scl;

    // Pullup resistors (mimic physical 4.7 kΩ to VDD)
    pullup (strong1, highz0) pu_sda (sda);
    pullup (strong1, highz0) pu_scl (scl);

    i2c_if i2c_if_h (
        .pclk     (pclk),
        .preset_n (preset_n),
        .sda      (sda),
        .scl      (scl)
    );

    // =========================================================================
    // DUT Instantiation
    // TODO: Replace stub port connections with actual i2c_top port list
    //       when RTL and APB register map are provided.
    // =========================================================================
    i2c_top dut (
        // APB interface — TODO: connect to i2c_if APB signals
        .pclk        (pclk),
        .preset_n    (preset_n),
        .paddr       (i2c_if_h.paddr),
        .pwrite      (i2c_if_h.pwrite),
        .psel        (i2c_if_h.psel),
        .penable     (i2c_if_h.penable),
        .pwdata      (i2c_if_h.pwdata),
        .prdata      (i2c_if_h.prdata),
        .pready      (i2c_if_h.pready),
        .pslverr     (i2c_if_h.pslverr),

        // I²C bus
        .sda         (sda),
        .scl         (scl)

        // TODO: Add interrupt, stretch_en, irq, own_addr, gen_call_en ports
        //       once RTL port list is confirmed.
    );

    // =========================================================================
    // SVA Bind
    // Assertions in i2c_sva are bound to the DUT's I²C bus signals
    // =========================================================================
    bind i2c_top i2c_sva u_i2c_sva (
        .pclk     (pclk),
        .preset_n (preset_n),
        .sda      (sda),
        .scl      (scl)
    );

    // =========================================================================
    // UVM Config DB — Virtual Interface Distribution
    // =========================================================================
    initial begin
        // APB agent virtual interface
        uvm_config_db #(virtual i2c_if)::set(
            null, "uvm_test_top.env_h.agt_top_h.apb_agt_h.apb_drv_h",
            "APB_VIF", i2c_if_h
        );
        uvm_config_db #(virtual i2c_if)::set(
            null, "uvm_test_top.env_h.agt_top_h.apb_agt_h.apb_mon_h",
            "APB_VIF", i2c_if_h
        );

        // I²C agent virtual interface (slave driver + monitor)
        uvm_config_db #(virtual i2c_if)::set(
            null, "uvm_test_top.env_h.agt_top_h.i2c_agt_h.i2c_slv_drv_h",
            "I2C_VIF", i2c_if_h
        );
        uvm_config_db #(virtual i2c_if)::set(
            null, "uvm_test_top.env_h.agt_top_h.i2c_agt_h.i2c_mon_h",
            "I2C_VIF", i2c_if_h
        );

        // Proto monitor
        uvm_config_db #(virtual i2c_if)::set(
            null, "uvm_test_top.env_h.proto_mon_h",
            "I2C_VIF", i2c_if_h
        );

        // Run selected test (passed via +UVM_TESTNAME=<test_name>)
        run_test();
    end

    // =========================================================================
    // Simulation Timeout Guard
    // =========================================================================
    initial begin
        #5_000_000;  // 5 ms max simulation wall-clock
        `uvm_fatal("TB_TOP", "Simulation timeout — check DUT and test stimulus")
    end

endmodule : i2c_tb_top
