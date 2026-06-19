// ============================================================
// mmu.v — Memory Management Unit (Virtual → Physical Translation)
// PURPOSE: Translates an 8-bit virtual address into an 8-bit
//          physical address using a software-loaded page table.
// INTERVIEW TIP: "MMU sits between CPU and physical memory.
//                 CPU only ever sees virtual addresses — the
//                 MMU silently maps them to physical RAM."
// ============================================================

module mmu #(
    parameter VAW = 8,   // Virtual Address Width
    parameter PAW = 8,   // Physical Address Width
    parameter OFFSET_BITS = 4,                  // 16-byte pages
    parameter PAGES = (1 << (VAW - OFFSET_BITS)) // Number of pages = 2^(VAW-OFFSET)
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire             enable,        // 1 = perform translation
    input  wire [VAW-1:0]   virtual_addr,  // address from "CPU"
    input  wire             access_read,   // 1 = this is a read access
    input  wire             access_write,  // 1 = this is a write access

    output reg  [PAW-1:0]   physical_addr, // translated address
    output reg              page_fault,    // 1 = page not valid
    output reg              protection_fault, // 1 = permission denied
    output reg              translation_valid // 1 = successful translation
);

    // ── Page Table Entry (PTE) format ──────────────────────────
    // Bit layout (8 bits per entry):
    //   [7:4] = Frame Number (maps to physical page)
    //   [3]   = Valid bit      (1 = page exists in memory)
    //   [2]   = Read permission
    //   [1]   = Write permission
    //   [0]   = Reserved (future: execute permission)
    // INTERVIEW TIP: "This is a simplified PTE — real x86/ARM
    //                 PTEs also have dirty bit, accessed bit,
    //                 cache policy bits, etc."
    reg [7:0] page_table [0:PAGES-1];

    // ── Address breakdown ───────────────────────────────────────
    // Page Number = upper bits, Offset = lower bits
    wire [VAW-OFFSET_BITS-1:0] page_number = virtual_addr[VAW-1:OFFSET_BITS];
    wire [OFFSET_BITS-1:0]     offset      = virtual_addr[OFFSET_BITS-1:0];

    // ── Decode current PTE fields ──────────────────────────────
    wire [7:0] pte          = page_table[page_number];
    wire [3:0] frame_number = pte[7:4];
    wire       valid_bit    = pte[3];
    wire       read_perm    = pte[2];
    wire       write_perm   = pte[1];

    // ── Initialize page table with a demo mapping ──────────────
    // INTERVIEW TIP: "In a real OS, the kernel writes these
    //                 entries when a process is created. Here
    //                 we hardcode a demo mapping for simulation."
    integer i;
    initial begin
        for (i = 0; i < PAGES; i = i + 1)
            page_table[i] = 8'b0000_0000;  // all pages invalid by default

        // Page 0 -> Frame 5, valid, read+write
        page_table[0] = {4'd5, 1'b1, 1'b1, 1'b1, 1'b0};
        // Page 1 -> Frame 2, valid, read-only
        page_table[1] = {4'd2, 1'b1, 1'b1, 1'b0, 1'b0};
        // Page 2 -> Frame 9, valid, write-only (unusual but tests logic)
        page_table[2] = {4'd9, 1'b1, 1'b0, 1'b1, 1'b0};
        // Page 3 -> invalid (not mapped) -> triggers page fault
        page_table[3] = 8'b0000_0000;
        // Page 4 -> Frame 7, valid, read+write
        page_table[4] = {4'd7, 1'b1, 1'b1, 1'b1, 1'b0};
        // Remaining pages stay invalid (page fault if accessed)
    end

    // ── Translation logic (combinational + registered output) ──
    // INTERVIEW TIP: "We register the outputs so they're glitch
    //                 free and synchronized to the clock — common
    //                 practice in real MMU pipelines."
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            physical_addr     <= {PAW{1'b0}};
            page_fault         <= 1'b0;
            protection_fault   <= 1'b0;
            translation_valid  <= 1'b0;
        end
        else if (enable) begin
            // Step 1: Check valid bit
            if (!valid_bit) begin
                page_fault        <= 1'b1;
                protection_fault  <= 1'b0;
                translation_valid <= 1'b0;
                physical_addr     <= {PAW{1'b0}};
            end
            // Step 2: Check read permission
            else if (access_read && !read_perm) begin
                page_fault        <= 1'b0;
                protection_fault  <= 1'b1;
                translation_valid <= 1'b0;
                physical_addr     <= {PAW{1'b0}};
            end
            // Step 3: Check write permission
            else if (access_write && !write_perm) begin
                page_fault        <= 1'b0;
                protection_fault  <= 1'b1;
                translation_valid <= 1'b0;
                physical_addr     <= {PAW{1'b0}};
            end
            // Step 4: All checks passed -> generate physical address
            else begin
                page_fault        <= 1'b0;
                protection_fault  <= 1'b0;
                translation_valid <= 1'b1;
                // Physical Address = Frame Number concatenated with Offset
                physical_addr     <= {frame_number, offset};
            end
        end
        else begin
            // enable=0 -> no translation, outputs idle
            translation_valid <= 1'b0;
            page_fault         <= 1'b0;
            protection_fault   <= 1'b0;
        end
    end

endmodule