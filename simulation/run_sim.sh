#!/bin/bash
# ============================================================
# run_sim.sh — Compiles and runs the MMU simulation
# HOW TO RUN: bash simulation/run_sim.sh   (from project root)
# ============================================================

echo "========================================"
echo " Compiling MMU + Testbench (Icarus Verilog)"
echo "========================================"

# Create waveforms folder if it doesn't exist
mkdir -p waveforms

# Compile RTL + testbench into a simulation executable
iverilog -g2012 -o simulation/mmu_sim rtl/mmu.v tb/mmu_tb.v

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed. Check errors above."
    exit 1
fi

echo "✅ Compilation successful"
echo ""
echo "========================================"
echo " Running Simulation"
echo "========================================"

# Run the compiled simulation
vvp simulation/mmu_sim

echo ""
echo "========================================"
echo " Simulation complete!"
echo " Waveform saved at: waveforms/mmu_waveform.vcd"
echo " View it with: gtkwave waveforms/mmu_waveform.vcd"
echo "========================================"