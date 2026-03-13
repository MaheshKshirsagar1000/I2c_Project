// =============================================================================
// i2c_monitor.sv — I²C Bus Monitor
//
// Passively decodes SDA/SCL waveform into complete i2c_xtn packets.
// Detects: START, STOP, Repeated-START, address byte, data bytes,
//          ACK/NACK on each byte, clock stretch, bus recovery pulses.
// Sends completed transactions to scoreboard via analysis port.
// Does NOT drive any bus signals.
// =============================================================================

class i2c_monitor extends uvm_monitor;

    `uvm_component_utils(i2c_monitor)

    i2c_agt_config  agt_cfg;
    virtual i2c_if.I2C_MON_MP vif;

    // Analysis port → scoreboard and protocol monitor
    uvm_analysis_port #(i2c_xtn) i2c_analysis_port;

    extern function new(string name = "i2c_monitor", uvm_component parent);
    extern function void build_phase  (uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task          run_phase    (uvm_phase phase);

    // Internal decode tasks
    extern task wait_for_start    (output logic is_repeated);
    extern task decode_byte       (output logic [7:0] data,
                                   output logic       ack_nack);
    extern task check_stop        (output logic is_stop);
    extern task measure_timing    (i2c_xtn xtn);

endclass : i2c_monitor

// -----------------------------------------------------------------------------
function i2c_monitor::new(string name = "i2c_monitor", uvm_component parent);
    super.new(name, parent);
endfunction : new

// -----------------------------------------------------------------------------
function void i2c_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(i2c_agt_config)::get(this, "", "i2c_agt_config", agt_cfg))
        `uvm_fatal("I2C_MON", "GET of i2c_agt_config failed")
    i2c_analysis_port = new("i2c_analysis_port", this);
endfunction : build_phase

// -----------------------------------------------------------------------------
function void i2c_monitor::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vif = agt_cfg.vif;
endfunction : connect_phase

// -----------------------------------------------------------------------------
task i2c_monitor::run_phase(uvm_phase phase);
    i2c_xtn xtn;
    logic [7:0] byte_val;
    logic       ack_bit;
    logic       is_repeated_start;
    logic       is_stop;

    @(posedge vif.rst_n);  // Wait for reset release

    forever begin
        xtn = i2c_xtn::type_id::create("xtn");
        xtn.ack      = new[0];
        xtn.rx_data  = new[0];

        // ---------------------------------------------------------
        // Wait for START or repeated START condition
        // ---------------------------------------------------------
        wait_for_start(is_repeated_start);
        xtn.start_detected  = 1'b1;
        xtn.sr_detected     = is_repeated_start;
        xtn.bus_state_at_start = (vif.busy) ? BUS_BUSY : BUS_FREE;

        // Record START time for t_BUF measurement
        // (proto_mon handles precise timing measurement)

        // ---------------------------------------------------------
        // Decode address byte (7 bits address + R/W bit)
        // ---------------------------------------------------------
        decode_byte(byte_val, ack_bit);
        xtn.addr       = byte_val[7:1];
        xtn.rw         = byte_val[0];
        xtn.ack        = new[1] (xtn.ack);
        xtn.ack[0]     = ack_bit;           // ACK/NACK on address phase

        if (ack_bit == 1'b1) begin
            // Address NACK — no device responded (FR-ERR-006a)
            xtn.nack_det   = 1'b1;
            xtn.nack_cause = NACK_NO_DEVICE;
        end

        // ---------------------------------------------------------
        // Decode data bytes until STOP or repeated START
        // ---------------------------------------------------------
        xtn.byte_cnt = 0;
        if (ack_bit == 1'b0) begin
            // Address ACK received — proceed to data phase
            forever begin
                check_stop(is_stop);
                if (is_stop || xtn.sr_detected) break;

                decode_byte(byte_val, ack_bit);
                xtn.byte_cnt++;

                if (xtn.rw == 1'b0) begin
                    // Write: controller sent data
                    xtn.tx_data = new[xtn.byte_cnt] (xtn.tx_data);
                    xtn.tx_data[xtn.byte_cnt-1] = byte_val;
                end else begin
                    // Read: slave sent data
                    xtn.rx_data = new[xtn.byte_cnt] (xtn.rx_data);
                    xtn.rx_data[xtn.byte_cnt-1] = byte_val;
                end

                xtn.ack = new[xtn.byte_cnt + 1] (xtn.ack);
                xtn.ack[xtn.byte_cnt] = ack_bit;

                if (ack_bit == 1'b1 && xtn.rw == 1'b0) begin
                    // NACK on data byte during write
                    xtn.nack_det = 1'b1;
                    if (xtn.nack_cause == NACK_NONE)
                        xtn.nack_cause = NACK_TARGET_BUSY;
                end
            end
        end

        // ---------------------------------------------------------
        // Record STOP/Sr condition
        // ---------------------------------------------------------
        xtn.stop_detected   = vif.stop_cond;
        xtn.recovery_detected = vif.recovery_active;
        xtn.recovery_pulses   = vif.recovery_cnt;
        xtn.stretch_detected  = vif.scl_slv_drv ? 1'b0 : 1'b1;

        `uvm_info("I2C_MON", $sformatf("\n%s", xtn.convert2string()), UVM_MEDIUM)
        i2c_analysis_port.write(xtn);
    end
endtask : run_phase

// -----------------------------------------------------------------------------
// Wait for START condition: SDA H→L while SCL HIGH
// is_repeated = 1 if this was a repeated START (bus was BUSY before)
task i2c_monitor::wait_for_start(output logic is_repeated);
    is_repeated = vif.busy;  // If bus was BUSY, this is a repeated START
    @(negedge vif.sda iff (vif.scl === 1'b1));
    `uvm_info("I2C_MON",
        $sformatf("%0s START detected", is_repeated ? "REPEATED" : "NORMAL"),
        UVM_HIGH)
endtask : wait_for_start

// -----------------------------------------------------------------------------
// Decode 8 bits (MSB first) + capture ACK/NACK on 9th SCL pulse
task i2c_monitor::decode_byte(output logic [7:0] data, output logic ack_nack);
    for (int i = 7; i >= 0; i--) begin
        @(posedge vif.scl);   // sample SDA on rising SCL
        data[i] = vif.sda;
        @(negedge vif.scl);
    end
    // 9th clock: ACK=0 (SDA LOW), NACK=1 (SDA HIGH)
    @(posedge vif.scl);
    ack_nack = vif.sda;  // 0=ACK, 1=NACK
    @(negedge vif.scl);
endtask : decode_byte

// -----------------------------------------------------------------------------
// After falling SCL edge — check if STOP (SDA L→H while SCL HIGH)
// or repeated START (SDA H→L while SCL HIGH) is about to happen
task i2c_monitor::check_stop(output logic is_stop);
    // Brief window: watch for SDA change while SCL goes HIGH
    // Using a fork-join_any to detect either next byte start or STOP/Sr
    fork
        begin : stop_watch
            @(posedge vif.scl);
            if (vif.sda == 1'b0) begin
                @(posedge vif.sda iff (vif.scl === 1'b1));
                is_stop = 1'b1;
                disable next_byte_watch;
            end else begin
                is_stop = 1'b0;
                disable stop_watch;
            end
        end
        begin : next_byte_watch
            // No STOP — SCL went high with SDA low (data bit)
            is_stop = 1'b0;
            disable stop_watch;
        end
    join_any
endtask : check_stop

// -----------------------------------------------------------------------------
task i2c_monitor::measure_timing(i2c_xtn xtn);
    // Timing measurements are delegated to proto_mon.sv
    // which has more precise $realtime tracking
    // This task is a placeholder for future direct timing capture
endtask : measure_timing
