# SCR1 Tang Primer 20K FPGA project repository

## Repository contents
Folder | Description
------ | -----------
src             | Projects for Sipeed Tang Primer 20K FPGA Dock Kit
README.md       | This file
scr1test.gprj   | File to open project in Gowin Eda

Now the system on chip looks like this:

![alt text](https://github.com/SurfaceYellowDuck/scr1_tang_primer20k/blob/master/images/schema.jpg)

## 🖍 Used technology
![Language Stats Badge](https://img.shields.io/badge/SystemVerilog--SystemVerilog?style=flat&logoSize=blue&labelColor=blue&color=blue
)

> SCR1 is an open-source and free to use RISC-V compatible MCU-class core, designed and maintained by Syntacore. In this repository, I am porting the SCR 1 core to the Tang Primer 20K 


As can be seen from the diagram, conceptually the Cis consists of two parts: SCR 1 cluster, which contains the SCR1 core itself, imem router, dmem router, tcm memory and timer.

This repository uses the [scr1 microcontroller](https://github.com/syntacore/scr1) and [fpga-sdk-prj](https://github.com/syntacore/fpga-sdk-prj)  sources. 

The second part consists of a peripheral connected to the SCR1 cluster via the AHB bus. It consists of an asynchronous transceiver and read-only memory.
The Read-only memory contains a uart program that implements a loopback from the uart back to the sender's com port.


## Getting started
1. First you need to install the Gowin EDA.
2. Then clone project and open scr1test.gprj file
3. Now you need run "synthesize" project and push on "place and route"
4. Then you need to connect your Tang Primer 20K to PC through USB. On board you have two type-c connectors. You need one that is labeled usb-jtag.
4. Open gowin programmer and flush sram. 
5. After flushing sram you can check, that program in ROM executes by processor. If you use Windows - open Putty. Select com port, where connected fpga and speed 9600. Then in line discipline optins select parameter "local echo" to "force on". After that you can open session, send characters to uart from COM port and see that characters are coming back on your com port from fpga. 
6. Loopback for UART is a test program. In the future, it is planned to install the sc-bl loader there.
