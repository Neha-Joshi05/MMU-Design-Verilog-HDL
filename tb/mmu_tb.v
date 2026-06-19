// ============================================================
// mmu_tb.v — Self-Checking Testbench for MMU
// PURPOSE: Drives various virtual addresses + access types and
//          verifies correct translation, page faults, and
//          protection faults using $display and assertions.
// HOW TO RUN: see simulation/run_sim.sh
// ============================================================

`timescale 1ns/1ps

module mmu_tb;

    // ── DUT signals ──────────────────────────────────────────
    reg        clk;
    reg        rst_n;
    reg        enable;
    reg  [7:0] virtual_addr;
    reg        access_read;
    reg        access_write;

    wire [7:0] physical_addr;
    wire       page_fault;
    wire       protection_fault;
    wire       translation_valid;

    integer    test_num;
    integer    pass_count;
    integer    fail_count;

    // ── Instantiate DUT (Device Under Test) ─────────────────────
    mmu #(
        .VAW(8),
        .PAW(8),
        .OFFSET_BITS(4)
    ) DUT (
        .clk               (clk),
        .rst_n             (rst_n),
        .enable            (enable),
        .virtual_addr      (virtual_addr),
        .access_read       (access_read),
        .access_write      (access_write),
        .physical_addr     (physical_addr),
        .page_fault        (page_fault),
        .protection_fault  (protection_fault),
        .translation_valid (translation_valid)
    );

    // ── Clock generation: 10ns period (100 MHz) ─────────────────
    always #5 clk = ~clk;

    // ── Self-check task ──────────────────────────────────────
    // INTERVIEW TIP: "A self-checking testbench compares actual
    //                 vs expected automatically — no manual
    //                 waveform inspection needed to know PASS/FAIL."
    task run_test(
        input [7:0]  va,
        input        rd,
        input        wr,
        input [7:0]  expected_pa,
        input        expect_pf,     // expect page fault
        input        expect_prot,   // expect protection fault
        input        expect_valid,  // expect successful translation
        input [127:0] test_name
    );
        begin
            test_num = test_num + 1;
            virtual_addr = va;
            access_read  = rd;
            access_write = wr;
            enable       = 1'b1;

            @(posedge clk);
            @(posedge clk); // wait one extra cycle for registered output

            if (page_fault === expect_pf &&
                protection_fault === expect_prot &&
                translation_valid === expect_valid &&
                (!expect_valid || physical_addr === expected_pa)) begin
                $display("[TEST %0d] PASS - %s", test_num, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("[TEST %0d] FAIL - %s", test_num, test_name);
                $display("    VA=%h RD=%b WR=%b", va, rd, wr);
                $display("    Expected: PA=%h PF=%b PROT=%b VALID=%b",
                          expected_pa, expect_pf, expect_prot, expect_valid);
                $display("    Got:      PA=%h PF=%b PROT=%b VALID=%b",
                          physical_addr, page_fault, protection_fault, translation_valid);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ── Test sequence ─────────────────────────────────────────
    initial begin
        // Setup waveform dump
        $dumpfile("waveforms/mmu_waveform.vcd");
        $dumpvars(0, mmu_tb);

        clk          = 0;
        rst_n        = 0;
        enable       = 0;
        virtual_addr = 0;
        access_read  = 0;
        access_write = 0;
        test_num     = 0;
        pass_count   = 0;
        fail_count   = 0;

        // Apply reset
        #12 rst_n = 1;
        @(posedge clk);

        $display("\n========================================");
        $display(" MMU Verification — Starting Test Suite");
        $display("========================================\n");

        // ── TEST 1: Valid translation, Page 0, Read access ──────
        // Page 0 -> Frame 5, offset 0x3 -> PA = {5, 3} = 0x53
        run_test(8'h03, 1'b1, 1'b0, 8'h53, 1'b0, 1'b0, 1'b1,
                  "Valid read - Page 0 (Frame 5)");

        // ── TEST 2: Valid translation, Page 1, Read access ──────
        // Page 1 -> Frame 2, offset 0x7 -> PA = {2, 7} = 0x27
        run_test(8'h17, 1'b1, 1'b0, 8'h27, 1'b0, 1'b0, 1'b1,
                  "Valid read - Page 1 (Frame 2, read-only)");

        // ── TEST 3: Protection fault - write to read-only page ──
        // Page 1 is read-only; writing should trigger protection fault
        run_test(8'h12, 1'b0, 1'b1, 8'h00, 1'b0, 1'b1, 1'b0,
                  "Protection fault - Write to read-only Page 1");

        // ── TEST 4: Valid translation, Page 2, Write access ─────
        // Page 2 -> Frame 9, offset 0x4 -> PA = {9, 4} = 0x94
        run_test(8'h24, 1'b0, 1'b1, 8'h94, 1'b0, 1'b0, 1'b1,
                  "Valid write - Page 2 (Frame 9, write-only)");

        // ── TEST 5: Protection fault - read from write-only page ─
        run_test(8'h21, 1'b1, 1'b0, 8'h00, 1'b0, 1'b1, 1'b0,
                  "Protection fault - Read from write-only Page 2");

        // ── TEST 6: Page fault - unmapped Page 3 ─────────────────
        run_test(8'h35, 1'b1, 1'b0, 8'h00, 1'b1, 1'b0, 1'b0,
                  "Page fault - Page 3 not valid (unmapped)");

        // ── TEST 7: Valid translation, Page 4, Write access ──────
        // Page 4 -> Frame 7, offset 0xF -> PA = {7, F} = 0x7F
        run_test(8'h4F, 1'b0, 1'b1, 8'h7F, 1'b0, 1'b0, 1'b1,
                  "Valid write - Page 4 (Frame 7)");

        // ── TEST 8: Boundary address - Page 0, max offset ───────
        // Page 0 -> Frame 5, offset 0xF -> PA = {5, F} = 0x5F
        run_test(8'h0F, 1'b1, 1'b0, 8'h5F, 1'b0, 1'b0, 1'b1,
                  "Boundary test - Page 0 max offset (0xF)");

        // ── TEST 9: Page fault - unmapped Page 15 (highest page) ─
        run_test(8'hF0, 1'b1, 1'b0, 8'h00, 1'b1, 1'b0, 1'b0,
                  "Page fault - Page 15 not valid (highest page)");

        // ── TEST 10: Enable = 0, no translation should occur ─────
        enable = 1'b0;
        @(posedge clk);
        @(posedge clk);
        test_num = test_num + 1;
        if (translation_valid === 1'b0 && page_fault === 1'b0 &&
            protection_fault === 1'b0) begin
            $display("[TEST %0d] PASS - Disabled MMU produces no translation", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[TEST %0d] FAIL - Disabled MMU should be idle", test_num);
            fail_count = fail_count + 1;
        end

        // ── Final Summary ────────────────────────────────────────
        $display("\n========================================");
        $display(" TEST SUMMARY");
        $display("========================================");
        $display(" Total Tests : %0d", test_num);
        $display(" Passed      : %0d", pass_count);
        $display(" Failed      : %0d", fail_count);
        if (fail_count == 0)
            $display(" RESULT      : ALL TESTS PASSED ✅");
        else
            $display(" RESULT      : %0d TEST(S) FAILED ❌", fail_count);
        $display("========================================\n");

        #20 $finish;
    end

endmodule