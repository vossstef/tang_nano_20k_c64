**Work in Progress!**

# DS Adapter Cable

This site shows how to build and connect an Adapter or an Adapter cable to the **Spare Pin Header J8**  
of the [MiSTery Nano Midi Shield by Till Harbaum](https://github.com/harbaum/MiSTeryNano/blob/main/board/misteryshield20k/README.md) to use a Playstation Dualshock 2 (DS2) Controller.

## Building your own Adapter
Use the **female** end of an DS2 Controller extension cable and cut it 25-30 centimeters behind the connector.  
Remove **carefully** the main isolation and **more carefully** the isolation of the cables.  
Be **very carefully** not to break/cut the thin wires.  

Here https://store.curiousinventor.com/guides/PS2/ you can see a variant of the cable colors from an open DS2 Controller cable.  
**Attention, you colours can be different.** Use a Multimeter for measure or beep the correct wires.  

If you have some spare female DS2 connectors you can solder direcly some small wires to the pins.

Crimp and/or solder some female dupont terminals to the needed wires.  
Use the provided pinouts and the connection table (see below) for correct position of the terminals within the terminal housing.  

See here https://www.instructables.com/Fitting-Dupont-Connectors/  
or here https://www.youtube.com/watch?v=fcP0P6OLJqA for instructions  
how to use Dupont terminals.

Finally double check your Adapter wires to make sure all pins, ***especially the voltage pins***, are at the correct position.

Your adapter could end up looking like this:  
![ds2_adaptercable](\.assets/ds2_adapter_cable.png)

If your Adapter cable is finished, make sure you connect it in the correct orientation.  
See the MiSTery Shield Board Layout (see below) for the correct position of **J8-Pin 1**, which should match **Pin 1** of your cable.  

Activate the DS2 Controller using **DS2 #2 Joy** in the Menu and have fun 😃 

### DS2 Buttons
Circle: Trigger Button #1  
Square: Trigger Button #2  
Traingle and Cross activate the "Paddle Mode" and **deactivate** actually the Direction buttons!  

### PCB based Adapter
An PCB Adapter board is currently being planned and will be released once the needed parts have arrived and been tested.  

## Pinouts and Connection Table
### Pinout of the Playstation Pad Connector
![ds2_pinmap](\.assets/ps_pad_connector.png)
  
### Pinout of the MiSTery Shield Pin Header J8
![ds2_pinmap](\.assets/pcb_m0s_j8_pinout.png)

### Connection Table
|DS2 Connector Pin|DS2 Signal Name|DS2 Function|MiSTery Shield J8 Pin|
|:---:|:---:|:---:|:---:|
|1|DAT|Pad Data|3|
|2|CMD|Pad Command|2|
|3|7.6v|Rumble Voltage|nc|
|4|GND|Ground|6|
|5|VCC|3.3v|7|
|6|ATN|Attention|4|
|7|CLK|Clock|1|
|8|IRQ|not in use|nc|
|9|ACK|Acknowledge|nc|

nc = not connected
