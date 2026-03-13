// =============================================================================
// i2c_slave_driver.sv — I²C Slave (Target) Behavioural Driver
//
// Emulates an I²C target device on the SDA/SCL open-drain bus.
// Behaviour:
//   - Monitors bus for START condition
//   - Decodes 7-bit address + R/W bit from SDA on rising SCL edges
//   - If address matches own_addr (or gen_call_en + 0x00), drives ACK
//   - Write path: ACKs each received data byte
//   - Read  path: Drives data bytes MSB-first; controller ACKs/NACKs
//   - Clock stretch: holds SCL LOW for stretch_cycles after ACK if stretch_en
//   - Error injection: drives NACK on specific conditions per i2c_xtn.nack_cause
//
// Open-drain model:
//   sda_slv_drv = 1 → release (bus → HIGH via pullup)
//   sda_slv_drv = 0 → assert  (bus → LOW, dominant)
//   scl_slv_drv = 0 → hold SCL LOW (clock stretching)
// =============================================================================

class i2c_slave_driver extends uvm_driver #(i2c_xtn);

    `uvm_component_utils(i2c_slave_driver)

    i2c_agt_config  agt_cfg;
    virtual i2c_if.I2C_SLV_MP vif;

    extern function new(string name = "i2c_slave_driver", uvm_component parent);
    extern function void build_phase  (uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task          run_phase    (uvm_phase phase);

    // Internal slave tasks
    extern task wait_for_start;
    extern task receive_address (output logic [6:0] addr_rcv,
                                 output logic       rw_rcv);
    extern task drive_ack       (input logic nack);
    extern task receive_byte    (output logic [7:0] data);
    extern task drive_byte      (input  logic [7:0] data);
    extern task clock_stretch   (input  int cycles);
    extern task idle_bus;

endclass : i2c_slave_driver

// -----------------------------------------------------------------------------
function i2c_slave_driver::new(string name = "i2c_slave_driver",
                                uvm_component parent);
    super.new(name, parent);
endfunction : new

// -----------------------------------------------------------------------------
function void i2c_slave_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(i2c_agt_config)::get(this, "", "i2c_agt_config", agt_cfg))
        `uvm_fatal("I2C_SLV_DRV", "GET of i2c_agt_config failed")
endfunction : build_phase

// -----------------------------------------------------------------------------
function void i2c_slave_driver::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vif = agt_cfg.vif;
endfunction : connect_phase

// -----------------------------------------------------------------------------
task i2c_slave_driver::idle_bus;
    vif.sda_slv_drv <= 1'b1;  // release SDA
    vif.scl_slv_drv <= 1'b1;  // release SCL
endtask : idle_bus

// -----------------------------------------------------------------------------
task i2c_slave_driver::run_phase(uvm_phase phase);
    logic [6:0] rcv_addr;
    logic       rcv_rw;
    logic [7:0] byte_data;
    i2c_xtn     req_item;

    idle_bus();
    @(posedge vif.rst_n);  // Wait for reset de-assertion

    forever begin
        // Get next slave configuration from sequence
        seq_item_port.get_next_item(req_item);
        `uvm_info("I2C_SLV_DRV",
            $sformatf("Slave configured: own_addr=7'h%02h rw=%0b byte_cnt=%0d",
                agt_cfg.own_addr, req_item.rw, req_item.byte_cnt), UVM_MEDIUM)

        // Wait for START condition from controller
        wait_for_start();

        // Receive address byte (7 bits + R/W)
        receive_address(rcv_addr, rcv_rw);

        // Check address match
        if ((rcv_addr == agt_cfg.own_addr) ||
            (agt_cfg.gen_call_en && rcv_addr == 7'h00)) begin

            // Address matched — drive ACK on 9th SCL pulse
            drive_ack(1'b0);  // ACK = SDA LOW

            // Optional clock stretch after address ACK
            if (agt_cfg.stretch_en && req_item.stretch_cycles > 0)
                clock_stretch(req_item.stretch_cycles);

            if (rcv_rw == 1'b0) begin
                // -------------------------------------------------------
                // WRITE path: receive data bytes from controller
                // -------------------------------------------------------
                for (int b = 0; b < req_item.byte_cnt; b++) begin
                    receive_byte(byte_data);
                    req_item.rx_data = new[req_item.rx_data.size() + 1]
                                           (req_item.rx_data);
                    req_item.rx_data[b] = byte_data;

                    // Drive NACK on specific conditions
                    if (req_item.nack_cause == NACK_OVERFLOW  && b == req_item.byte_cnt - 1)
                        drive_ack(1'b1);  // NACK = SDA HIGH
                    else if (req_item.nack_cause == NACK_BAD_CMD && b == 0)
                        drive_ack(1'b1);  // NACK first byte (bad command)
                    else if (req_item.nack_cause == NACK_TARGET_BUSY)
                        drive_ack(1'b1);  // NACK all bytes (target busy)
                    else
                        drive_ack(1'b0);  // ACK
                end

            end else begin
                // -------------------------------------------------------
                // READ path: drive data bytes to controller
                // -------------------------------------------------------
                for (int b = 0; b < req_item.byte_cnt; b++) begin
                    logic [7:0] tx_byte;
                    tx_byte = (req_item.tx_data.size() > b) ?
                              req_item.tx_data[b] : agt_cfg.rx_buf_data;
                    drive_byte(tx_byte);

                    // Wait for controller ACK/NACK on 9th pulse
                    @(posedge vif.scl);
                    @(negedge vif.scl);
                    idle_bus(); // release SDA after byte
                end
            end

        end else begin
            // Address mismatch — release bus (no ACK = NACK by non-response)
            drive_ack(1'b1);  // NACK: SDA stays HIGH
            `uvm_info("I2C_SLV_DRV",
                $sformatf("Address mismatch: rcv=7'h%02h own=7'h%02h",
                    rcv_addr, agt_cfg.own_addr), UVM_HIGH)
        end

        idle_bus();
        seq_item_port.item_done();
    end
endtask : run_phase

// -----------------------------------------------------------------------------
// Wait for START condition: SDA falls while SCL is HIGH
task i2c_slave_driver::wait_for_start;
    @(negedge vif.sda iff (vif.scl === 1'b1));
    `uvm_info("I2C_SLV_DRV", "START detected", UVM_HIGH)
endtask : wait_for_start

// -----------------------------------------------------------------------------
// Receive 7-bit address + R/W bit (8 bits, MSB first on rising SCL)
task i2c_slave_driver::receive_address(output logic [6:0] addr_rcv,
                                        output logic       rw_rcv);
    logic [7:0] addr_byte;
    for (int i = 7; i >= 0; i--) begin
        @(posedge vif.scl);
        addr_byte[i] = vif.sda;
    end
    addr_rcv = addr_byte[7:1];
    rw_rcv   = addr_byte[0];
    @(negedge vif.scl);
    `uvm_info("I2C_SLV_DRV",
        $sformatf("Address byte received: 7'h%02h rw=%0b", addr_rcv, rw_rcv),
        UVM_HIGH)
endtask : receive_address

// -----------------------------------------------------------------------------
// Drive ACK or NACK on the 9th SCL pulse (SDA already SCL-LOW after 8 bits)
// nack=0 → ACK (pull SDA LOW); nack=1 → NACK (release SDA HIGH)
task i2c_slave_driver::drive_ack(input logic nack);
    // SCL is currently LOW (after 8th bit negedge)
    vif.sda_slv_drv <= ~nack;  // 0=pull low (ACK), 1=release (NACK)
    @(posedge vif.scl);        // 9th SCL rising edge
    @(negedge vif.scl);        // 9th SCL falling edge
    vif.sda_slv_drv <= 1'b1;  // release SDA after ACK/NACK
endtask : drive_ack

// -----------------------------------------------------------------------------
// Receive one 8-bit data byte from the bus (controller drives SDA)
task i2c_slave_driver::receive_byte(output logic [7:0] data);
    for (int i = 7; i >= 0; i--) begin
        @(posedge vif.scl);
        data[i] = vif.sda;
    end
    @(negedge vif.scl);
endtask : receive_byte

// -----------------------------------------------------------------------------
// Drive one 8-bit data byte onto the bus (slave drives SDA, MSB first)
task i2c_slave_driver::drive_byte(input logic [7:0] data);
    for (int i = 7; i >= 0; i--) begin
        vif.sda_slv_drv <= ~data[i];  // 0=pull low for '1', 1=release for '0'
        // Note: open-drain — to drive '1' we release (pull-up takes it HIGH)
        //       to drive '0' we assert (pull bus LOW)
        @(posedge vif.scl);
        @(negedge vif.scl);
    end
    vif.sda_slv_drv <= 1'b1;  // release SDA for ACK window
endtask : drive_byte

// -----------------------------------------------------------------------------
// Hold SCL LOW for 'cycles' system clock cycles (clock stretching)
task i2c_slave_driver::clock_stretch(input int cycles);
    `uvm_info("I2C_SLV_DRV",
        $sformatf("Clock stretching for %0d cycles", cycles), UVM_MEDIUM)
    vif.scl_slv_drv <= 1'b0;   // hold SCL LOW
    repeat (cycles) @(posedge vif.pclk);
    vif.scl_slv_drv <= 1'b1;   // release SCL (controller can proceed)
endtask : clock_stretch
