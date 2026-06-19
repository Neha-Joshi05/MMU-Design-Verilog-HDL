# ============================================================
# mmu_model.py — Python Model of the MMU (mirrors rtl/mmu.v)
# PURPOSE: Re-implements the exact same page table and
#          translation logic as the Verilog RTL, so the
#          dashboard behavior matches the hardware design.
# INTERVIEW TIP: "I built a Python golden model of my RTL to
#                 power a visual dashboard — this is the same
#                 idea as a C++/Python reference model used in
#                 real verification environments (UVM scoreboard)."
# ============================================================

VAW = 8            # Virtual Address Width
PAW = 8             # Physical Address Width
OFFSET_BITS = 4      # 16-byte pages
PAGE_BITS = VAW - OFFSET_BITS
NUM_PAGES = 1 << PAGE_BITS   # 16 pages

# ── Page Table — IDENTICAL mapping to rtl/mmu.v initial block ──
# Format per entry: { frame, valid, read, write }
PAGE_TABLE = {i: {"frame": 0, "valid": False, "read": False, "write": False}
              for i in range(NUM_PAGES)}

PAGE_TABLE[0] = {"frame": 5, "valid": True,  "read": True,  "write": True}   # RW
PAGE_TABLE[1] = {"frame": 2, "valid": True,  "read": True,  "write": False}  # Read-only
PAGE_TABLE[2] = {"frame": 9, "valid": True,  "read": False, "write": True}   # Write-only
PAGE_TABLE[3] = {"frame": 0, "valid": False, "read": False, "write": False} # Unmapped
PAGE_TABLE[4] = {"frame": 7, "valid": True,  "read": True,  "write": True}   # RW
# Pages 5-15 remain unmapped (valid=False) — page faults if accessed


def translate(virtual_addr: int, access_read: bool, access_write: bool) -> dict:
    """
    Performs virtual -> physical address translation.
    Mirrors the always block in rtl/mmu.v exactly.
    """
    page_number = (virtual_addr >> OFFSET_BITS) & (NUM_PAGES - 1)
    offset      = virtual_addr & ((1 << OFFSET_BITS) - 1)

    pte = PAGE_TABLE[page_number]

    result = {
        "virtual_addr":      virtual_addr,
        "page_number":       page_number,
        "offset":            offset,
        "pte":               pte,
        "physical_addr":     None,
        "page_fault":        False,
        "protection_fault":  False,
        "translation_valid": False,
    }

    # Step 1: Valid bit check
    if not pte["valid"]:
        result["page_fault"] = True
        return result

    # Step 2: Read permission check
    if access_read and not pte["read"]:
        result["protection_fault"] = True
        return result

    # Step 3: Write permission check
    if access_write and not pte["write"]:
        result["protection_fault"] = True
        return result

    # Step 4: Success — generate physical address
    physical_addr = (pte["frame"] << OFFSET_BITS) | offset
    result["physical_addr"]     = physical_addr
    result["translation_valid"] = True
    return result


def get_page_table_view() -> list:
    """Returns the full page table formatted for dashboard display."""
    rows = []
    for page_num, pte in PAGE_TABLE.items():
        rows.append({
            "page_number": page_num,
            "frame":       pte["frame"],
            "valid":       pte["valid"],
            "read":        pte["read"],
            "write":       pte["write"],
        })
    return rows