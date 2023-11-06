# tang_nano_20k_c64
[C64](https://en.wikipedia.org/wiki/Commodore_64) living in a [Gowin GW2AR](https://www.gowinsemi.com/en/product/detail/38/) FPGA on a [Sipeed Tang Nano 20k](https://api.dl.sipeed.com/shareURL/TANG/Nano_20K) with HDMI Video and Audio Output.<br>
<br>
Original C64 core by Peter Wendrich<br>
Dram controller by Till Harbaum<br>
c1541 by https://github.com/darfpga (https://darfpga.blogspot.com)<br> 

Features:
* HDMI 720x576p @50Hz Video and Audio Output
* PS/2 Keyboard
* Joystick (Atari / Commodore digital type)<br>
* Joystick emulation on Keyboard Numpad<br>
* emulated 1541 Diskdrive on **raw** microSD card <br>

<font color="red">Both PS/2 KEYBOAD AND digital JOYSTICK pinmaps aligned to match</font> [MiSTeryNano project](https://github.com/harbaum/MiSTeryNano). Didn't tested yet but the described USB Keyboard to PS/2 converter based on [M0S Dock](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html) should work too.

**Note** ENTIRE PROJECT IS STILL WORK IN PROGRESS</b>
<br>So far Video/Audio/Keyboard/Joystick/Cartride/c1541_sd working.<br>
Dedicated .fs bitstream for default configuration and .fs for cartridge ROM demo included.
<br><br>
**Info** HDMI Signal 720x576p@50Hz isn't an official [VESA](https://glenwing.github.io/docs/VESA-DMT-1.13.pdf) mode.<br>
Working on e.g. BENQ GL2450HM (FHD) , Acer VN247 (FHD), Dell S2721DGF (2k), LG 27UP85NP (4K). Check [EDID](https://en.wikipedia.org/wiki/Extended_Display_Identification_Data) timing of your target display for support. [Monitor Asset Manager](http://www.entechtaiwan.com/util/moninfo.shtm) might help to figure out.<br>

## emulated Diskdrive 1541
Emulated 1541 on a raw microSD card (no FAT fs !)<br>
Place one or more [.D64](https://vice-emu.sourceforge.io/vice_toc.html#TOC405) file in the tools folder and run 'create_C64_ALL_D64.bat'. It will create a DISKSRAWC64.IMG.<br> Use e.g. [win32diskimager](https://sourceforge.net/projects/win32diskimager/) to program a microSD card with DISKSRAWC64.IMG. BE CAREFUL NOT WRITING ON YOUR OWN HARDDRIVE! Insert card in TN slot.<br>
LED 1 is the Drive activity indicator.<br> For those who forgot after all those years...<br>
Disk directory listing: <br>
LOAD"$",8<br>
LIST<br> 
Load first program from Disk:<br>
LOAD"*",8<br>
RUN<br>
D64 Image on sdcard can be selected by CTRL+F8 (LED 2+3 will give a hint) followed by a Drive Reset pushing CTRL+F11. Sorry no OSD selection yet...

## Push Button utilization
* S1 push button Reset<br>
* S2 to select physical Joystick in between [c64 Joystick port ](https://www.c64-wiki.com/wiki/Control_Port) 1 or 2 (selected port indicated by LED 0).<br>
## Keyboard 
* left CTRL+F1 toggle Numpad Joystick emulation:<br>
 	'default' - PORT 1 = Joystick or JOYKEYS on Numpad, PORT 2 = unused<br>
	'toggle' - PORT 1 = unused,            PORT 2 = Joystick or JOYKEYS on Numpad <br>
    Keypad layout: left 4, right 6, up 8, down 2 and fire 0
* left CTRL+F8 change selected disk image on internal 1541 SD card<br>
          - left CTRL + F8 next image<br>
          - left CTRL + shift + F8  previous image<br>
* left CTRL+F11 c1541_sd drive Reset (you have to press once after image selection change and wait for 2 sec) <br>

Keyboard specific keys:<br>

| US KB | GER KB | c64|
| ----------- | ---   | --------  |
| Esc                | Esc | run stop |
| <code>&#91;</code> | ü   | @ |
| <code>&#93;</code> | *   | * |
| \\ | #   | up arrow |
| ` | esc   | left arrow |
| ' | ä   | semi colon |
|  | ö   | colon |
| F9 | F9   | &pound; |
| F10 | F10   | + |
| Left Alt | Left Alt | commodore key |

## LED
0 Joystick selection indication<br>
1 1541 drive activity<br>
2 Disk image indicator bit 0<br>
3 Disk image indicator bit 1<br>

## Powering
Prototype circuit with Keyboard can be powered by Tang USB-C connector from PC or a Power Supply Adapter. 
## Synthesis
Source code can be synthesized, fitted and programmed with GOWIN IDE Windows or Linux.<br>
Chage in fpga64_buslogic.vhd the attribute cartride to '1' if you want to compile a cartrige load varaint.
## Pin mapping 
see pin configuration in .cst configuration file
## cartride ROM
The bin2mi tool can be used to generate from a game ROM new pROM VHDL code (bin2mi xyz.crt xyz.mi)<br>
From typical [.CRT](https://vice-emu.sourceforge.io/vice_17.html#SEC429) images the first 0x40 bytes need to be discarded and filesize header in .mi need to be fixed to 8192/16384.<br>
## HW circuit considerations
- PS/2 keyboard has to be connected to 3.3V tolerant FPGA via level shifter to avoid damage of inputs ! Use e.g. 2 pcs SN74LVC1G17DBVR 5V to 3V3 level shifter.<br> Add 10K pull-up resistors to Tang 5V for PS/2 Clock and Data Signals directly coming from Keyboard.
- Joystick interface is 3.3V tolerant. Joystick 5V supply pin has to be left floating !
- Tang Nano 5V output (J5 1) connected to Keyboard supply. Tang 3V3 output (J5 16) to level shifter supply.

**Pinmap D-SUB 9 Joystick Interface** <br>
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

**Pinmap PS2 Interface** <br>
![pinmap](\.assets/ps2conn.png)

| PS2 pin | Tang Nano pin | FPGA pin | PS2 Function |
| ----------- | ---   | --------  | ----- |
| 1 | J5 6 | 41   | DATA  |
| 2 | n.c. | - | n.c. |
| 3 | J5 2 | - | GND |
| 4 | J5 1 | - | +5V |
| 5 | J5 5| 42 | CLK |
| 6 | n.c. | - | n.c |

### BOM

[Sipeed Tang Nano 20k](https://api.dl.sipeed.com/shareURL/TANG/Nano%209K/1_Specification)<br> 
D-SUB 9 M connector<br> 
Commodore/[Atari](https://en.wikipedia.org/wiki/Atari_CX40_joystick) compatible Joystick<br>
PS/2 Keyboard<br>
PS/2 Socket Adapter Module<br>
2 x 10K Resistor<br>
2 pcs [SN74LVC1G17DBVR](http://www.ti.com/document-viewer/SN74LVC1G17/datasheet) level shifter<br>
Prototype Board<br>
TFT Monitor with HDMI Input<br>
microSD or microSDHC card<br>
<br>
Not tested yet !!!<br>
alternative Keyboard option:<br>
USB Keyboard<br>
[M0S Dock](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html)<br>
USB-C to USB-A adapter to connect regular USB devices to the M0S Dock<br>
[USB Keyboard firmware for M0S Dock](https://github.com/harbaum/MiSTeryNano/tree/d61060803bd5839fd0dca355d45b596c87f65832/bl616)<br>
<br>
alternative Joystick option:<br>
a 2nd M0S Dock and a 2nd USB-C to USB-A adapter<br>
USB Joystick [COMPETITION PRO](https://www.speedlink.com/en/COMPETITION-PRO-EXTRA-USB-Joystick-black-red/SL-650212-BKRD)<br>
[USB Joystick firmware for M0S Dock](https://github.com/harbaum/Pacman-TangNano9k/tree/2b078bfd923d8f4e174b177ab0912dd4eef6a7f2/m0sdock_usb_joystick)
