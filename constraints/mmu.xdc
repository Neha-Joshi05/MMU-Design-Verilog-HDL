## ============================================================
## mmu.xdc — Example Xilinx Constraints File
## PURPOSE: Maps MMU module ports to physical FPGA pins.
## NOTE: Pin numbers shown are for Nexys A7-100T — adjust for
##       your specific board's pinout from its reference manual.
## ============================================================

## Clock (100 MHz on Nexys A7)
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

## Reset button
set_property PACKAGE_PIN C12 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## Switches -> virtual_addr[7:0] (8 switches for 8-bit VA)
set_property PACKAGE_PIN J15 [get_ports {virtual_addr[0]}]
set_property PACKAGE_PIN L16 [get_ports {virtual_addr[1]}]
set_property PACKAGE_PIN M13 [get_ports {virtual_addr[2]}]
set_property PACKAGE_PIN R15 [get_ports {virtual_addr[3]}]
set_property PACKAGE_PIN R17 [get_ports {virtual_addr[4]}]
set_property PACKAGE_PIN T18 [get_ports {virtual_addr[5]}]
set_property PACKAGE_PIN U18 [get_ports {virtual_addr[6]}]
set_property PACKAGE_PIN R13 [get_ports {virtual_addr[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {virtual_addr[*]}]

## Push buttons -> access_read, access_write, enable
set_property PACKAGE_PIN N17 [get_ports access_read]
set_property PACKAGE_PIN M18 [get_ports access_write]
set_property PACKAGE_PIN P17 [get_ports enable]
set_property IOSTANDARD LVCMOS33 [get_ports {access_read access_write enable}]

## LEDs -> physical_addr[7:0]
set_property PACKAGE_PIN H17 [get_ports {physical_addr[0]}]
set_property PACKAGE_PIN K15 [get_ports {physical_addr[1]}]
set_property PACKAGE_PIN J13 [get_ports {physical_addr[2]}]
set_property PACKAGE_PIN N14 [get_ports {physical_addr[3]}]
set_property PACKAGE_PIN R18 [get_ports {physical_addr[4]}]
set_property PACKAGE_PIN V17 [get_ports {physical_addr[5]}]
set_property PACKAGE_PIN U17 [get_ports {physical_addr[6]}]
set_property PACKAGE_PIN U16 [get_ports {physical_addr[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {physical_addr[*]}]

## LEDs -> fault flags
set_property PACKAGE_PIN V16 [get_ports page_fault]
set_property PACKAGE_PIN T15 [get_ports protection_fault]
set_property PACKAGE_PIN U14 [get_ports translation_valid]
set_property IOSTANDARD LVCMOS33 [get_ports {page_fault protection_fault translation_valid}]