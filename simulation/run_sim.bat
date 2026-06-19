@echo off
echo ========================================
echo  Compiling MMU + Testbench (Icarus Verilog)
echo ========================================

if not exist waveforms mkdir waveforms

iverilog -g2012 -o simulation\mmu_sim rtl\mmu.v tb\mmu_tb.v

if %ERRORLEVEL% NEQ 0 (
    echo Compilation failed. Check errors above.
    exit /b 1
)

echo Compilation successful
echo.
echo ========================================
echo  Running Simulation
echo ========================================

vvp simulation\mmu_sim

echo.
echo ========================================
echo  Simulation complete!
echo  Waveform saved at: waveforms\mmu_waveform.vcd
echo  View it with: gtkwave waveforms\mmu_waveform.vcd
echo ========================================