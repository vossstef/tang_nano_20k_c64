# C64 Nano on Tang Mega 60K NEO

C64 Nano can be used in the [Tang Mega 60K NEO](https://wiki.sipeed.com/hardware/en/tang/tang-mega-60k/mega-60k.html).

Besides the significantly bigger FPGA over the Tang Nano 20K, the Tang Mega 60K adds several more features of
which some can be used in the area of retro computing as well. 

Although the Tang Mega 60K comes with a significant ammount of
DDR3-SDRAM, it also comes with a slot for the [Tang
SDRAM](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#TANG_SDRAM). Using this board allows to use the same SDR-SDRAM memory access methods.<br> 

The M0S required to control the C64 Nano is to be mounted in the
**right PMOD** close to the HDMI connector with the help of the [M0S PMOD adapter](board/m0s_pmod).

Plug the optional Dualshock [DS2x2](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DS2x2) Interface into the **edge PMOD** slot.<br>

The **SDRAM 1** slot is allocated for a digital retro Joystick interface.  
A 40 pole 2.54mm pinheader need to be soldered into the Meag 60k NEO.
An 40 pole receptable to be used connecting the 7 signals to the D9 connector.
> [!WARNING]
> Joystick interface is 3.3V tolerant and therefore the Joystick 5V supply pin has to be left floating when no level shifters are in use!<br>

|Bus|Signal    | D9   |40-pol| Name     |FPGA pin |
| - |------    |------| ---- |----------| ------- |
| 0 | Button 0 | 6    |  36  |SDRAM1_A10|  U17    |
| 1 | Down     | 2    |  35  |SDRAM1_BA1|  U18    |
| 2 | Up       | 1    |  10  |SDRAM1_D14|  V17    |
| 3 | Right    | 4    |   9  |SDRAM1_D15|  W17    |
| 4 | Left     | 3    |  32  |SDRAM1_RAS|  Y18    |
| 5 |Button 1 X| 9    |  31  |SDRAM1_CAS|  Y19    |
| - |POT Y     | 5    |  -   |          |  n.c.   |
| - | GND      | -    |  12  |GND       |  GND    |
| - | +5V      |!!! n.c.|11  |          |  n.c.   |

The whole setup will look like this:

![MiSTeryNano on TM60K NEO](./.assets/mega60k.png)

The firmware for the M0S Dock is the [same version as for the Tang
Nano 20K](firmware/misterynano_fw/).

On the software side the setup is very simuilar to the original Tang Nano 20K based solution. The core needs to be built specifically
for the different FPGA of the Tang Primer using either the [TCL script with the GoWin command line interface](build_tm60k.tcl) or the
[project file for the graphical GoWin IDE](tang_mega_60k_c64.gprj). The resulting bitstream is flashed to the TM60K as usual needing latest Gowin Programmer GUI 1.9.10.03 or newer.


**HW modification**  
[Tang SDRAM Module](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#TANG_SDRAM) V1.2 modification to fit on the TM60k NEO dock.<br>
The capacitors are a bit too lange and touching the 60k FPGA plug-module.  
Use duct tape to cover the capacitors avoiding shortcuts or unsolder three that are blocking.  
There is a also newer Version 1.3 of the TANG_SDRAM available (90° angle) that likely fit. 
![parts](./.assets/sdram_mod.png)


