quit -sim

cd ./sim
if ![file exists "./sim.mpf"] {
project new "." sim
project addfile "./../../src/c1541/mist_sd_card.sv" 
project addfile "./../../src/dualshock_controller.v" 
project addfile "./../../src/gowin_clkdiv/gowin_clkdiv.v" 
project addfile "./../../src/gowin_dpb/gowin_dpb_buffer.v" 
project addfile "./../../src/gowin_dpb/gowin_dpb_track_buffer_b.v" 
project addfile "./../../src/gowin_dpb/gowin_dpb_trkbuf.v" 
project addfile "./../../src/gowin_rpll/pll_160m.v" 
project addfile "./../../src/hdmi/audio_clock_regeneration_packet.sv" 
project addfile "./../../src/hdmi/audio_info_frame.sv" 
project addfile "./../../src/hdmi/audio_sample_packet.sv" 
project addfile "./../../src/hdmi/auxiliary_video_information_info_frame.sv" 
project addfile "./../../src/hdmi/hdmi.sv" 
project addfile "./../../src/hdmi/packet_assembler.sv" 
project addfile "./../../src/hdmi/packet_picker.sv" 
project addfile "./../../src/hdmi/serializer.sv" 
project addfile "./../../src/hdmi/source_product_description_info_frame.sv" 
project addfile "./../../src/hdmi/tmds_channel.sv" 
project addfile "./../../src/misc/hid.v" 
project addfile "./../../src/misc/mcu_spi.v" 
project addfile "./../../src/misc/osd_u8g2.v" 
project addfile "./../../src/misc/scandoubler.v" 
project addfile "./../../src/misc/sd_card.v" 
project addfile "./../../src/misc/sd_rw.v" 
project addfile "./../../src/misc/sdcmd_ctrl.v" 
project addfile "./../../src/misc/sysctrl.v" 
project addfile "./../../src/misc/video.v" 
project addfile "./../../src/misc/video_analyzer.v" 
project addfile "./../../src/mos6526.v" 
project addfile "./../../src/sdram.v" 
project addfile "./../../src/ws2812.v" 
project addfile "./../../src/c1541/c1541_logic.vhd"
project addfile "./../../src/c1541/c1541_sd.vhd"
project addfile "./../../src/c1541/gcr_floppy.vhd"
project addfile "./../../src/c1541/via6522.vhd"
project addfile "./../../src/cpu_6510.vhd"
project addfile "./../../src/fpga64_buslogic.vhd"
project addfile "./../../src/fpga64_keyboard.vhd"
project addfile "./../../src/fpga64_rgbcolor.vhd"
project addfile "./../../src/fpga64_sid_iec.vhd"
project addfile "./../../src/gowin_prom/gowin_prom_1541_8k_rom.vhd"
project addfile "./../../src/gowin_prom/gowin_prom_1541_rom.vhd"
project addfile "./../../src/gowin_prom/gowin_prom_basic_kernal.vhd"
project addfile "./../../src/gowin_prom/gowin_prom_cart.vhd"
project addfile "./../../src/gowin_prom/gowin_prom_chargen.vhd"
project addfile "./../../src/gowin_rpll/gowin_rpll.vhd"
project addfile "./../../src/gowin_sp/gowin_sp_2k.vhd"
project addfile "./../../src/gowin_sp/gowin_sp_8k.vhd"
project addfile "./../../src/keyboard_matrix_pkg.vhd"
project addfile "./../../src/sid6581/Q_table.vhd"
project addfile "./../../src/sid6581/adsr_multi.vhd"
project addfile "./../../src/sid6581/mult_acc.vhd"
project addfile "./../../src/sid6581/my_math_pkg.vhd"
project addfile "./../../src/sid6581/oscillator.vhd"
project addfile "./../../src/sid6581/sid_ctrl.vhd"
project addfile "./../../src/sid6581/sid_debug_pkg.vhd"
project addfile "./../../src/sid6581/sid_filter.vhd"
project addfile "./../../src/sid6581/sid_mixer.vhd"
project addfile "./../../src/sid6581/sid_regs.vhd"
project addfile "./../../src/sid6581/sid_top.vhd"
project addfile "./../../src/sid6581/wave_map.vhd"
project addfile "./../../src/spram.vhd"
project addfile "./../../src/t65/T65.vhd"
project addfile "./../../src/t65/T65_ALU.vhd"
project addfile "./../../src/t65/T65_MCode.vhd"
project addfile "./../../src/t65/T65_Pack.vhd"
project addfile "./../../src/tang_nano_20k_c64_top.vhd"
project addfile "./../../src/video_vicII_656x.vhd"

 if [file exists work] {
    vdel -lib work -all
   }
vlib work
vlib gw2a

vcom -work gw2a -2008 -autoorder -explicit \
"./../../tb/prim_sim.vhd" \
"./../../tb/prim_syn.vhd"

vlog -sv -suppress 2730,2388 -work work \
"./../../src/c1541/mist_sd_card.sv" \
"./../../src/hdmi/audio_clock_regeneration_packet.sv" \ 
"./../../src/hdmi/audio_info_frame.sv" \ 
"./../../src/hdmi/audio_sample_packet.sv" \ 
"./../../src/hdmi/auxiliary_video_information_info_frame.sv" \ 
"./../../src/hdmi/hdmi.sv" \ 
"./../../src/hdmi/packet_assembler.sv" \ 
"./../../src/hdmi/packet_picker.sv" \ 
"./../../src/hdmi/serializer.sv" \ 
"./../../src/hdmi/source_product_description_info_frame.sv" \ 
"./../../src/hdmi/tmds_channel.sv"

vlog -vlog01compat -work work \
"./../../src/misc/hid.v" \ 
"./../../src/misc/mcu_spi.v" \ 
"./../../src/misc/osd_u8g2.v" \ 
"./../../src/misc/scandoubler.v" \ 
"./../../src/misc/sd_card.v" \ 
"./../../src/misc/sd_rw.v" \ 
"./../../src/misc/sdcmd_ctrl.v" \ 
"./../../src/misc/sysctrl.v" \ 
"./../../src/misc/video.v" \ 
"./../../src/misc/video_analyzer.v" \ 
"./../../src/mos6526.v" \ 
"./../../src/sdram.v" \ 
"./../../src/ws2812.v" 
"./../../src/dualshock_controller.v" \
"./../../src/gowin_clkdiv/gowin_clkdiv.v" \ 
"./../../src/gowin_dpb/gowin_dpb_buffer.v" \ 
"./../../src/gowin_dpb/gowin_dpb_track_buffer_b.v" \ 
"./../../src/gowin_dpb/gowin_dpb_trkbuf.v" \ 
"./../../src/gowin_rpll/pll_160m.v"

vcom -work work -2008 -autoorder -explicit \
"./../../src/c1541/c1541_logic.vhd" \
"./../../src/c1541/c1541_sd.vhd" \
"./../../src/c1541/gcr_floppy.vhd" \
"./../../src/c1541/via6522.vhd" \
"./../../src/cpu_6510.vhd" \
"./../../src/fpga64_buslogic.vhd" \
"./../../src/fpga64_keyboard.vhd" \
"./../../src/fpga64_rgbcolor.vhd" \
"./../../src/fpga64_sid_iec.vhd" \
"./../../src/gowin_prom/gowin_prom_1541_8k_rom.vhd" \
"./../../src/gowin_prom/gowin_prom_1541_rom.vhd" \
"./../../src/gowin_prom/gowin_prom_basic_kernal.vhd" \
"./../../src/gowin_prom/gowin_prom_cart.vhd" \
"./../../src/gowin_prom/gowin_prom_chargen.vhd" \
"./../../src/gowin_rpll/gowin_rpll.vhd" \
"./../../src/gowin_sp/gowin_sp_2k.vhd" \
"./../../src/gowin_sp/gowin_sp_8k.vhd" \
"./../../src/keyboard_matrix_pkg.vhd" \
"./../../src/sid6581/Q_table.vhd" \
"./../../src/sid6581/adsr_multi.vhd" \
"./../../src/sid6581/mult_acc.vhd" \
"./../../src/sid6581/my_math_pkg.vhd" \
"./../../src/sid6581/oscillator.vhd" \
"./../../src/sid6581/sid_ctrl.vhd" \
"./../../src/sid6581/sid_debug_pkg.vhd" \
"./../../src/sid6581/sid_filter.vhd" \
"./../../src/sid6581/sid_mixer.vhd" \
"./../../src/sid6581/sid_regs.vhd" \
"./../../src/sid6581/sid_top.vhd" \
"./../../src/sid6581/wave_map.vhd" \
"./../../src/spram.vhd" \
"./../../src/t65/T65.vhd" \
"./../../src/t65/T65_ALU.vhd" \
"./../../src/t65/T65_MCode.vhd" \
"./../../src/t65/T65_Pack.vhd" \
"./../../src/tang_nano_20k_c64_top.vhd" \
"./../../src/video_vicII_656x.vhd" 
} else {
 project open "./sim"
 project compileoutofdate
}

vsim -voptargs=+acc -gui -L gw2a work.c64_tb
view wave

add wave -divider "Input Signals"
#add wave -logic 

add wave -divider "Result Interface"
#add wave -logic 
#add wave -radix hexadecimal 
add wave -r /*

onerror {resume}
quietly WaveActivateNextPane {} 0

configure wave -namecolwidth 420
configure wave -valuecolwidth 110
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns

configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0ns} {2000ns}

quietly set StdArithNoWarnings 1
quietly set NumericStdNoWarnings 1

run 10 ms
