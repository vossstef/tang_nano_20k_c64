# C64Nano
The C64Nano is a port of some [MiST](https://github.com/mist-devel/mist-board/wiki) and 
[MiSTer](https://mister-devel.github.io/MkDocs_MiSTer/) components of the
[C64 FPGA core ](https://en.wikipedia.org/wiki/Commodore_64) for the 
[Tang Nano 20k FPGA board](https://wiki.sipeed.com/nano20k) with a new VHDL top level and HDMI Video and Audio Output.<br>It has also been ported to the [Tang Primer 25K](https://wiki.sipeed.com/hardware/en/tang/tang-primer-25k/primer-25k.html)  ([Gowin GW5A-25](https://www.gowinsemi.com/en/product/detail/60/)) and [Tang Mega 138k](https://wiki.sipeed.com/hardware/en/tang/tang-mega-138k/mega-138k-pro.html) ([Gowin GW5AST-138](https://www.gowinsemi.com/en/product/detail/60/)) too.<br>
Be aware that the [VIC20 FPGA core](https://en.wikipedia.org/wiki/VIC-20) had been ported too in similar manner ([link](https://github.com/vossstef/VIC20Nano)).<br>
<br>
Original C64 core by Peter Wendrich<br>
All HID components and [BL616 MCU](https://en.bouffalolab.com/product/?type=detail&id=25) µC firmware by Till Harbaum<br>
c1541 by https://github.com/darfpga<br>

Features:
* PAL 800x576p@50Hz or NTSC 800x480p@60Hz HDMI Video and Audio Output
* USB Keyboard via [Sipeed M0S Dock BL616 RISC-V µC](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html)
* USB Joystick via µC
* USB Mouse via µC [c1351](https://en.wikipedia.org/wiki/Commodore_1351) Mouse emulation
* [legacy D9 Joystick](https://en.wikipedia.org/wiki/Atari_CX40_joystick) (Atari / Commodore digital type) [MiSTeryNano shield](https://github.com/harbaum/MiSTeryNano/tree/main/board/misteryshield20k/README.md)<br>
* Joystick emulation on Keyboard Numpad<br>
* [Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock) Keys & Stick as Joystick<br>
* [Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock) Sticks as [Paddle](https://www.c64-wiki.com/wiki/Paddle) Emulation (analog mode)<br>
* emulated [1541 Diskdrive](https://en.wikipedia.org/wiki/Commodore_1541) on FAT/extFAT microSD card with parallel bus [Speedloader Dolphin DOS 2](https://rr.pokefinder.org/wiki/Dolphin_DOS). [GER manual](https://www.c64-wiki.de/wiki/Dolphin_DOS)<br>
* c1541 DOS ROM selection
* Cartridge (*.CRT) loader
* Direct program file (*.PRG) injection loader
* Loadable 8K Kernal ROM (*.BIN)
* emulated [RAM Expansion Unit (REU)](https://en.wikipedia.org/wiki/Commodore_REU)<br>
* On Screen Display (OSD) for configuration and loadable image selection (D64/G64/CRT/PRG/BIN)<br>
* Physical MIDI-IN and OUT [MiSTeryNano shield](https://github.com/harbaum/MiSTeryNano/tree/main/board/misteryshield20k/README.md)<br>
<br>
<img src="./.assets/c64_core.png" alt="image" width="80%" height="auto">
<br>

HID interfaces aligned in pinmap and control to match [MiSTeryNano project's bl616 misterynano_fw](https://github.com/harbaum/MiSTeryNano/tree/main/firmware/misterynano_fw).<br> Basically BL616 µC acts as USB host for USB devices and as an OSD controller using a [SPI communication protocol](https://github.com/harbaum/MiSTeryNano/blob/main/SPI.md).<br>

**Note** PROJECT IS STILL WORK IN PROGRESS
<br>
## Installation

The installation of C64 Nano on the Tang Nano 20k board can be done using a Linux PC or a Windows PC
[(Instruction)](INSTALLATION_WINDOWS.md).<br>

## c64 Nano on Tang Primer 25K
See [Tang Primer 25K](TANG_PRIMER_25K.md)

## c64 Nano on Tang Mega 138k
See [Tang Mega 138K](TANG_MEGA_138K.md)

## emulated Diskdrive c1541
Emulated 1541 on a regular FAT/exFAT formatted microSD card including parallel bus Speedloader Dolphin DOS.<br>
Copy a D64 Disk image to your sdcard and rename it to **disk8.d64** as default boot image.<br>
Add further D64 or G64 images as you like and insert card in TN slot. Power Cycle TN. LED 0 acts as Drive activity indicator.<br> 
Disk directory listing: (or F7 keypress)<br> 
LOAD"$",8<br>
LIST<br> 
Load first program from Disk: (or just LOAD)<br> 
LOAD"*",8<br>
RUN<br>
c1541 DOS ROM to be selected from OSD (default Dolphin DOS, CBM DOS or other)<br>
In case a program don't load correctly select via OSD the factory default CBM DOS an give it a try.

## CRT Loader (.CRT)
Cartrige ROM can be loaded via OSD file selection.<br>
Copy a *.CRT to your sdcard and rename it to **c64crt.crt** as default boot cartridge.<br>
Detach Cartrige by OSD CRT selection **No Disk** , **Save settings** and System **Cold Boot**.<br>

## PRG Loader (.PRG)
A Program *.PRG file can be loaded via OSD file selection.<br>
Copy a *.PRG to your sdcard and rename it to **c64prg.prg** as default boot basic program.<br>
Prevent PRG load by OSD PRG selection **No Disk** , **Save settings** and **Reset**.<br>

## Kernal Loader (.BIN)
Dolphin DOS 2.0 is the power-up default Kernal.<br>
Kernal ROM files *.BIN can be loaded via OSD selection.<br>
Copy a 8K C64 Kernal ROM *.BIN to your sdcard and rename it to **c64kernal.bin** as default boot Kernal.<br>
Prevent Kernal load by OSD Kernal BIN selection **No Disk** and **Save settings** and do a **power-cyle** of the board.<br>

## emulated RAM Expansion Unit REU 1750
For those programs the require a [RAM Expansion Unit (REU)](https://en.wikipedia.org/wiki/Commodore_REU) it can be activated by OSD on demand.<br>
<br>
Playing [Sonic the Hedgehog V1.2](https://csdb.dk/release/?id=212523)<br>
Enable REU, and load the PRG.<br>

Playing around with [GEOS](https://en.wikipedia.org/wiki/GEOS_(8-bit_operating_system))<br>
Enable REU, select c1541 CBM DOS ROM and load the PRG.<br>

## Push Button utilization
* S2 keep pressed during power-up for programming Flash<br>
* S1 reserved <br>

## OSD
invoke by F12 keypress<br>
* Reset<br>
* Cold Reset + memory scrubbing<br>
* Audio Volume + / -<br>
* Scanlines effect %<br>
* Widescreen activation<br>
* HID device selection for Joystick Port 1 and Port 2<br>
* REU activation<br>
* Audio Filter<br>
* c1541 Drive disk image selection<br>
* c1541 Disk write protetcion<br>
* c1541 Reset<br>
* c1541 DOS ROM selection<br>
* MIDI configuration<br>
* Pause when OSD open<br>
* PAL / NTSC Video mode<br>
* VIC-II revision and 6526 / 8521 selection
* Loader (CRT/PRG/BIN) file selection<br>

## Gamecontrol support
legacy single D9 Digital Joystick. OSD: Retro D9<br>
or<br>
USB Joystick(s). OSD: USB #1 or USB #2 <br>
or<br>
Gamepad. OSD: DualShock
<br>**stick digital** for Move and Left **L1** or Right **R1** shoulder Button for Trigger or following **Pad** controls:<br>
| Buttons | - | - |
| - | - | -  |
| Left L1/R1<br>Trigger | triangle button<br>Up  | .  |
| square button<br>Left | - | circle button<br>Right |
| - | cross button<br>Down | - |<br>

or Keyboard **Numpad**. OSD: Numpad<br>
| | | |
|-|-|-|
|0<br>Trigger|8<br>Up|-|
|4<br>Left|-|6<br>Right|
|-|2<br>Down|-|

or Mouse. OSD: Mouse<br>
USB Mouse as c1351 Mouse emulation.

or Paddle. OSD: Paddle<br>
Dualshock 2 Sticks in analog mode as VC-1312 Paddle emulation.<br>
Left **L1 / L2**  and Right **R1 / R2** shoulder Button as Trigger<br>
You have first to set the DS2 Sticks into analog mode by pressing the DS2 ANALOG button. Mode indicated by red light indicator.<br>Configure DIGITAL mode (press ANALOG button again) when using the Joystick mode agin. OSD: DS2<br>

## Keyboard 
 ![Layout](\.assets/keymap.gif)
 Tape Play not implemented.

## LED UI

| LED | function | TN20K | TP25K | TM138K |
| --- |        - | -     | -     | -      |
| 0 | c1541 activity  | x | x | x |
| 1 | D64 selected | x | - | x |
| 2 | CRT seleced | x | - | x |
| 3 | PRG selected | x | - | x |
| 4 | Kernal selected  | x | - | x |
| 5 | (reserved TAP) | x | - | x |

Solid 'red' of the c1541 led after power-up indicates a missing DOS in Flash<br>

**Multicolor RGB LED**
* **<font color="green">green</font>**&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;all fine and ready to go<br>
* **<font color="red">red</font>**&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;something wrong with SDcard / default boot image<br>
* **<font color="blue">blue</font>**&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;µC firmware detected valid FPGA core<br>
* **white**&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;-<br>

## MIDI-IN and OUT
Type of MIDI interface can be selected from OSD.<br> There is support for Sequential Inc., Passport/Sentech, DATEL/SIEL/JMS/C-LAB and Namesoft<br>
You can use a [MiSTeryNano MIDI shield](https://github.com/harbaum/MiSTeryNano/tree/main/board/misteryshield20k/README.md) to interface to a Keyboard.<br>
## Powering
Prototype circuit with Keyboard can be powered by Tang USB-C connector from PC or a Power Supply Adapter. 
## Synthesis
Source code can be synthesized, fitted and programmed with GOWIN IDE Windows or Linux.<br>
Alternatively use the command line build script gw_sh.exe build_tn20k.tcl, build_tp25k.tcl or build_tm138k.tcl<br>
## Pin mapping 
see pin configuration in .cst configuration file
## HW circuit considerations
**Pinmap TN20k Interfaces** <br>
 Sipeed M0S Dock, digital Joystick D9 and DualShock Gamepad connection.<br>
 ![wiring](\.assets/wiring_spi_irq.png)

**Pinmap D-SUB 9 Joystick Interface** <br>
- Joystick interface is 3.3V tolerant. Joystick 5V supply pin has to be left floating !<br>
![pinmap](\.assets/vic20-Joystick.png)

| Joystick pin | Tang Nano pin | FPGA pin | Joystick Function |
| ----------- | ---   | --------  | ----- |
| 1 | J6 9  | 28   | Joy3 RIGHT | 28 |
| 2 | J6 11  | 25 | Joy2 LEFT | 25 |
| 3 | J6 10 | 26 | Joy1 DOWN | 26 |
| 4 | J5 12 | 29 | Joy0 UP | 29 |
| 5 | - | - | POT Y | - |
| 6 | J5 8 | 27 | FIRE B.| 27 |
| 7 | n.c | n.c | 5V | - |
| 8 | J5 20 | - | GND | - |
| 9 | - | - | POT X | - |

**Pinmap Dualshock 2 Controller Interface** <br>
<img src="./.assets/controller-pinout.jpg" alt="image" width="30%" height="auto">
| DS pin | Tang Nano pin | FPGA pin | DS Function |
| ----------- | ---   | --------  | ----- |
| 1 | J5 18 | 71 MISO | JOYDAT  |
| 2 | J5 19 | 53 MOSI  | JOYCMD |
| 3 | n.c. | - | 7V5 |
| 4 | J5 15 | - | GND |
| 5 | J5 16| - | 3V3 |
| 6 | J5 17 | 72 CS | JOYATN|
| 7 | J5 20 | 52 MCLK | JOYCLK |
| 8 | n.c. | - | JOYIRQ |
| 9 | n.c. | - | JOYACK |


## Getting started

In order to use this Design the following things are needed:

[Sipeed M0S Dock](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html)<br>
[Sipeed Tang Nano 20k](https://wiki.sipeed.com/nano20k) <br>
or [Sipeed Tang Primer 25k](https://wiki.sipeed.com/hardware/en/tang/tang-primer-25k/primer-25k.html)<br>
and [PMOD DVI](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DVI)<br>
and [PMOD TF-CARD](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_TF-CARD)<br>
and [PMOD SDRAM](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#TANG_SDRAM)<br>
and [M0S PMOD adapter](https://github.com/harbaum/MiSTeryNano/tree/main/board/m0s_pmod/README.md)
 or ad hoc wiring + soldering.<br>
or [Sipeed Tang Mega 138k](https://wiki.sipeed.com/hardware/en/tang/tang-mega-138k/mega-138k-pro.html)<br>
and [PMOD SDRAM](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#TANG_SDRAM)<br>
and [PMOD DS2x2](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DS2x2)<br>
and [M0S PMOD adapter](https://github.com/harbaum/MiSTeryNano/tree/main/board/m0s_pmod/README.md)<br>
microSD or microSDHC card FAT32 formatted<br>
TFT Monitor with HDMI Input and Speaker<br>
<br>

| HID and Gamecontrol Hardware option | TN20k needs | alternative option |Primer 25K|Mega 138K|
| ----------- | --- | ---  | ---| -|
| USB Keyboard | [USB-C to USB-A adapter](https://www.aliexpress.us/item/3256805563910755.html) | [4 port mini USB hub](https://a.aliexpress.com/_EIidgjH)  |x|x|
| [USB Joystick(s)](https://www.speedlink.com/en/COMPETITION-PRO-EXTRA-USB-Joystick-black-red/SL-650212-BKRD)| [4 port mini USB hub](https://a.aliexpress.com/_EIidgjH) | - |x|x|
| USB Mouse | [4 port mini USB hub](https://a.aliexpress.com/_EIidgjH) | -  |x|x|
| Commodore/[Atari](https://en.wikipedia.org/wiki/Atari_CX40_joystick) compatible retro D9 Joystick| [MiSTeryNano shield](https://github.com/harbaum/MiSTeryNano/tree/main/board/misteryshield20k/README.md)|D-SUB 9 M connector, breadboard to wire everything up, some jumper wires|-|-|
| [Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock) | Gamepad Adapter Board (Sipeed Joystick to DIP) respectively<br> PMOD DS2x2 | breadboard to wire everything up and some jumper wires |-|x|
