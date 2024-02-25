# Installation using a Windows PC

This document explains how to install all the necessary files on the
Tang Nano 20K and the M0S Dock in order to use it as a C64 Nano
device.

This has been tested on Windows 11. It should work on older versions too.

Software needed:

  - [Gowin V1.9.9 Beta-4 Education](https://www.gowinsemi.com/en/support/home/) **to flash the FPGA or to synthesize the core**
  - [BouffaloLabDevCube](https://dev.bouffalolab.com/download) **to flash the BL616**
  - [Latest release](https://github.com/vossstef/tang_nano_20k_c64/releases/latest) of C64Nano **FPGA** bitstream
  - [Latest release](https://github.com/harbaum/MiSTeryNano/releases/latest) of MiSTeryNano **BL616 µC firmware**

In order to use the SD card for disks:

  - c64 disk images in .D64 or .G64 format

# Flashing the Tang Nano 20k

First download the Gowin IDE. The Education version is sufficient and
won't need a licence.

Install the IDE on your system (follow the installation instructions
from Gowin).  After the Installation you should have it as an shortcut
on your desktop or in your start menu.

 - Press the ```S2``` button on the Tang Nano 20K and keep it pressed
 - Connect the Tang Nano 20k to the USB on your computer. You should hear the connecting sound of Windows.
 - Release the ```S2``` button
 - Start Gowin. **You should see the following screen**

Explanation: The C64Nano core makes use of the flash memory of the
Tang Nano 20k to store c1541 DOS ROMs. This may interfere with the FPGA
flash process. Pressing the ```S2``` during power up will prevent the
Tang Nano 20k from booting into the C64Nano core and will make sure
the flash ROM can be updated.

![](https://github.com/vossstef/tang_nano_20k_c64/blob/main/.assets/gowin1.jpg)

Now press on the “programmer” marked red on the picture above. **You
should see following screen:**

![](https://github.com/vossstef/tang_nano_20k_c64/blob/main/.assets/device.png)

-   Press save on the dialog
-   From there you can add a device for programming by pressing on the little
    icon with the green plus
-   At least three files have to be flashed:
    - The core itself: ```tang_nano_20k_c64.fs```
    - Two c1541 DOS ROMs
-   Than you can choose from the drop downs the parameter you see on the
    pictures.

**Important**:

  - ```tang_nano_20k_c64.fs``` is written to address 0x000000
  - ```reserved for Atari ST !``` address 0x100000
  - ```c1541 DOS Dolphin 2``` is written to address 0x200000
  - ```c1541 DOS CBM``` is written to address 0x208000

Optionally two additional DOS ROMs may be flashed to the alternate
addresses:

  - ```c1541 DOS Speeddos Plus``` is written to address 0x210000
  - ```c1541 DOS Jiffy``` is written to address 0x218000

These DOS for the c1541 emulation can later be selected from the on-screen-display (OSD).
  - For the FS file please choose the ```tang_nano_20k_c64.fs``` you just downloaded
  - User Code and IDCODE can be ignored
  - Mark each of your configs and press the little icon with the green play
    button. You should see a progress bar and then:

![](https://github.com/vossstef/tang_nano_20k_c64/blob/main/.assets/c64_flash.png)

**Production of c1541 DOS 32k ROM binaries** <br>
The needed DOS files you will find on the Internet.<br>
```Dolphin DOS 2```<br>
Typically you will [find](https://e4aws.silverdr.com/projects/dolphindos2/) a 32K Byte file e.g. 2dosa_c.bin that can right away be flashed.<br>
Program at offset 0x200000<br>
![](https://github.com/vossstef/tang_nano_20k_c64/blob/main/.assets/dolphin.png)

```CBM DOS```<br>You find [CBM 1541 8k low rom](https://www.zimmers.net/anonftp/pub/cbm/firmware/drives/new/1541/1541-c000.325302-01.bin) 
and 
[CBM 1541 8k high rom](https://www.zimmers.net/anonftp/pub/cbm/firmware/drives/new/1541/1541-e000.901229-05.bin)<br>
Open a command prompt and enter the directory where you downloaded the files from the Internet and type: <br>
> COPY /B 1541-c000.325302-01.bin + 1541-e000.901229-05.bin + 1541-c000.325302-01.bin + 1541-e000.901229-05.bin  c1541_cbm.bin<br>

If will create the required 32K size DOS image named c1541_cbm.bin <br>
Program at offset 0x208000<br>
![](https://github.com/vossstef/tang_nano_20k_c64/blob/main/.assets/cbm.png)

```Speed DOS Plus```<br>
You will [find](https://rr.pokefinder.org/wiki/Speed_DOS#Binaries) 
a 32K Byte file e.g. c1541-20-8.rom that can right away be flashed.<br>
Program at offset 0x210000<br>
![](https://github.com/vossstef/tang_nano_20k_c64/blob/main/.assets/speed.png)

```Jiffy DOS```<br>
You find [CBM 1541 8k low rom](https://www.zimmers.net/anonftp/pub/cbm/firmware/drives/new/1541/1541-c000.325302-01.bin) 
and get a 8k [JiffyDos](https://www.go4retro.com/products/jiffydos/) file.
Open a command prompt and enter the directory where you downloaded the file from the Internet and type: <br>
> COPY /B 1541-c000.325302-01.bin + JiffyDOS_1541.bin + 1541-c000.325302-01.bin + JiffyDOS_1541.bin  c1541_jiffy.bin

If will create the required 32K size DOS image named c1541_jiffy.bin <br>
Program at offset 0x218000<br>
![](https://github.com/vossstef/tang_nano_20k_c64/blob/main/.assets/jiffy.png)

**That´s it for the Tang Nano 20k**

## Flashing the BL616 µC

For the BL616 you have to extract and start the BuffaloLabDevCube. 

**If you use the internal BL616 present on the Tang Nano 20K you loose
your possibility to flash the Tang over the USB connection.** It is thus
strongly recommended to use an external BL616 (e.g. a M0S Dock).

However, when using the internal BL616 you will be able to flash the
[original firmware](https://github.com/harbaum/MiSTeryNano/blob/main/bl616/friend_20k)
to the internal BL616 again to restore the flasher functionality of
the Tang Nano 20K. Using an external M0S is nevertheless recommended.

-   Press the ```BOOT``` button on your M0S Dock before you plug the USB connection
    on your PC. You should hear the hardware detecting sound.
-   Start the BuffaloLabDevCube from the directory where you decompressed it it
    ask you what chip should be used. Select BL616/BL618 and press “finish”

![](https://github.com/vossstef/tang_nano_20k_c64/blob/main/.assets/buffstart.png)

- You'll now see the program screen. On the right it should auto detect your
  device with a COM port. If not take a look in the device manager to check for
  the correct device detection.
- On the top click on MCU and browse to the firmware image file named
  ```misterynano_fw_bl616.bin``` (contains a unified firmware both for Atari ST and C64Nano)
- Choose “Open Uart” and than press “Create & Download”. The firmware should now be
  flashed

![](https://github.com/vossstef/tang_nano_20k_c64/blob/main/.assets/bufffinish.png)

## Prepare the SD card

Format the SD card in FAT32. Copy your D64 / G64 files files on
it. You can organize your files in subdirectories. These files can later
be selected using the on-screen-display (OSD).
Copy a D64 Disk image to your sdcard and rename it to disk8.d64 as default boot image.

That´s it for now. Have fun using the C64Nano
