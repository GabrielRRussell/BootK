; s1.asm - Stage 1 BootK
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
; 0x0500 - 0x7BFF : Free Memory (~29.7Kb) <-- Setting up Stack here
; 0x7C00 - 0x7DFF : Bootsector (512b) <-- YOU ARE HERE
; 0x7E00 - 0x0007.FFFF : Free Memory (480.5Kb) <-- Loading Stage 2 Here

; This time we're loading our copied MBR at 0x0000:0x7C00
; BIOS puts us in Real Mode (16 Bits), so we tell the assembler
[org 0x7C00]
[bits 16]

jmp short start
nop
%include "Real_Mode_Includes/smallfat.inc"

start:
  cli
  ; Reset segment registers to 0x0000, just in case
  xor eax, eax
  mov ds, ax
  mov es, ax
  mov ss, ax

  ; Setup stack at 0x0000:0x7B00
  mov bp, 0x7B00
  mov sp, bp

  ; Spec Compliant bootloaders should pass us the drive number in DL
  mov [var_boot_drive], dl

  ; Active partition entry pointed to by SI
  ; Store the starting LBA of this partition from the active partition entry

  ; @TODO - Do I really want to keep it this way?
  ; Might be better to read it from the FAT table that way this could be
  ; compatible with other chainloaders. SI pointing to the partition entry isn't
  ; guaranteed, so it might not be compatible with other chainloaders.
  mov eax, dword [si+8]
  mov [var_partition_lba], eax

  ; We can restore interrupts now that setup is done
  sti

  ; Calculate size of FAT in Sectors
  xor eax, eax
  xor ecx, ecx
  xor ebx, ebx
  mov ax, word [bpb_sectors_per_fat]
  mov bl, byte [bpb_total_fats]
  mul bx

  ; Find the start of the root directory
  add  ax,  word [bpb_reserved_sectors]
  add eax, dword [var_partition_lba]
  xchg eax, ecx

  ; Calculate how many sectors we need to load for the root directory
  xor ebx, ebx
  mov ax, word [bpb_root_dir_entries]
  mov dx, 32
  mul dx
  add ax, word [bpb_bytes_per_sector]
  dec ax
  mov bx, word [bpb_bytes_per_sector]
  div bx

  ; Set values for load function
  ; Load to 0x0000:0x8000
  xchg eax, ecx
  mov bx, 0x8000
  call readSectorsLBA

  ; Compare the value in the entry until we find it
  mov si, bx
  mov di, str_s2_filename
  mov cx, 11 ; Compare 11 Characters
  mov dx, [bpb_root_dir_entries] ; Do this until we run out of entries

findEntry:
  call compareString
  jz .next ; Nope, not it.
  jmp .found ; Sweet, it worked!
.next:
  dec dx ; Have we run out of entries?
  test dx, 0
  jz .fail ; Didn't find it
  add si, 32 ; Go to the next entry
  jmp findEntry
.fail:
  mov si, str_error
  call printString
  cli
  hlt
.found:

loadFat:
  ; Entry is stored at 0x0000:SI, grab the cluster number
  xor eax, eax
  mov ax,  word [si+dir_first_cluster_lo]

  ; Calculate offset of FAT to load
  ; AX = Quotient = Offset Sector to Load
  ; DX = Remainder = Cluster Offset to load inside sector
  mov bx, 512
  div bx

  ; Add LBA of first FAT to eax
  add eax, dword [bpb_hidden_sectors]
  add eax,  word [bpb_reserved_sectors]

  ; We'll load this to 0x0000:0x0500
  mov bx, 0x0500

  ; Load only one sector from boot drive.
  mov cx, 1
  mov dl, byte [var_boot_drive]

  ; Load the data! A sector from the FAT should be located at 0x0500 now!
  call readSectorsLBA

  ; Continue working on this later

  cli
  hlt

; Includes
%include "Real_Mode_Includes/string.inc"
%include "Real_Mode_Includes/disk.inc"

; Constants, Strings, Variables
var_boot_drive:     db 0
var_partition_lba:  dd 0
str_s2_filename:    db "S2      BIN", 0
str_good:           db ":)", 0
str_error:          db ":(", 0

times 510 - ($-$$) db 0
dw 0xAA55
