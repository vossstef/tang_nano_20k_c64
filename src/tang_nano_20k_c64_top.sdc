//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.9 Beta-4 Education
//Created Time: 2024-02-11 11:55:51
create_clock -name clk64 -period 15.873 -waveform {0 5} [get_nets {clk64}]
create_clock -name clk32 -period 31.746 -waveform {0 5} [get_nets {clk32}]
create_clock -name ds2_clk -period 8000 -waveform {0 5} [get_nets {gamepad/clk_spi}]
create_clock -name clk_27mhz -period 37.037 -waveform {0 18.518} [get_ports {clk_27mhz}]
create_clock -name joymiso -period 8000 -waveform {0 20} [get_ports {joystick_miso}]
create_clock -name spibl -period 50 -waveform {0 20} [get_nets {mcu_spi_inst/n4_24}]
create_clock -name clk_pix -period 37.037 -waveform {0 1.25} [get_nets {video_inst/clk_pixel}] -add
create_clock -name clk_pixel_x5 -period 7.407 -waveform {0 1.25} [get_nets {video_inst/clk_pixel_x5}] -add
create_clock -name clk_audio -period 20833.332 -waveform {0 5} [get_nets {video_inst/clk_audio}] -add
create_clock -name mspi_clk -period 15.873 -waveform {0 5} [get_ports {mspi_clk}] -add
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
set_clock_groups -asynchronous -group [get_clocks {clk_pixel_x5}] -group [get_clocks {clk64}]
