# BootK
The premier x86 Bootloader for KoiOS!

![A rectangular minimalist art piece, with a drawing of a yellow bouquet of pink flowers to the left. Above it is the text 'BootK', with a green circle reaching around the bouquet of flowers. The background is a green and white gradient.](assets/headerlogo.png)
_____________
# Prerequisites
You'll need the following utilities installed:
- NASM - Assembler
- Parted - Scripting disk image partitions
- mkfs - Formatting various filesystems
- e2tools - EXT2 Disk Image Operations
- qemu-system-x86_64 (or any other 32/64bit x86 VM of your choice)
- gdb - Debugging the boot loader
_____________
# Building
As long as you have the above utilities installed, edit the makefile to fit what your needs. You do NOT need root permissions to build the disk image, since this build script does not take advantage of loop devices, or mount the disk images. It uses entirely userspace tools to do so, as long as you have the proper prerequisites installed. Most of these should be included on your Distro, but I'm running on a Debian based OS. The only tools I had to install using my package manager were NASM, e2tools, and qemu.

Use ```make``` to build a bootable disk image.  
Use ```make test``` to make and boot the image in a VM.  
Use ```make debug``` to open the image in a VM, and connect GDB to it in ASM layout.  
Use ```make clean``` to remove non-source files in the directory.
_____________
# Other Info
BootK is a 2 Stage Loader by default. Building the image will generate a 128MB disk image, that is formatted as GPT. BootK currently works only on BIOS machines, but will eventually include UEFI. BootK does not support MBR formatted disks. There will be two required partitions:
1. RAW, 4KB - This is used to store the first stage for BIOS machines.
2. FAT32, 32MB - This is the ESP for UEFI machines, and stores a config file for BootK.

The RAW partition is for BIOS systems to load the first stage of BootK, and must not be modified. It has no filesystem. The FAT32 partition is the EFI System Partition, and stores a configuration file that is loaded by BootK, and it will also eventually store the EFI executable used to load the OS on UEFI based systems. On BIOS machines, the Bootsector will load the raw executable from the first partition, and run it at 0x8000

BootK is not quite yet ready for booting other Operating Systems. It will be in the future though, so keep an eye out!

# Credits and Thanks
Software, Code, Documentation:
- [osdev.org](https://osdev.org) Forum/Wiki, and it's users
- Everyone on [/r/OSDev on Reddit](https://reddit.com/r/osdev)
- [Jonas 'Sortie' Termansen!](https://maxsi.org/) For your kind words and help :)
- [William Atkinson](https://devwillatkinson.com/), for helping me stay motivated during the original project
- Mel, for drawing the art used for BootK and KoiOS! [Twitter,](https://twitter.com/Little_Ly_Arts) [Tumblr](https://littlelyarts.tumblr.com/)
- And a very big **THANK YOU!** to the maintainers of all of the software I use!
