//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.11 Education
//Created Time: 2023-10-31 20:28:45
create_clock -name clk_shift -period 7.407 -waveform {0 1.25} [get_nets {clk_shift}]
create_clock -name clk_pixel -period 37.037 -waveform {0 1.25} [get_nets {clk_pixel}]
create_clock -name clk_27mhz -period 37.037 -waveform {0 18.518} [get_ports {clk_27mhz}]
create_clock -name clk32 -period 31.746 -waveform {0 5} [get_nets {clk32}]
create_clock -name spi_clk -period 63.492 -waveform {0 5} [get_nets {c1541_sd/sd_spi/spi_clk}] -add
set_clock_groups -asynchronous -group [get_clocks {spi_clk}] -group [get_clocks {clk_pixel}] -group [get_clocks {clk32}] -group [get_clocks {clk_shift}] -group [get_clocks {clk_27mhz}]
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1



