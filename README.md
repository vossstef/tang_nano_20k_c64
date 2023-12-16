# tang_nano_20k_c64
[C64](https://en.wikipedia.org/wiki/Commodore_64) living in a [Gowin GW2AR](https://www.gowinsemi.com/en/product/detail/38/) FPGA on a [Sipeed Tang Nano 20k](https://api.dl.sipeed.com/shareURL/TANG/Nano_20K) with HDMI Video and Audio Output.<br>
<br>
Original C64 core by Peter Wendrich<br>
Dram controller and [BL616 MCU](https://en.bouffalolab.com/product/?type=detail&id=25) µC firmware by Till Harbaum<br>
c1541 by https://github.com/darfpga<br>

Features:
* HDMI 720x576p @50Hz Video and Audio Output
* USB Keyboard via [Sipeed M0S Dock BL616 µC](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html) (future plan Tang onboard µC)
* USB Joystick via [Sipeed M0S Dock BL616 µC](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html) (future plan Tang onboard µC)
* [legacy Joystick](https://en.wikipedia.org/wiki/Atari_CX40_joystick) (Atari / Commodore digital type)<br>
* Joystick emulation on Keyboard Numpad<br>
* [Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock) as Joystick<br>
* emulated [1541 Diskdrive](https://en.wikipedia.org/wiki/Commodore_1541) on **raw** microSD card with [Userport](https://www.c64-wiki.com/wiki/User_Port) parallel bus [Speedloader](https://www.c64-wiki.com/wiki/SpeedDOS)<br>
* OSD partially<br>

<font color="red">HMI interfaces aligned in pinmap and control to match</font> [MiSTeryNano project's bl616 misterynano_fw](https://github.com/harbaum/MiSTeryNano/tree/main/bl616/misterynano_fw).<br> Basically BL616 µC acts as USB host for a USB keyboard, USB Joystick and OSD controller using a [SPI communication protocol](https://github.com/harbaum/MiSTeryNano/blob/main/bl616/misterynano_fw/SPI.md). Have a look MiSTeryNano readme chapter 'Installation of the MCU firmware' to get an idea how to install the needed Firmware. 

**Note** ENTIRE PROJECT IS STILL WORK IN PROGRESS</b>
<br>So far Video/Audio/Keyboard/Joystick/Cartride/c1541_sd working.<br>
Dedicated .fs bitstream for default configuration and .fs for cartridge ROM demo included.
<br><br>

## emulated Diskdrive 1541
Emulated 1541 on a raw microSD card (no FAT fs !) including parallel bus Speedloader.<br>
Place one or more [.D64](https://vice-emu.sourceforge.io/vice_toc.html#TOC405) file in the tools folder and run 'create_C64_ALL_D64.bat'. It will create a DISKSRAWC64.IMG. Use only SIMPLE D64 files : 174 848 octets (35 Tracks)<br> Use e.g. [win32diskimager](https://sourceforge.net/projects/win32diskimager/) or [Balena Etcher](https://etcher.balena.io) to program a microSD card with DISKSRAWC64.IMG. BE CAREFUL NOT WRITING ON YOUR OWN HARDDRIVE! Insert card in TN slot.<br>
LED 1 is the Drive activity indicator.<br> For those who forgot after all those years...<br>
Disk directory listing: (or F7 keypress)<br> 
LOAD"$",8<br>
LIST<br> 
Load first program from Disk:<br>
LOAD"*",8<br>
RUN<br>
Multiple D64 images on sdcard can be selected by Numpad '+' forwards followed by a Drive Reset pushing Numpad 'Enter' or one image backwards by Numpad '-' and Numpad 'Enter'. Sorry no OSD selection yet...
## Push Button utilization
* S2 push button Reset<br>
* S1 to swap physical Joystick or GamePad in between [c64 Joystick ports ](https://www.c64-wiki.com/wiki/Control_Port) 1 or 2 (selected port indicated by LED 0). Two Player control.<br>

## OSD
invoke by F12 keypress<br>
* Reset<br>
* Audio Volume<br>
* Scanlines
<br>don't touch Drive A/B, as not implemented yet<br>
Note: You might need to increase audio volume to 100%.

## Gamecontrol Joystick support
legacy Digital Joystick<br>
or<br>
USB Joystick<br>
or<br>
Gamepad Right **stick** for Move and Left **L1** shoulder Button for Fire or following **Pad** controls:<br>
| Buttons | - | - |
| - | - | -  |
| Left L1<br>Fire | triangle button<br>Up  | .  |
| square button<br>Left | - | circle button<br>Right |
| - | cross button<br>Down | - |<br>

or Keyboard **Numpad** Keys:<br>
| | | |
|-|-|-|
|0<br>Fire|8<br>Up|-|
|4<br>Left|-|6<br>Right|
|-|2<br>Down|-|


## Keyboard 
* Numpad '*' toggle Numpad Joystick emulation:<br>
 	'default' - PORT 1 = Joystick or JOYKEYS on Numpad, PORT 2 = Gamepad<br>
	'toggle' - PORT 1 = Gamepad,            PORT 2 = Joystick or JOYKEYS on Numpad <br>
    Keypad layout: left 4, right 6, up 8, down 2 and fire 0
* Numpad  change selected disk image on internal 1541 SD card<br>
          - Numpad '+' next image<br>
          - Numpad '-'  previous image<br>
* Numpad 'Enter' c1541_sd drive Reset (you have to press once after image selection change and wait for 2 sec) <br>

[Layout](https://github.com/MiSTer-devel/C64_MiSTer/blob/master/keymap.gif) similar with some enhancements.

## LED
0 Joystick selection indication<br>
1 c1541 drive activity<br>

## Powering
Prototype circuit with Keyboard can be powered by Tang USB-C connector from PC or a Power Supply Adapter. 
## Synthesis
Source code can be synthesized, fitted and programmed with GOWIN IDE Windows or Linux.<br>
## Pin mapping 
see pin configuration in .cst configuration file
## cartride ROM
The bin2mi tool can be used to generate from a game ROM new pROM VHDL code (bin2mi xyz.crt xyz.mi)<br>
From typical [.CRT](https://vice-emu.sourceforge.io/vice_17.html#SEC429) images the first 0x40 bytes need to be discarded and filesize header in .mi need to be fixed to 8192/16384.<br>Change in fpga64_buslogic.vhd (see comment) and top level (exrom = '0') needed to compile a cartrige load varaint.
## HW circuit considerations
**Pinmap TN20k Interfaces** <br>
 Sipeed M0S Dock and digital Joystick D9 connection. Dualshock 2 Controller not shown as default according to circuit diagram.<br>
 ![wiring](\.assets/wiring_spi.png)

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
![pinmap](\.assets/controller-pinout.jpg)
| DS pin | Tang Nano pin | FPGA pin | DS Function |
| ----------- | ---   | --------  | ----- |
| 1 | J6 17 | 19 MISO | JOYDAT  |
| 2 | J6 16 | 20 MOSI  | JOYCMD |
| 3 | n.c. | - | 7V5 |
| 4 | J6 20 | - | GND |
| 5 | J6 19| - | 3V3 |
| 6 | J6 18 | 18 CS | JOYn|
| 7 | J6 15 | 17 MCLK | JOYCLK |
| 8 | n.c. | - | IRQ |
| 9 | n.c. | - | ACK |

### BOM

[Sipeed Tang Nano 20k](https://api.dl.sipeed.com/shareURL/TANG/Nano%209K/1_Specification)<br> 
D-SUB 9 M connector<br> 
Commodore/[Atari](https://en.wikipedia.org/wiki/Atari_CX40_joystick) compatible Joystick<br>
Prototype Board<br>
TFT Monitor with HDMI Input<br>
microSD or microSDHC card<br>
USB Keyboard<br>
[Sipeed M0S Dock](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html)<br>
USB-C to USB-A adapter to connect regular USB devices to the M0S Dock or alternatively a 4 port [mini USB hub](https://a.aliexpress.com/_EIidgjH)<br>
[firmware for M0S Dock](https://github.com/harbaum/MiSTeryNano/tree/main/bl616/misterynano_fw)<br>
<br>
alternative Gamecontrol option:<br>
Sipeed Gamepad Adapter for Tang FPGA<br>
[Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock)<br>
[USB Joystick](https://www.speedlink.com/en/COMPETITION-PRO-EXTRA-USB-Joystick-black-red/SL-650212-BKRD)<br>
