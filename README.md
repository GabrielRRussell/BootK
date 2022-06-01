# BootK
The premier x86 Bootloader for KoiOS!

![A rectangular minimalist art piece, with a drawing of a yellow bouquet of pink flowers to the left. Above it is the text 'BootK', with a green circle reaching around the bouquet of flowers. The background is a green and white gradient.](assets/headerlogo.png)
_____________
# Prerequisites
You'll need the following utilities installed:
- NASM - Assembler
- sfdisk - Scripting disk image partitions
- mkfs - Formatting various filesystems
- e2tools - EXT2 Disk Image Operations
- qemu-system-x86_64 (or any other 32/64bit x86 VM of your choice)
- gdb - Debugging the boot loader
_____________
# Building
As long as you have the above utilities installed, edit the makefile to fit what your needs. You do NOT need root permissions to build the disk image, since this build script does not take advantage of loop devices, or mount the disk images. It uses entirely userspace tools to do so, as long as you have the proper prerequisites installed. Most of thse should be included on your Distro, but I'm running on a Debian based OS. The only tools I had to install using my package manager were NASM, e2tools, and qemu.

Use ```make``` to build a bootable disk image.  
Use ```make test``` to make and boot the image in a VM.  
Use ```make debug``` to open the image in a VM, and connect GDB to it in ASM layout.
Use ```make clean``` to remove non-source files in the directory.
_____________
# Other Info
BootK is a 3 Stage Loader by default for KoiOS's sake. It doesn't have to be this way by default, but we'll cover default use case first. First things first: building the image will generate a 128MB disk image, that is formatted as MBR. There will be two partitions:
1. FAT12, 16MB - This is used for the First/Second Stage (Marked Active 0x80)
2. EXT2, 32MB - This is used for the Operating System.

You are free to extend the EXT2 partition, but do not edit the FAT12 partition. The FAT12 partition is a system partition used to locate and load a configuration file for the operating system, which is located on it's own partition.

The system has a Stage Zero chainloader installed in the MBR by default. This is not required by the rest of the boot process, and is merely the default MBR for KoiOS. The chainloader searches the MBR for an active partition, and loads the VMBR from the first one it finds into ```0x0000:0x7C00```, with *SI* pointing to the partition entry that it loaded, and *DL* with the drive number. Since the default MBR is standard compliant, you can replace it with whatever you want, as Stage One and Stage Two in FAT12 partition will handle booting the OS.

BootK is not quite yet ready for booting other Operating Systems. It will be in the future though, so keep an eye out!
_____________
# Credits and Thanks
Software, Code, Documentation:
- [osdev.org](osdev.org) Forum/Wiki, and it's users
- Everyone on [/r/OSDev on Reddit](reddit.com/r/osdev)
- [Jonas 'Sortie' Termansen!](https://maxsi.org/) For your kind words and help :)
- [William Atkinson](https://devwillatkinson.com/), for helping me stay motivated during the original project
- Mel, for drawing the art used for BootK and KoiOS! [Twitter,](https://twitter.com/Little_Ly_Arts) [Tumblr](https://littlelyarts.tumblr.com/)
- And a very big **THANK YOU!** to the maintainers of all of the software I use!
