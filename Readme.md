# mc-2g-1024

## General description
This package is an extension on the FPGA multicomputer, as introduced by Grant Searle, which can be found [Here](http://searle.hostei.com/grant/Multicomp/index.html). It focuses on the Z80 CP/M computer described therein.

## SPECS

* New ROM monitor with **multi-boot capability**, **Format**, **Getsys** and **Putsys** tools and debug capabilities. No BASIC in ROM.
* **SD-HC** capable card controller. Init at 250 kHz, running at 25 MHz.
* Improved keyboard definition featuring external keymap and added key functionality.
* **Multi volume disk system**, which currently supports upto 253 8MB disk volumes (which uses 2GB+ on the SD-card). All these volumes can be loaded with a separate OS bootimage.
* OSes configured with 3 drives: **A:**, **B:** and **C:**. A: for the system drive (holding the volume booted from) while B: and C: can be assigned and re-assigned one of the remaining volumes. Also a RAM disk is available for CP/M 2 and CP/M 3 systems as drive **M:**.
* Y2k compatible system clock (date and time) for all OSes.
* Included are CP/M 2.2, Dos+ 2.5, CP/M 3.0, MPMII 2.1, ZSDOS 1.1/ZCPR2, ZPM3/ZCCP and NASCOM ROM Basic



## SD image

As github does not permit big files, you can get the system image from:
[Here](https://mega.nz/file/b4x3HBbI#ZSz0A_3J3G3JzT0UY21_9xDDHfIxYkqHwc6D15DRFFg).

 You have two options:

* Burn the image to a fresh SD card and use it on the secondary SD slot (I/0 board). (dd in Linux, Win32DiskImager in Windows)
* put it in the games/mc-2g-1024/ directory on your main SD card.

## Starting OS.

From the **ROM** monitor, issue the "Snnn" command *(where nnn is the volume number to boot)*.

## Boot Volumes

* 001 **DOS+ 2.5**
* 002 **CP/M 2.2**
* 003 **CP/M 3.0**
* 004 **MPMII**
* 005 **NASCOM ROM BASIC**
* 006 **ZSDOS 1.1/ZCPR2**
* 007 **ZPM3/ZCPP**

## Software volumes

There are 48 disk volumes. (each volume can have different "USER"
directories) 

## Mounting drives

The boot disk is always mapped as A: and RamDisk as M: To mount any other
disk (as B: or C:) issue the comand "MOUNT DRIVE: nnn" (where nnn is the
volume number)

## Useful links
* [CP/M 3.0 Command reference](http://www.cpm.z80.de/manuals/cpm3-cmd.pdf)
* [CP/M 2.2 Operating System Manual](http://www.cpm.z80.de/manuals/cpm22-m.pdf)
* [MP/M II User guide](http://www.cpm.z80.de/manuals/mpm2ug.pdf)
* [The humongous CP/M Software archives](http://www.classiccmp.org/cpmarchives/)
