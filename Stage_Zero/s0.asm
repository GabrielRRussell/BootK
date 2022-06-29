; s0.asm - Stage 0 BootK
; Developed with NASM

;MIT License

;Copyright (c) 2022 Gabriel Robert Louis Russell

;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:

;The above copyright notice and this permission notice shall be included in all
;copies or substantial portions of the Software.

;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;SOFTWARE.

; Assembly Code Styling:
; Tabs, 2 Spaces Each
; codeLabels are camelCase
; variable_and_data_labels are snake_case

; 0x0000 - 0x03FF : IVT (1Kb) <-- Important later on, not right now
; 0x0500 - 0x7BFF : Free Memory (~29.7Kb) <-- Stack goes here
; 0x7C00 - 0x7DFF : Bootsector (512b) <-- YOU ARE HERE
; 0x7E00 - 0x0007.FFFF : Free Memory (480.5Kb) <-- Loading Stage 1 here

; This code expects a GPT formatted drive, and looks for the RAW partition,
; Loads this partition to 0x8000, and then jumps to it.

; Set our origin to 0x7C00 since that's where we're loaded to
; BIOS puts us in Real Mode (16 Bits), so we tell the assembler
[org 0x7C00]
[bits 16]

setup:
  ; Disable Interrupts
  cli

  ; Set Data,Extra,Stack Segment Registers to 0
  xor ax, ax
  mov ds, ax
  mov es, ax
  mov ss, ax

  ; Properly set up the stack at free memory 0x7000, reference chart above
  mov bp, 0x7000
  mov sp, bp

  ; Save Boot Drive to our variable
  mov [var_boot_drive], dl

  ; Should be safe to re-enable interrupts now
  sti

  ; Set Code Segment to 0
  jmp 0:start

start:
  ; Loading LBA 1 (Partition Table Header) to 0x0000:0x0500
  mov eax, 1
  mov di, 0x0500
  mov cx, 1
  mov dl, byte [var_boot_drive]
  call readSectorsLBA
  jc diskReadError

  ; Okay, sector is loaded. Let's make sure it's actually a GPT disk.
  ; Verify the signature. 8 Bytes
  mov si, 0x0500
  mov di, const_gpt_signature
  mov cx, 8
  call compareString
  jne diskFormatError

  ; Cool, it's a GPT disk. Good to know. Let's load the Partition Entries
  ; Each Entry is 128 Bytes large, so we can fit 4 into a single sector.
  ; We're going to take a shortcut and assume it's inside the first 4 sectors
  ; @TODO: Change this to something more efficient once we get past POC stage.

  mov ax, [0x0548]
  mov di, 0x0500
  mov cx, 4
  mov dl, byte [var_boot_drive]
  call readSectorsLBA
  jc diskReadError
  ; 2KB Loaded to 0x0500, read the first 16 sectors

findPartition:
  ; We loaded our sectors to 0x0500
  ; We only need to look through the first 16 entries until we find it.
  mov bx, 16
  mov si, 0x0500
.loop:
  ; Compare the identifier to what we're looking for.
  mov di, const_stage1_signature
  mov cx, 16
  call compareString
  je .exit
  ; Have we run out of entries?
  dec bx
  jz .error
  ; Load the next entry, every 128 Bytes
  add si, 0x80
  jmp .loop
.error:
  mov si, str_disk_missing_part
  call printString
  jmp halt
.exit:
  ; Identifier matched up, so we'll load it.
  ; @TODO: This is lazy. Change it to use the full 8 Bytes later
  mov eax, dword [si+0x20]
  mov ecx, dword [si+0x28]
  sub ecx, eax
  mov di, 0x8000
  mov dl, byte [var_boot_drive]

  ; Read from the disk!
  call readSectorsLBA
  jc diskReadError

  mov si, str_good
  call printString

  ; Preserve the Boot Drive, just in case
  mov dl, byte [var_boot_drive]

  ; Blast off!
  jmp 0:0x8000

diskReadError:
  mov si, str_disk_read_error
  call printString
  xchg ax, dx
  call printRegister
  jmp halt
diskFormatError:
  mov si, str_disk_format_error
  call printString
  jmp halt
halt:
  cli
  hlt

; Include various other routines we need
%include "Real_Mode_Includes/string.inc"
%include "Real_Mode_Includes/disk.inc"

; Strings, Variables, Constants
var_boot_drive:             db 0 ; We need to keep this for the kernel
const_gpt_signature:        db "EFI PART"
const_stage1_signature:     db "Hah!IdontNeedEFI"
str_no_support_error:       db "BIOS doesn't support extended int 10h", 0
str_disk_read_error:        db "Disk Read Error.", 0
str_disk_format_error:      db "Disk not GPT format.", 0
str_disk_missing_part:      db "Missing System Partition", 0
str_good:                   db "Stage 0 Finished!", 0xA, 0xD 0

; We don't care about anything before the partition entries
; Also acts as a guard against accidentally overwriting the partition entries
times 446 - ($-$$) db 0

; MBR Partition Table. There are 4 Partitions each with a width of 16 Bytes
; Boot Indicator: Shows "Active" partitions. Should be 0, or nz/0x80 ("active")
; Starting Head: CHS Stuff. Ignore it.
; Starting Sector,Cylinder: More CHS garbage. Two fields, 6 bits, then 10 bits
; System ID: Identification for FS. Unreliable. Looking for 0x86 for EXT2
; Ending Head: CHS Stuff. Ignore it.
; Ending Sector,Cylinder: More CHS Stuff. Two fields, 6 bits, then 10 bits.
; Partition Start LBA: This is what we need. Start of this partition, in LBA
; Partition Total Sectors: How long the partition is, in sectors.

mbr_partition_table:
partition_entry_1:
  .boot_indicator:           db 0
  .starting_head:            db 0
  .starting_sector_cylinder: dw 0
  .system_id:                db 0
  .ending_head:              db 0
  .ending_sector_cylinder:   dw 0
  .partition_start_lba:      dd 0
  .partition_total_sectors:  dd 0

partition_entry_2:
  .boot_indicator:           db 0
  .starting_head:            db 0
  .starting_sector_cylinder: dw 0
  .system_id:                db 0
  .ending_head:              db 0
  .ending_sector_cylinder:   dw 0
  .partition_start_lba:      dd 0
  .partition_total_sectors:  dd 0

partition_entry_3:
  .boot_indicator:           db 0
  .starting_head:            db 0
  .starting_sector_cylinder: dw 0
  .system_id:                db 0
  .ending_head:              db 0
  .ending_sector_cylinder:   dw 0
  .partition_start_lba:      dd 0
  .partition_total_sectors:  dd 0

partition_entry_4:
  .boot_indicator:           db 0
  .starting_head:            db 0
  .starting_sector_cylinder: dw 0
  .system_id:                db 0
  .ending_head:              db 0
  .ending_sector_cylinder:   dw 0
  .partition_start_lba:      dd 0
  .partition_total_sectors:  dd 0

; End Boot Signature to signify this disk is bootable.
dw 0xAA55
