# I use "test" instead of run since people might confuse this for the proper
# KoiOS project. Makes separating the two easier. Feel free to change if you want.
.PHONY: all run

# This is the virtual machine that will be ran when you use test/debug!!!
# By default this is a 64 Bit VM, change as needed!
VM := qemu-system-x86_64
GDB := gdb


#If you edit the disk.sfdisk script then edit these values!
# @TODO Automate this part. Tried to use XXD but didn't seem to work
# FAT Partition Starting LBA, and Sector Count
FPLBA := 2048
FPSC  := 32768

# EXT Partition Starting LBA, and Sector Count
EPLBA := 34816
EPSC  := 65536

# By default creates a 128MB disk with two partitions:
# 1: 16MB FAT12 - build/system.part
# 2: 32MB EXT2  - build/os.part
build/disk.img: build/s0.bin build/system.part build/os.part disk.sfdisk
	# Create the disk at the proper size, then format the partition table
	touch $@
	dd if=/dev/zero of=$@ bs=1M count=128
	sfdisk $@ < disk.sfdisk
	# Install the partitions, and the bootloader
	dd if=build/s0.bin of=$@ bs=446 count=1 conv=notrunc
	dd if=build/system.part of=$@ bs=512 count=${FPSC} seek=${FPLBA} conv=notrunc
	dd if=build/os.part of=$@ bs=512 count=${EPSC} seek=${EPLBA} conv=notrunc

# Build the Stage Zero MBR with NASM
build/s0.bin: Stage_Zero/s0.asm Real_Mode_Includes/disk.inc Real_Mode_Includes/string.inc
	mkdir -p build/
	nasm -f bin Stage_Zero/s0.asm -o $@

# Build the FAT12 System Partition, and put a text file on it for testing
build/system.part:
	touch $@
	touch build/sample.txt
	echo "This is a sample txt file. See you in Stage 2!" >> build/sample.txt
	dd if=/dev/zero of=$@ bs=512 count=${FPSC}
	mkfs.fat -F 12 -n KSPBOOT -S 512 -i 0xDEADBEEF $@
	mcopy -i $@ build/sample.txt ::/

# Build the EXT2 System Partition, and put a text file on it for testing
build/os.part:
	touch $@
	touch build/test.txt
	echo "This is a sample txt file, but on the EXT2 Partition! Hello Kernel World!" >> build/test.txt
	dd if=/dev/zero of=$@ bs=512 count=${EPSC}
	mkfs.ext2 $@ -L KoiOS
	e2cp build/test.txt build/os.part:/test.txt

# Run the disk image
test: build/disk.img
	${VM} -hda $<

# Run the disk image, and open GDB at the same time
debug: build/disk.img
	${VM} -hda $< -s \
	& ${GDB} -ex "target remote localhost:1234" -ex "layout asm"

# Everything made as part of the build process is left in build/
clean:
	rm -rf build/
