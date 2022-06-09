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
  xor edx, edx
  div bx

  ; Set values for load function
  ; Load to 0x0000:0x8000
  xchg eax, ecx
  mov bx, 0x8000
  mov dl, [var_boot_drive]
  call readSectorsLBA

  ; Compare the value in the entry until we find it
  mov si, bx
  mov di, str_s2_filename
  mov cx, 11 ; Compare 11 Characters
  mov dx, [bpb_root_dir_entries] ; Do this until we run out of entries

findEntry:
  call compareString
  jne .next ; Nope, not it.
  jmp .found ; Sweet, it worked!
.next:
  dec dx ; Have we run out of entries?
  test dx, 0
  jnz .fail ; Didn't find it
  add si, 32 ; Go to the next entry
  jmp findEntry
.fail:
  mov si, str_error
  call printString
  cli
  hlt
.found:
  ; Entry is stored at 0x0000:SI, grab the cluster number
  xor eax, eax
  mov ax,  word [si+dir_first_cluster_lo]
  mov di, 0xA000

loadFile:
  call loadCluster
  call loadFatSectorFromCluster
  mov ax, word [var_cluster_offset]
  mov bl, 2
  mul bl
  mov cx, ax
  mov ax, word [eax+0x500]
  cmp ax, 0xFFF7
  je diskerror
  jg .end
  jmp loadFile
.end:
  ; idk yet, not done
  mov si, str_good
  call printString
  cli
  hlt

; loadFatSectorFromCluster:
; This routine loads a single sector from the FAT to 0x0000:0x0500 based
; on the cluster number provided. The formula is
; (Cluster Number / Sectors Per Cluster) + Reserved Sectors + Hidden Sectors
; AX = Cluster Number
; Current Cluster Offset is loaded to "[var_cluster_offset]"
loadFatSectorFromCluster:
  pusha
  ; Calculate LBA Offset from Start of FAT
  xor edx, edx
  xor ecx, ecx
  mov  cl, byte [bpb_sectors_per_cluster]
  div  cx

  ; Save our Cluster Offset
  mov word [var_cluster_offset], dx

  ; Calculate offset to FAT, add it to EAX
  add  ax,  word [bpb_reserved_sectors]
  add eax, dword [bpb_hidden_sectors]

  ; Loading one sector from our Boot Drive to 0x0000:0x0500
  mov cx, 1
  mov bx, 0x0500
  mov dl, [var_boot_drive]

  call readSectorsLBA
  popa
  test ah, 0
  jnz diskerror
  ret

; loadCluster: This routine loads cluster offset AX to the address 0x0000:DI
; This method does not error check the cluster number. Do that first!
loadCluster:
  pusha

  ; Clear values first
  xor cx,cx
  xor bx,bx
  xor dx,dx

  mov cl, byte [bpb_sectors_per_cluster]
  mul cl
  xchg eax, edx

  ; Find the LBA just past both FAT copies.
  mov ax, word [bpb_sectors_per_fat]
  mov bl, byte [bpb_total_fats]
  mul bl
  add eax, dword [bpb_hidden_sectors]
  add  ax,  word [bpb_reserved_sectors]

  ; Add the offset of our cluster to EAX
  add eax, edx

  ; Loading cx sectors to 0x0000:DI
  mov bx, di
  mov dl, [var_boot_drive]
  call readSectorsLBA
  test ah, 0
  jnz diskerror
  popa
  ret

diskerror:
  mov si, str_error
  call printString
  cli
  hlt

; Includes
%include "Real_Mode_Includes/string.inc"
%include "Real_Mode_Includes/disk.inc"

; Constants, Strings, Variables
var_boot_drive:     db 0
var_partition_lba:  dd 0
var_cluster_offset: dw 0
str_s2_filename:    db "S2      BIN", 0
str_error:          db "!dc", 0
str_good:           db "Hmm...", 0

; Boot Signature
times 510 - ($-$$) db 0
dw 0xAA55
