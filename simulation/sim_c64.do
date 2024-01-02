quit -sim

cd ./sim
if ![file exists "./sim.mpf"] {
 project new "." sim
 project addfile "./../../src/T65_MCode.vhd"
 project addfile "./../../src/T65_ALU.vhd"
 project addfile "./../../src/T65_Pack.vhd"
 project addfile "./../../src/T65.vhd"

 if [file exists work] {
    vdel -lib work -all
   }
vlib work
vlib gw2a

vcom -work gw2a -2008 -autoorder -explicit \
"./../../tb/prim_sim.vhd" \
"./../../tb/prim_syn.vhd"

vcom -work work -2008 -autoorder -explicit \
 "./../../src/T65_MCode.vhd" \
 "./../../src/T65_ALU.vhd" \
 "./../../src/T65_Pack.vhd" \
 "./../../src/T65.vhd"
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
