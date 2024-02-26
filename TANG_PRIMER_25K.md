# C64 Nano on Tang Primer 25K

C64 Nano can be used in the [Tang Primer 25K](https://wiki.sipeed.com/hardware/en/tang/tang-primer-25k/primer-25k.html).<br> This offers a 10%
bigger FPGA than the [Tang Nano 20K](https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html)
the MiSTeryNano was initially developed for.<br> Unlike the TN20K, the
TP25k's FPGA does not come with an internal SDRAM. Nor does the board
come with HDMI or an SD card slot.

Some SDRAM can be added in the form of the [Tang SDRAM](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#TANG_SDRAM), HDMI can be added via the [PMOD DVI](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DVI) and the SD card is installed using the [PMOD TF-CARD](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_TF-CARD).<br> All three add-ons need to carefully be mounted with the SDRAM's "THIS SIDE FACES OUTWARD" pointing to the boards edge. The HDMI needs to be mounted to the leftmost PMOD slot andf the SD card to the rightmost.

The M0S required to control the MiSTeryNano is to be mounted in the middle PMOD with the help of the [M0S PMOD adapter](https://github.com/harbaum/MiSTeryNano/tree/main/board/m0s_pmod/README.md).

The whole setup will look like this:<br>
![m0s pmod on TP25K](./.assets/m0s_pmod_tp25k.jpg)


If you don't have a **M0S PMOD adapter** at hand then adhoc wiring is feasible needing a soldering iron.<br>
The needed +5V for the M0S Dock can be taken from Pin 1 of the USB-A connector by a short soldered wire<br> 8 single pins are needed to plug into the PMOD apart from the cable that comes along with the M0S Dock package.<br>


|      | M0S Dock | Primer-25k / PMOD                  |                                      |
|------|-------------------|-------------------|--------------------------------------|
| GND  | GND        | GND -> 3       | GND               |
| GND  | GND        | GND -> 4       | GND               |
| PWR  | +5V        | USB-A pin 1 !!! | +5V Supply for M0S              |
| - | +3V3        | n.c | don't connect !              |
| CSN  | GPIO12      | E11 -> 9       | SPI select, active low               |
| SCK  | GPIO13      | E10 -> 10       | SPI clock, idle low                  |
| MOSI | GPIO11      | A11 -> 11       | SPI data from MCU to FPGA            |
| MISO | GPIO10      | A10 <- 12       | SPI data from FPGA to MCU    |
| IRQ  | GPIO14      | L11 <- 8       | Interrupt from FPGA to MCU, active low |

![c64 Nano on TP25K](./.assets/primer25k.png)

On the software side the setup is very simuilar to the original Tang Nano 20K based solution. The core needs to be built specifically
for the different FPGA of the Tang Primer using either the [TCL script with the GoWin command line interface](build_tp25k.tcl) or the
[project file for the graphical GoWin IDE](tang_primer_25k_c64.gprj). The resulting bitstream is flashed to the TP25K as usual. So are the c1541 DOS ROMs which are flashed exactly like they are on the Tang Nano 20K. And also the firmware for the M0S Dock is the [same version as for
the Tang Nano 20K](https://github.com/harbaum/MiSTeryNano/tree/main/firmware/misterynano_fw/). Latest binary can be found in the [release](https://github.com/harbaum/MiSTeryNano/releases) section.

The resulting setup has no spare connectors and thus no MIDI, DB9 retro joystick port, DualShock, Paddle is available.