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
; 0x0500 - 0x7BFF : Free Memory (~29.7Kb) <-- We'll copy MBR here at 0x0600
; 0x7C00 - 0x7DFF : Bootsector (512b) <-- YOU ARE HERE
; 0x7E00 - 0x7FFF : Free Memory (480.5Kb) <-- Setting up Stack Here

; This Stage 0 Bootloader expects a few things. First of all, it's loaded via
; HDD. Second, that HDD is formatted with MBR, not GPT. Third, there exists a
; NOT-LOGICAL EXT2 partition on the disk that has the operating system contents.
; Fourth, the system must support Fast A20 setup, and LBA Disk Load BIOS calls.
; Try not to use this on anything ancient. As stated above, no warranty.

; Set our origin to 0x0600 since that's where our copied MBR will go.
; BIOS puts us in Real Mode (16 Bits), so we tell the assembler
[org 0x0600]
[bits 16]

setup:
  ; Disable Interrupts
  cli

  ; Set Data,Extra,Stack Segment Registers to 0
  xor eax, eax
  mov ds, ax
  mov es, ax
  mov ss, ax

  ; Properly set up the stack at free memory 0x8000, reference chart above
  mov bp, 0x8000
  mov sp, bp

; Copy the MBR (512 Bytes) to 0x0600, and jump to it.
; This way we can copy the VMBR of our partition to 0x7C00 and execute it.
copyMBR:
  mov cx, 0x0200
  mov si, 0x7C00
  mov di, 0x0600
  rep movsb
  jmp 0:start

start:
  ; Now that we've moved back over to 0x0600, we can resume interrupts
  sti
  mov [var_boot_drive], dl

  ; There are four partition table entries we need to check
  mov ecx, 4
  mov ebx, partition_entry_1
findPartition:
  ; Check the active partition value. If it isn't active, go to the next one.
  mov al, [ebx]
  test al, 0x80
  jnz .exit
  add ebx, 16
  dec cx
  jnz findPartition
  ; Didn't find any active partitions, so we'll need to abort.
  jmp .error

.error:
  mov si, str_no_active_error
  call printString
  cli
  hlt

.exit:

  ;@TODO Edit the DAP section in "disk.inc", Section noted there

  ; Store a PTR to the active partition entry, and grab
  ; the starting LBA sector on that partition entry
  mov dword [var_active_partition_entry], ebx
  mov ebx, dword [ebx+8]
  mov [dap_lba], ebx

  ; We're going to load one sector to 0x0000:0x7C00, our original location
  xor eax,eax
  mov word [dap_segment], ax

  inc ax
  mov word [dap_sector_count], 0x01

  mov ax, 0x7C00
  mov word [dap_offset], ax

  ; Okay, we're finally reading the data.
  call readSectorsLBA

  ; We need to make sure this is a bootable partition, check the boot sig
  ; The correct value should be 0xAA55
  cmp word [const_new_boot_signature], 0xAA55

  ; @TODO Change this to print a different error sequence
  jne .error

  ; Pass over the partition table entry, and the boot drive to the next stage
  mov si, word [var_active_partition_entry]
  mov dl, byte [var_boot_drive]

  ; Blast Off!
  jmp 0x7C00

; Include various other routines we need
%include "Real_Mode_Includes/string.inc"
%include "Real_Mode_Includes/disk.inc"

; Strings, Variables, Constants
const_new_boot_signature: equ 0x7C00 + 510 ; PTR to new mbr signature 0xAA55
var_boot_drive:            db 0            ; We need to keep this for the kernel
var_active_partition_entry dd 0            ; PTR to active partition entry
str_no_fs_error:           db "!FS", 0     ; ERROR: No EXT2 Partitions Found
str_no_active_error:       db "!80", 0     ; ERROR: No Active Partitions
str_good:                  db ":)", 0      ; No Issues Here

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
