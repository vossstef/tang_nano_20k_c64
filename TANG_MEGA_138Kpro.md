# C64 Nano on Tang Mega 138K Pro

C64 Nano can be used in the [Tang Mega 138K Pro](https://wiki.sipeed.com/hardware/en/tang/tang-mega-138k/mega-138k-pro.html).

The Tang Mega 138K Pro is bigger than the other bords supported my
MiSTeryNano. Unlike the Tang Nano 20K which is actually slightly
inferior to the original [MiST](https://github.com/mist-devel/mist-board/wiki), the Tang Mega 138K is even slightly
more powerful than the MiST's successor [MiSTer](https://mister-devel.github.io/MkDocs_MiSTer/). So while the
MiSTeryNano core does run on the Tang Mega 138K it only utilizes its
FPGA to 14%.

Besides the significantly bigger FPGA over the Tang Nano 20K and also
the Tang Primer 25K, the Tang Mega 138K adds several more features of
which some can be used in the area of retro computing as well. 

Although the Tang Mega 138K Pro comes with a significant ammount of
DDR3-SDRAM, it also comes with a slot for the [Tang
SDRAM](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#TANG_SDRAM). Using this board allows to use the same SDR-SDRAM memory access
methods. DDR3 on the other hand is not supported by regular retro
implementations like the MiSTeryNano.

Plug the optional Dualshock [DS2x2](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DS2x2) Interface into the **left PMOD** slot.<br>

The M0S required to control the C64 Nano is to be mounted in the
**middle PMOD** with the help of the [M0S PMOD adapter](board/m0s_pmod).

The **right PMOD** slot is allocated for a digital retro Joystick interface.
There is no D9 digital Joystick interface PMOD Adapter known and adhoc wiring needed.
> [!WARNING]
> Joystick interface is 3.3V tolerant and therefore the Joystick 5V supply pin has to be left floating when no level shifters are in use!<br>

|Bus|D9 Signal |D9 pin|PMOD  |FPGA pin |
| - |------    |------| ---- | ------- |
| 0 | Button 0 | 6    |  12  | B21     |
| 1 | Down     | 2    |  11  | C21     |
| 2 | Up       | 1    |  10  | A20     |
| 3 | Right    | 4    |   9  | B20     |
| 4 | Left     | 3    |   8  | A19     |
| 5 |Button 1 X| 9    |   7  | B19     |
| - |POT Y     | 5    |   6  | n.c.    |
| - | GND      | -    |   3  | GND     |
| - | +5V      |!!! n.c.|    | n.c.    |

The whole setup will look like this:

![MiSTeryNano on TM138K Pro](./.assets/ds2_m0s_pmod_tm138kpro.png)

The firmware for the M0S Dock is the [same version as for the Tang
Nano 20K](firmware/misterynano_fw/).

On the software side the setup is very simuilar to the original Tang Nano 20K based solution. The core needs to be built specifically
for the different FPGA of the Tang Primer using either the [TCL script with the GoWin command line interface](build_tm138kpro.tcl) or the
[project file for the graphical GoWin IDE](tang_mega_138kpro_c64.gprj). The resulting bitstream is flashed to the TM138K as usual.

Since the Tang Mega 138K Pro needs a bigger portion of the available flash
memory space, the DOS ROMs need to be flashed to a different memory location
on the TM.
