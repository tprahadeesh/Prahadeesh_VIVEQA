## Xilinx Vivado Pin Constraints Template for xc7a35tftg256-1
## -------------------------------------------------------------

# System Clock Input (24MHz clock oscillator)
set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 41.667 -name sys_clk_pin -waveform {0.000 20.833} -add [get_ports clk]

# Generated clock for the divided CPU clock (clk_div[23])
create_generated_clock -name cpu_clk -source [get_ports clk] -divide_by 16777216 [get_nets clk_div[23]]

# Reset Button (Active-Low)

set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports reset_n]

# 8 Output LEDs (used to display PC[9:2])
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports {leds[0]}]
set_property -dict {PACKAGE_PIN A3 IOSTANDARD LVCMOS33} [get_ports {leds[1]}]
set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS33} [get_ports {leds[2]}]
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports {leds[3]}]
set_property -dict {PACKAGE_PIN E6 IOSTANDARD LVCMOS33} [get_ports {leds[4]}]
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports {leds[5]}]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports {leds[6]}]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports {leds[7]}]


create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 8192 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_IBUF_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {mem_addr[0]} {mem_addr[1]} {mem_addr[2]} {mem_addr[3]} {mem_addr[4]} {mem_addr[5]} {mem_addr[6]} {mem_addr[7]} {mem_addr[8]} {mem_addr[9]} {mem_addr[10]} {mem_addr[11]} {mem_addr[12]} {mem_addr[13]} {mem_addr[14]} {mem_addr[15]} {mem_addr[16]} {mem_addr[17]} {mem_addr[18]} {mem_addr[19]} {mem_addr[20]} {mem_addr[21]} {mem_addr[22]} {mem_addr[23]} {mem_addr[24]} {mem_addr[25]} {mem_addr[26]} {mem_addr[27]} {mem_addr[28]} {mem_addr[29]} {mem_addr[30]} {mem_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 32 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {mem_wd[0]} {mem_wd[1]} {mem_wd[2]} {mem_wd[3]} {mem_wd[4]} {mem_wd[5]} {mem_wd[6]} {mem_wd[7]} {mem_wd[8]} {mem_wd[9]} {mem_wd[10]} {mem_wd[11]} {mem_wd[12]} {mem_wd[13]} {mem_wd[14]} {mem_wd[15]} {mem_wd[16]} {mem_wd[17]} {mem_wd[18]} {mem_wd[19]} {mem_wd[20]} {mem_wd[21]} {mem_wd[22]} {mem_wd[23]} {mem_wd[24]} {mem_wd[25]} {mem_wd[26]} {mem_wd[27]} {mem_wd[28]} {mem_wd[29]} {mem_wd[30]} {mem_wd[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list dmem_we_actual]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_IBUF_BUFG]
