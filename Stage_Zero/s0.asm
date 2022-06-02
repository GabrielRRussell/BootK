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

; This code expects a MBR formatted drive, and looks for an active partition,
; then loads the VMBR of that partition to 0x0000:0x7C00 and jumps to it.

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
  mov byte [var_boot_drive], dl

findPartition:
  ; Test Extended int 13h support
  ; RETURNS:
  ;   CF: Clear on Present
  ;   AH: Error Code / Version
  ;   BX: 0xAA55
  ;   CX: Interface support bitmask. We really don't care about this.
  mov ah, 0x41
  mov bx, 0x55AA
  mov dl, [var_boot_drive]
  int 13h
  jc .noSupport ; If CF is set, we're smoked. Otherwise, carry on ;)

  ; There are four partition table entries we need to check
  mov ecx, 4
  mov edx, partition_entry_1
.loop:
  ; Check the active partition value. If it isn't active, go to the next one.
  mov al, [edx]
  test al, 0x80
  jnz .exit ; Found it!
  add edx, 16
  dec cx
  jnz .loop
  ; Didn't find any active partitions, so we'll need to abort.
  jmp .noActivePartition

.exit:

  ; Store pointer to the active partition
  mov dword [var_active_partition_entry], edx

  ; Store a PTR to the active partition entry, and grab
  ; the starting LBA sector on that partition entry
  mov edx, dword [var_active_partition_entry]
  mov eax, dword [edx+8]
  mov  bx, 0x7C00                 ; We're loading to 0x0000:0x7C00
  mov  cx, 1                      ; Loading one sector
  mov  dl, byte [var_boot_drive]  ; Probably 0x80, hard drive

  ; Okay, we're finally reading the data.
  call readSectorsLBA
  test ah, ah      ; Test for non-zero AH, failure if that happened
  jnz .readError
  jmp .readSuccess ; Success!

.noActivePartition:
  mov si, str_no_active_error
  call printString
  jmp .hang
.noSupport:
  mov si, str_no_support_error
  call printString
  jmp .hang
.readError:
  mov si, str_disk_read_error
  call printString
  jmp .hang
.notBootableError:
  mov si, str_disk_no_boot_error
  call printString
.hang:
  cli
  hlt

.readSuccess:
  ; We need to make sure this is a bootable partition, check the boot sig
  ; The correct value should be 0xAA55
  cmp word [const_new_boot_signature], 0xAA55
  jne .notBootableError

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
str_no_active_error:       db "ERROR! No active partitions!", 0
str_no_support_error:      db "ERROR! BIOS doesn't support extended int 10h", 0
str_disk_read_error:       db "ERROR! Disk Read Error!", 0
str_disk_no_boot_error:    db "ERROR! Disk not bootable!", 0
str_good:                  db "Stage 0 Finished!\n", 0

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
