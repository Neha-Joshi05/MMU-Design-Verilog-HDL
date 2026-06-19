# ============================================================
# app.py — Flask Dashboard for MMU Virtual->Physical Translator
# HOW TO RUN: python dashboard/app.py
# Open: http://localhost:5000
# ============================================================

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flask import Flask, render_template, request, jsonify
from mmu_model import translate, get_page_table_view, VAW, PAW, OFFSET_BITS

app = Flask(__name__)


@app.route("/")
def index():
    return render_template("index.html",
                            page_table=get_page_table_view(),
                            vaw=VAW, paw=PAW, offset_bits=OFFSET_BITS)


@app.route("/api/translate", methods=["POST"])
def api_translate():
    data = request.get_json()

    try:
        va_str = data.get("virtual_addr", "0").strip()
        # Accept hex (0x..) or decimal input
        virtual_addr = int(va_str, 16) if va_str.lower().startswith("0x") else int(va_str, 16)
    except ValueError:
        return jsonify({"error": "Invalid virtual address format"}), 400

    if virtual_addr < 0 or virtual_addr > (1 << VAW) - 1:
        return jsonify({"error": f"Address must be between 0x00 and 0x{(1<<VAW)-1:02X}"}), 400

    access_read  = bool(data.get("access_read", False))
    access_write = bool(data.get("access_write", False))

    result = translate(virtual_addr, access_read, access_write)

    # Format for JSON response
    response = {
        "virtual_addr_hex":  f"0x{result['virtual_addr']:02X}",
        "page_number":       result["page_number"],
        "offset_hex":        f"0x{result['offset']:01X}",
        "pte":               result["pte"],
        "page_fault":        result["page_fault"],
        "protection_fault":  result["protection_fault"],
        "translation_valid": result["translation_valid"],
        "physical_addr_hex": f"0x{result['physical_addr']:02X}" if result["physical_addr"] is not None else None,
    }

    return jsonify(response)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)