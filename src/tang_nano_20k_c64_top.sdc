create_clock -name clk32 -period 31.746 -waveform {0 5} [get_nets {clk32}] -add
create_clock -name flash_clk -period 15.595 -waveform {0 5} [get_nets {flash_clk}] -add
create_clock -name clk64 -period 15.873 -waveform {0 5} [get_nets {clk64}] -add
create_clock -name ds_clk -period 500.000 -waveform {0 250} [get_nets {gamepad_p1/clk_spi}] -add
create_clock -name ds2_clk -period 500.000 -waveform {0 250} [get_nets {gamepad_p2/clk_spi}] -add
create_clock -name clk_pixel_x10 -period 3.175 -waveform {0 1.587} [get_nets {clk_pixel_x10}] -add
create_clock -name clk -period 37.037 -waveform {0 5} [get_ports {clk}] -add
create_clock -name clk_pixel_x5 -period 6.349 -waveform {0 1.25} [get_nets {clk_pixel_x5}] -add
create_clock -name clk_audio -period 20833.332 -waveform {0 5} [get_nets {video_inst/clk_audio}] -add
create_clock -name mspi_clk -period 15.595 -waveform {0 5} [get_ports {mspi_clk}] -add
create_clock -name m0s[3] -period 50.0 -waveform {0 5} [get_ports {m0s[3]}] -add
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
set_clock_groups -asynchronous -group [get_clocks {flash_clk}] 
                               -group [get_clocks {clk_audio}] 
                               -group [get_clocks {clk64}] 
                               -group [get_clocks {clk32}] 
                               -group [get_clocks {clk_pixel_x5}] 