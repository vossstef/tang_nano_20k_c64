quit -sim

cd ./sim
if ![file exists "./sim.mpf"] {
project new "." sim
project addfile "./../../src/c1541/mist_sd_card.sv" 
project addfile "./../../src/gowin_dpb/sector_dpram.v" 
project addfile "./../../src/gowin_dpb/gowin_dpb_track_buffer_b.v" 
project addfile "./../../src/gowin_dpb/gowin_dpb_trkbuf.v" 
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
project addfile "./../../src/sdram8.v" 
project addfile "./../../src/misc/ws2812.v" 
project addfile "./../../src/c1541/c1541_logic.vhd"
project addfile "./../../src/c1541/c1541_sd.vhd"
project addfile "./../../src/c1541/gcr_floppy.vhd"
project addfile "./../../src/c1541/via6522.vhd"
project addfile "./../../src/cpu_6510.vhd"
project addfile "./../../src/fpga64_buslogic.vhd"
project addfile "./../../src/fpga64_keyboard.vhd"
project addfile "./../../src/fpga64_rgbcolor.vhd"
project addfile "./../../src/fpga64_sid_iec.vhd"
project addfile "./../../src/gowin_prom/gowin_prom_basic.vhd"
project addfile "./../../src/gowin_prom/gowin_prom_chargen.vhd"
project addfile "./../../src/gowin_sdpb/gowin_sdpb_kernal_8k.vhd"
project addfile "./../../src/gowin_sp/gowin_sp_2k.vhd"
project addfile "./../../src/gowin_sp/gowin_sp_8k.vhd"
project addfile "./../../src/sid/sid_dac.sv"
project addfile "./../../src/sid/sid_envelope.sv"
project addfile "./../../src/sid/sid_filter.sv"
project addfile "./../../src/sid/sid_tables.sv"
project addfile "./../../src/sid/sid_top.sv"
project addfile "./../../src/sid/sid_voice.sv"
project addfile "./../../src/c1530.vhd"
project addfile "./../../src/t65/T65.vhd"
project addfile "./../../src/t65/T65_ALU.vhd"
project addfile "./../../src/t65/T65_MCode.vhd"
project addfile "./../../src/t65/T65_Pack.vhd"
project addfile "./../../src/tang_nano_20k_c64_top.vhd"
project addfile "./../../src/video_vicII_656x.vhd"
project addfile "./../../tb/c64_tb.vhd"
project addfile "./../../src/gowin_sp/gowin_sp_cram.vhd"
project addfile "./../../src/misc/flash_dspi.v"
project addfile "./../../src/reu.v"
project addfile "./../../src/acia.v"
project addfile "./../../src/c64_midi.vhd"
project addfile "./../../src/dualshock2.v"
project addfile "./../../src/loader_sd_card.sv"
project addfile "./../../src/fifo_sc_hs/fifo_sc_hs.vhd"
project addfile "./../../tb/prim_sim.v"
project addfile "./../../tb/prim_sim.vhd"

#project addfile "./../../tb/prim_syn.vhd"
#project addfile "./../../tb/prim_tsim.v"

 if [file exists work] {
    vdel -lib work -all
   }

 if [file exists gw2a] {
    vdel -lib gw2a -all
   }

vlib work
vlib gw2a

# Compile the GOWIN Standard Cells to Library std_cell_lib
#vlog -incr -work gw_std_cell_lib "./../../tb/prim_sim.v" 

vcom -work gw2a -2008 -autoorder -explicit \
"./../../tb/prim_sim.vhd" \
"./../../tb/prim_syn.vhd"

vlog -incr -work work \
-suppress 2388,13282,13294 \
-sv \
-sv17compat \
-incr \
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
"./../../src/hdmi/tmds_channel.sv" \
"./../../src/misc/hid.v" \
"./../../src/misc/mcu_spi.v" \
"./../../src/misc/osd_u8g2.v" \
"./../../src/misc/sysctrl.v" \
"./../../src/misc/video.v" \
"./../../src/misc/sd_card.v" \
"./../../src/misc/video_analyzer.v" \
"./../../src/misc/sd_rw.v" \
"./../../src/misc/scandoubler.v" \
"./../../src/mos6526.v" \
"./../../src/sdram8.v" \
"./../../src/misc/flash_dspi.v" \
"./../../src/reu.v" \
"./../../src/gowin_dpb/sector_dpram.v" \
"./../../src/gowin_dpb/gowin_dpb_track_buffer_b.v" \
"./../../src/gowin_dpb/gowin_dpb_trkbuf.v" \
"./../../src/cartridge.v" \
"./../../src/acia.v" \
"./../../src/dualshock2.v" \
"./../../src/loader_sd_card.sv" \
"./../../src/sid/sid_dac.sv" \
"./../../src/sid/sid_envelope.sv" \
"./../../src/sid/sid_filter.sv" \
"./../../src/sid/sid_tables.sv" \
"./../../src/sid/sid_top.sv" \
"./../../src/sid/sid_voice.sv" \

#"./../../tb/prim_sim.v" 
# "./../../tb/prim_tsim.v"

vlog -work work -incr \
"./../../src/misc/sdcmd_ctrl.v" \
"./../../src/misc/ws2812.v" \
"./../../src/dualshock_controller.v"

vcom -work work -suppress 1583 -2008 -autoorder -explicit \
"./../../tb/c64_tb.vhd" \
"./../../src/gowin_sp/gowin_sp_cram.vhd" \
"./../../src/c1541/c1541_logic.vhd" \
"./../../src/c1541/c1541_sd.vhd" \
"./../../src/c1541/gcr_floppy.vhd" \
"./../../src/c1541/via6522.vhd" \
"./../../src/cpu_6510.vhd" \
"./../../src/fpga64_buslogic.vhd" \
"./../../src/fpga64_keyboard.vhd" \
"./../../src/fpga64_rgbcolor.vhd" \
"./../../src/fpga64_sid_iec.vhd" \
"./../../src/gowin_sdpb/gowin_sdpb_kernal_8k.vhd" \
"./../../src/gowin_prom/gowin_prom_chargen.vhd" \
"./../../src/gowin_prom/gowin_prom_basic.vhd" \
"./../../src/gowin_sp/gowin_sp_2k.vhd" \
"./../../src/gowin_sp/gowin_sp_8k.vhd" \
"./../../src/t65/T65.vhd" \
"./../../src/t65/T65_ALU.vhd" \
"./../../src/t65/T65_MCode.vhd" \
"./../../src/t65/T65_Pack.vhd" \
"./../../src/tang_nano_20k_c64_top.vhd" \
"./../../src/video_vicII_656x.vhd" \
"./../../src/c64_midi.vhd" \
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
