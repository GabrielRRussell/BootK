# I use "test" instead of run since people might confuse this for the proper
# KoiOS project. Makes separating the two easier. Feel free to change if you want.
.PHONY: all run

# This is the virtual machine that will be ran when you use test/debug!!!
# By default this is a i386 Bit VM, change as needed!
# This used to be an x64 vm, but it caused GDB to lose it's mind
# For some reason GDB wasn't recognizing the i8086 arch when using a 64bit VM
# So for now, I've set it to i386. BootK doesn't enter long mode as of now
# anyways, so this is fine. Change it if you want to.
VM := qemu-system-i386
GDB := gdb

#If you edit the disk.sfdisk script then edit these values!
#Maintain the whitespace style in the script otherwise this will break.

# Fun Fact: Makefiles automatically interpret $ as variables. If you want to
# properly use Awk variables (ex $4) you have to double escape it. $$4 is proper
# Hopefully this comment will save you a ton of time.
# System Partition Starting LBA, and Sector Count
SPLBA = ${shell awk '/BootK/ {print $$4}' disk.sfdisk}
SPSC  = ${shell awk '/BootK/ {print $$7}' disk.sfdisk}
# FAT32 Partition Starting LBA, and Sector Count
FPLBA = ${shell awk '/ESP/ {print $$4}' disk.sfdisk}
FPSC  = ${shell awk '/ESP/ {print $$7}' disk.sfdisk}

# By default creates a 128MB disk with two partitions:
# 1: 4KB RAW - build/s1.bin
# 2: 16MB FAT32- build/system.part
build/disk.img: build/s0.bin build/s1.bin build/system.part disk.sfdisk
	# Create the disk at the proper size, then format the partition table
	touch $@
	dd if=/dev/zero of=$@ bs=1M count=256
	sfdisk $@ < disk.sfdisk

	# Install the partitions, and the bootloader
	dd if=build/s0.bin of=$@ bs=446 count=1 conv=notrunc
	dd if=build/s1.bin of=$@ bs=512 count=${SPSC} seek=${SPLBA} conv=notrunc
	dd if=build/system.part of=$@ bs=512 count=${FPSC} seek=${FPLBA} conv=notrunc

# Build the Stage Zero MBR with NASM
build/s0.bin: Stage_Zero/s0.asm
	mkdir -p build/
	nasm -f bin $< -o $@

build/s1.bin: Stage_One/s1.asm
	nasm -f bin $< -o $@

# Build the FAT32 System Partition, and put a text file on it for testing
build/system.part:
	touch $@
	touch build/sample.txt
	echo "This is a sample txt file. See you in Stage 2!" >> build/sample.txt
	dd if=/dev/zero of=$@ bs=512 count=${FPSC}
	mkfs.fat -F 32 \
					 -n KSPBOOT \
					 -S 512 \
					 -i 0xDEADBEEF \
					 -D 0x80 \
					 -h ${FPLBA} $@
	mcopy -i $@ build/sample.txt ::/

# Run the disk image
test: build/disk.img
	${VM} -hda $<

# Run the disk image, and open GDB at the same time
debug: build/disk.img
	${VM} -hda $< -s -S \
	& ${GDB} -ex "target remote localhost:1234" \
					 -ex "layout regs" \
					 -ex "layout next" \
					 -ex "set architecture i8086" \
					 -ex "break *0x7C00" \
					 -ex "c"

# Everything made as part of the build process is left in build/
clean:
	rm -rf build/
