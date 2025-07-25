//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10.03 (64-bit) 
//Created Time: 2025-01-12 22:49:11
create_clock -name clk -period 37.037 -waveform {0 18.5} [get_ports {clk}] -add
create_generated_clock -name clk_pixel_x10 -source [get_ports {clk}] -master_clock clk -divide_by 3 -multiply_by 35 [get_pins {mainclock/CLKOUT}]
create_generated_clock -name mspi_clk -source [get_ports {clk}] -master_clock clk -divide_by 7 -multiply_by 26 -duty_cycle 50 -phase 135 [get_pins {flashclock/CLKOUTP}]
create_generated_clock -name flash_clk -source [get_ports {clk}] -master_clock clk -divide_by 7 -multiply_by 26 [get_pins {flashclock/CLKOUT}]
create_generated_clock -name clk_pixel_x5 -source [get_ports {clk}] -master_clock clk -divide_by 6 -multiply_by 35 [get_pins {mainclock/CLKOUTD}]
create_generated_clock -name clk64 -source [get_pins {mainclock/CLKOUT}] -master_clock clk_pixel_x10 -divide_by 5 -multiply_by 1 [get_pins {div1_inst/CLKOUT}]
create_generated_clock -name clk32 -source [get_pins {div1_inst/CLKOUT}] -master_clock clk64 -divide_by 2 -multiply_by 1 [get_pins {div2_inst/CLKOUT}]
create_clock -name m0sclk -period 50 -waveform {0 25} [get_ports {spi_sclk}] -add
set_clock_groups -asynchronous -group [get_clocks {flash_clk}] -group [get_clocks {clk32}]
set_clock_groups -asynchronous -group [get_clocks {clk32}] -group [get_clocks {m0sclk}]
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1


