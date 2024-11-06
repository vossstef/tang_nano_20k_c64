# C64 Nano on Tang Mega 60K NEO

C64 Nano can be used in the [Tang Mega 60K NEO](https://wiki.sipeed.com/hardware/en/tang/tang-mega-60k/mega-60k.html).

Besides the significantly bigger FPGA over the Tang Nano 20K, the Tang Mega 60K adds several more features of
which some can be used in the area of retro computing as well. 

Although the Tang Mega 60K comes with a significant ammount of
DDR3-SDRAM, it also comes with a slot for the [Tang
SDRAM](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#TANG_SDRAM). Using this board allows to use the same SDR-SDRAM memory access methods.<br> The capacitors on my TANG_SDRAM are a bit too lange and touching the 60k SOM plug module. Use duct tape to cover the capacitors avoiding shortcuts.

The M0S required to control the C64 Nano is to be mounted in the
**right PMOD** close to the HDMI connector with the help of the [M0S PMOD adapter](board/m0s_pmod).

Plug the optional Dualshock [DS2x2](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DS2x2) Interface into the **edge PMOD** slot.<br>

The whole setup will look like this:

![MiSTeryNano on TM60K NEO](./.assets/mega60k.png)

The firmware for the M0S Dock is the [same version as for the Tang
Nano 20K](firmware/misterynano_fw/).

On the software side the setup is very simuilar to the original Tang Nano 20K based solution. The core needs to be built specifically
for the different FPGA of the Tang Primer using either the [TCL script with the GoWin command line interface](build_tm60k.tcl) or the
[project file for the graphical GoWin IDE](tang_mega_60k_c64.gprj). The resulting bitstream is flashed to the TM60K as usual needing latest Gowin Programmer GUI 1.9.10.03 or newer.

Since the Tang Mega 60K needs a bigger portion of the available flash
memory space, the DOS ROMs need to be flashed to a different memory location
on the TM60K.
