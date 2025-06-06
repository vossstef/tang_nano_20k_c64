create_clock -name ds_clk -period 500.000 -waveform {0 250} [get_nets {gamepad_p1/clk_spi}] -add
create_clock -name ds2_clk -period 500.000 -waveform {0 250} [get_nets {gamepad_p2/clk_spi}] -add
create_clock -name flash_clk -period 15.595 -waveform {0 5} [get_nets {flash_clk}]
create_clock -name clk -period 20 -waveform {0 5} [get_ports {clk}]
create_clock -name clk32 -period 31.746 -waveform {0 5} [get_nets {clk32}]
create_clock -name clk64 -period 15.873 -waveform {0 5} [get_nets {clk64}]
create_clock -name clk_audio -period 2611 -waveform {0 5} [get_nets {video_inst/i2s_clk}] -add
create_clock -name mspi_clk -period 15.595 -waveform {0 5} [get_ports {mspi_clk}] -add
create_clock -name m0s[3] -period 40.000 -waveform {0 5} [get_ports {m0s[3]}] -add
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
set_clock_groups -asynchronous -group [get_clocks {flash_clk}] 
                               -group [get_clocks {clk_audio}] 
                               -group [get_clocks {clk64}] 
                               -group [get_clocks {clk32}] 