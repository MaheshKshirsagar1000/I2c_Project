// =============================================================================
// apb_xtn.sv — APB Transaction Class
// Represents one complete APB register access (write or read).
// Used by: apb_driver, apb_monitor, apb_sequence, scoreboard
// =============================================================================

class apb_xtn extends uvm_sequence_item;

    `uvm_object_utils(apb_xtn)

    // -------------------------------------------------------------------------
    // Transaction Fields
    // -------------------------------------------------------------------------
    rand logic [31:0] Paddr;      // Register address (word-aligned)
    rand logic        Pwrite;     // 1 = write, 0 = read
    rand logic [31:0] Pwdata;     // Write data (valid when Pwrite=1)
         logic [31:0] Prdata;     // Read data  (captured when Pwrite=0)
         logic        Pslverr;    // Slave error response

    // -------------------------------------------------------------------------
    // Constraints
    // -------------------------------------------------------------------------
    // Word-aligned address (lower 2 bits always 0)
    constraint word_align_c { Paddr[1:0] == 2'b00; }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    extern function new(string name = "apb_xtn");

    // -------------------------------------------------------------------------
    // UVM field methods
    // -------------------------------------------------------------------------
    extern function void      do_copy   (uvm_object rhs);
    extern function bit       do_compare(uvm_object rhs, uvm_comparer comparer);
    extern function string    convert2string();
    extern function void      do_print  (uvm_printer printer);

endclass : apb_xtn

// -----------------------------------------------------------------------------
function apb_xtn::new(string name = "apb_xtn");
    super.new(name);
endfunction : new

// -----------------------------------------------------------------------------
function void apb_xtn::do_copy(uvm_object rhs);
    apb_xtn rhs_;
    super.do_copy(rhs);
    if (!$cast(rhs_, rhs)) `uvm_fatal("APB_XTN", "do_copy cast failed")
    this.Paddr   = rhs_.Paddr;
    this.Pwrite  = rhs_.Pwrite;
    this.Pwdata  = rhs_.Pwdata;
    this.Prdata  = rhs_.Prdata;
    this.Pslverr = rhs_.Pslverr;
endfunction : do_copy

// -----------------------------------------------------------------------------
function bit apb_xtn::do_compare(uvm_object rhs, uvm_comparer comparer);
    apb_xtn rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (super.do_compare(rhs, comparer) &&
            (this.Paddr   === rhs_.Paddr)   &&
            (this.Pwrite  === rhs_.Pwrite)  &&
            (this.Pwdata  === rhs_.Pwdata)  &&
            (this.Prdata  === rhs_.Prdata));
endfunction : do_compare

// -----------------------------------------------------------------------------
function string apb_xtn::convert2string();
    return $sformatf(
        "APB_XTN: Paddr=0x%08h Pwrite=%0b Pwdata=0x%08h Prdata=0x%08h Pslverr=%0b",
        Paddr, Pwrite, Pwdata, Prdata, Pslverr);
endfunction : convert2string

// -----------------------------------------------------------------------------
function void apb_xtn::do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field_int("Paddr",   Paddr,   32, UVM_HEX);
    printer.print_field_int("Pwrite",  Pwrite,   1, UVM_BIN);
    printer.print_field_int("Pwdata",  Pwdata,  32, UVM_HEX);
    printer.print_field_int("Prdata",  Prdata,  32, UVM_HEX);
    printer.print_field_int("Pslverr", Pslverr,  1, UVM_BIN);
endfunction : do_print
