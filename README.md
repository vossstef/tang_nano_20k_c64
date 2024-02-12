# tang_nano_20k_c64
[C64](https://en.wikipedia.org/wiki/Commodore_64) living in a [Gowin GW2AR](https://www.gowinsemi.com/en/product/detail/38/) FPGA on a [Sipeed Tang Nano 20k](https://api.dl.sipeed.com/shareURL/TANG/Nano_20K) with HDMI Video and Audio Output.<br>
<br>
Original C64 core by Peter Wendrich<br>
Dram controller and [BL616 MCU](https://en.bouffalolab.com/product/?type=detail&id=25) µC firmware by Till Harbaum<br>
c1541 by https://github.com/darfpga<br>

Features:
* HDMI 720x576p @50Hz Video and Audio Output
* USB Keyboard via [Sipeed M0S Dock BL616 µC](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html) (future plan Tang onboard BL616 µC)
* USB Joystick via µC
* USB Mouse via µC as c1351 Mouse emulation
* [legacy D9 Joystick](https://en.wikipedia.org/wiki/Atari_CX40_joystick) (Atari / Commodore digital type)<br>
* Joystick emulation on Keyboard Numpad<br>
* [Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock) Keys & Stick as Joystick<br>
* [Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock) Sticks as [Paddle](https://www.c64-wiki.com/wiki/Paddle) Emulation (analog mode)<br>
* emulated [1541 Diskdrive](https://en.wikipedia.org/wiki/Commodore_1541) on FAT/extFAT microSD card with parallel bus [Speedloader Dolphin DOS 2](https://rr.pokefinder.org/wiki/Dolphin_DOS). [GER manual](https://www.c64-wiki.de/wiki/Dolphin_DOS)<br>
* emulated [RAM Expansion Unit (REU)](https://en.wikipedia.org/wiki/Commodore_REU)<br>
* c1541 DOS ROM selection
* On Screen Display (OSD) for configuration and D64 / G64 image selection<br>
* MIDI Interface [MIDI shield](https://github.com/harbaum/MiSTeryNano/tree/main/board)<br>
<br>
<img src="./.assets/c64_core.png" alt="image" width="80%" height="auto">
<br>

<font color="red">HID interfaces aligned in pinmap and control to match</font> [MiSTeryNano project's bl616 misterynano_fw](https://github.com/harbaum/MiSTeryNano/tree/main/bl616/misterynano_fw).<br> Basically BL616 µC acts as USB host for USB devices and as an OSD controller using a [SPI communication protocol](https://github.com/harbaum/MiSTeryNano/blob/main/SPI.md).<br>

**Note** PROJECT IS STILL WORK IN PROGRESS</b>
<br>
## Installation

The installation of C64 Nano on the Tang Nano 20k can be done using a Linux PC or a
[Windows PC instructions](INSTALLATION_WINDOWS.md).

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
c1541 DOS ROM to be selected from OSD (default Dolphin, factory or other)<br>

## emulated RAM Expansion Unit REU 1750
For those programs the require a [RAM Expansion Unit (REU)](https://en.wikipedia.org/wiki/Commodore_REU) it can be activated by OSD on demand.<br>
<br>
Playing [Sonic the Hedgehog V1.2](https://csdb.dk/release/?id=212523)<br>
Enable REU, do via OSD a cold c64 core reset and load the PRG.<br>

## Push Button utilization
* S2 Reset (for Flasher)<br>
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
* Image selection for c1541 Drive<br>
* c1541 Disk write protetcion<br>
* c1541 Reset<br>
* c1541 DOS ROM selection<br>
* MIDI mode<br>
* Pause when OSD open activation<br>

## Gamecontrol support
legacy single D9 Digital Joystick. OSD: D9<br>
or<br>
USB Joystick(s). OSD: UJ1 or UJ2 <br>
or<br>
Gamepad. OSD: DS2
<br>**stick digital** for Move and Left **L1** or Right **R1** shoulder Button for Fire or following **Pad** controls:<br>
| Buttons | - | - |
| - | - | -  |
| Left L1/R1<br>Fire | triangle button<br>Up  | .  |
| square button<br>Left | - | circle button<br>Right |
| - | cross button<br>Down | - |<br>

or Keyboard **Numpad**. OSD: NP<br>
| | | |
|-|-|-|
|0<br>Fire|8<br>Up|-|
|4<br>Left|-|6<br>Right|
|-|2<br>Down|-|

or Mouse. OSD: Mou<br>
USB Mouse as c1351 Mouse emulation.

or Paddle. OSD: Pad<br>
Dualshock 2 Sticks in analog mode as VC-1312 Paddle emulation.<br>
Left **L1 / L2**  and Right **R1 / R2** shoulder Button as Trigger<br>
You have first to set the DS2 Sticks into analog mode by pressing the DS2 ANALOG button. Mode indicated by red light indicator.<br>Configure DIGITAL mode (press ANALOG button again) when using the Joystick mode agin. OSD: DS2<br>

## Keyboard 
 ![Layout](\.assets/keymap.gif)
 Tape Play not implemented.

## LED UI
0 c1541 Drive activity. Solid 'red' after power indicates a problem missing DOS in Flash<br>
1 unused<br>
2 unused<br>
3 M0S Dock detect<br>
4 System LED 0<br>
5 System LED 1<br>

## Powering
Prototype circuit with Keyboard can be powered by Tang USB-C connector from PC or a Power Supply Adapter. 
## Synthesis
Source code can be synthesized, fitted and programmed with GOWIN IDE Windows or Linux.<br>
## Flash program
*M0 Dock Bl616 Firmware:*<br>Have a look MiSTeryNano readme chapter 'Installation of the MCU firmware' to get an idea how to install the needed Firmware.<br>

*FPGA bitstream:*<br>
For proper operation program .fs bitsteam to 'external Flash' and power cycle the board.<br>
Just SRAM load will not be sufficient.<br>

*c1541 DOS ROM:*<br>
Image has be to 32k Byte in size !<br>
Memory Layout SPI Flash:<br>
0x000000 reserved for FPGA bitstream<br>
0x100000 reserved for Atari ST/STE<br>
0x200000 c1541 Dolphin Dos 2<br>
0x208000 c1541 factory CBM DOS 2.6<br>
0x210000 c1541 Speed DOS<br>
0x218000 c1541 Jiffy DOS<br>

Use Gowin Programmer GUI or OpenFpgaLoader(Linux) to program at least **Dolphin DOS and factory CBM DOS** to 'external Flash' at mentioned offsets. DOS roms you will find on the internet.<br>

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
| 6 | J5 17 | 72 CS | JOYn|
| 7 | J5 20 | 52 MCLK | JOYCLK |
| 8 | n.c. | - | IRQ |
| 9 | J6 5 | 77 ACK | JOYACK |


## Getting started

In order to use this Design the following things are needed:

[Sipeed Tang Nano 20k](https://wiki.sipeed.com/nano20k)<br>
[Sipeed M0S Dock](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html)<br>
USB-C to USB-A adapter to connect regular USB devices to the M0S Dock<br> &nbsp;&nbsp;or alternatively a 4 port [mini USB hub](https://a.aliexpress.com/_EIidgjH)<br>
microSD or microSDHC card FAT/exFAT formatted<br>
USB Keyboard<br>
D-SUB 9 M connector<br> 
Commodore/[Atari](https://en.wikipedia.org/wiki/Atari_CX40_joystick) compatible Joystick<br>
a breadboard to wire everything up<br>
some jumper wires<br>
TFT Monitor with HDMI Input<br>
<br>
alternative Gamecontrol Hardware option:<br>
Gamepad Adapter Board (Sipeed Joystick to DIP)<br>
[Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock)<br>
[USB Joystick](https://www.speedlink.com/en/COMPETITION-PRO-EXTRA-USB-Joystick-black-red/SL-650212-BKRD)<br>
