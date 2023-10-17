# tang_nano_20k_c64
[C64](https://en.wikipedia.org/wiki/Commodore_64) living in a [Gowin GW2AR](https://www.gowinsemi.com/en/product/detail/38/) FPGA on a [Sipeed Tang Nano 20k](https://api.dl.sipeed.com/shareURL/TANG/Nano_20K) with HDMI Video and Audio Output.<br>
<br>
Original C64 core by Peter Wendrich<br>
Dram controller by Till Harbaum

Features:
* HDMI 720x576p @50Hz Video and Audio Output
* PS/2 Keyboard
* Joystick (Atari / Commodore digital type)<br>


**Note** ENTIRE PROJECT IS STILL WORK IN PROGRESS AND ON A PROOF OF CONCEPT LEVEL!</b> 
<br>So far Video/Audio/Keyboard/Joystick/Cartride working.<br>
Dedicated .fs bitstream for default configuration and .fs for cartridge ROM demo included.
<br><br>
**Info** HDMI Signal 720x576p@50Hz isn't an official [VESA](https://glenwing.github.io/docs/VESA-DMT-1.13.pdf) mode.<br>
Working on e.g. BENQ GL2450HM (FHD) , Acer VN247 (FHD), Dell S2721DGF (2k), LG 27UP85NP (4K). Check [EDID](https://en.wikipedia.org/wiki/Extended_Display_Identification_Data) of your target display for support. [Monitor Asset Manager](http://www.entechtaiwan.com/util/moninfo.shtm) or an [EDID Database](https://github.com/bsdhw/EDID) might help to figure out.<br>

## Push Button utilization
* S1 push button Reset
* S2 to select in between Joystick port 1 or 2 (active port indicated by LED 0). You have to toggle for this release!
## Powering
Prototype circuit with Keyboard can be powered by Tang USB-C connector from PC or a Power Supply Adapter. 
## Synthesis
Source code can be synthesized, fitted and programmed with GOWIN IDE Windows or Linux.<br>
Chage in fpga64_buslogic.vhd the attribute cartride to '1' if you want to compile a cartrige load varaint.
## Pin mapping 
see pin configuration in .cst configuration file
## cartride ROM
The bin2mi tool can be used to generate from a game ROM new pROM VHDL code (bin2mi xyz.crt xyz.mi)<br>
From typical [.CRT](https://vice-emu.sourceforge.io/vice_17.html) images the first 0x40 bytes need to be discarded and filesize header in .mi need to be fixed to 8192/16384.<br>
## HW circuit considerations
- PS/2 keyboard has to be connected to 3.3V tolerant FPGA via level shifter to avoid damage of inputs ! Use e.g. 2 pcs SN74LVC1G17DBVR 5V to 3V3 level shifter.<br> Add 10K pull-up resistors to Tang 5V for PS/2 Clock and Data Signals directly coming from Keyboard.
- Joystick interface is 3.3V tolerant. Joystick 5V supply pin has to be left floating !
- Tang Nano 5V output (J5 1) connected to Keyboard supply. Tang 3V3 output (J5 16) to level shifter supply.

**Pinmap D-SUB 9 Joystick Interface** <br>
![pinmap](\.assets/vic20-Joystick.png)

| Joystick pin | Tang Nano pin | FPGA pin | Joystick Function |
| ----------- | ---   | --------  | ----- |
| 1 | J6 1  | 73   | Joy3 RIGHT |
| 2 | J6 2  | 74 | Joy2 LEFT |
| 3 | J6 3  | 75 | Joy1 DOWN |
| 4 | J5 13 | 86 | Joy0 UP | 
| 5 | n.c. | n.c. | POT Y |
| 6 | J5 14 | 79 | FIRE B.|
| 7 | n.c. | n.c. | 5V |
| 8 | J5 20 | - | GND |
| 9 | n.c. | n.c. | POT X |

**Pinmap PS2 Interface** <br>
![pinmap](\.assets/ps2conn.png)

| PS2 pin | Tang Nano pin | FPGA pin | PS2 Function |
| ----------- | ---   | --------  | ----- |
| 1 | J5 3 | 76   | DATA  |
| 2 | n.c. | - | n.c. |
| 3 | J5 2 | - | GND |
| 4 | J5 1 | - | +5V |
| 5 | J5 18| 71 | CLK |
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
