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

; This time we should be loaded to 0x0000:0x8000
; BIOS puts us in Real Mode (16 Bits), so we tell the assembler
[org 0x8000]
[bits 16]

setup:
  ; Set Data,Extra,Stack Segment Registers to 0
  xor ax, ax
  mov ds, ax
  mov es, ax
  mov ss, ax

  ; Set up the stack / base pointer
  mov bp, stack
  mov sp, bp

  ; Save drive number, we should still have it.
  mov byte [var_boot_drive], dl

  ; Set our code segment to 0
  jmp 0:start

start:
  ; First 16 Partition Entries are still loaded at 0x0000:0x0500
  mov si, 0x0500
  mov di, var_esp_sig
  mov dx, 16
findPartition:
  ; Try to find the ESP partition
  mov cx, 16
  call compareString
  je loadESPMBR

  ; Didn't find it, did we run out?
  dec dx
  jz .error

  ; Try the next one.
  add si, 0x80
  jmp findPartition

; ESP doesn't exist in the first 16 partitions
.error:
  mov si, str_error_no_esp
  call printString
  jmp hang

; We found it!
loadESPMBR:

  ; Load the first sector of the partition to 0x9000, right above this code.
  mov eax, dword [si+0x20]
  mov cx, 1
  mov di, 0x9000
  mov dl, byte [var_boot_drive]
  call readSectorsLBA
  jc .error
  jmp loadESPRootDir
.error:
  mov si, str_disk_read_error
  call printString
  xchg ax, dx
  call printRegister
  jmp hang

loadESPRootDir:
  ; Print a message stating we've found the ESP
  mov si, str_found_esp
  call printString

  ; Load it right above the bootsector in memory
  mov si, 0x9000
  mov di, 0x9200

  ; Get the cluster number of the root directory
  mov eax, dword [si+f32_ebr_c_num_rootdir_dword]
  mov dl, byte [var_boot_drive]
  call loadClusterToOffset32

  ; Calculate Bytes per Cluster
  xor ax, ax
  xor dx, dx
  mov al, byte [si+bpb_sectors_per_cluster_byte] 
  mov bx, word [si+bpb_bytes_per_sector_word]
  mul bx 

  ; Calculate number of directory entries, in EAX
  mov bx, 32
  div bx

  ; We're going to scan the entries for our directory
  xchg eax, edx

  ; Save this for later
  push edx

  mov di, str_folder_name
  mov si, 0x9200
  call findEntryInDirectory32
  jnc foundFolder

  ; Looks like we didn't find it
  mov si, str_error_no_folder
  call printString
  jmp hang

; We've found our entry! Cluster stored in EAX
foundFolder:
  ; Notify the user
  mov si, str_found_folder
  call printString

  ; Load the first cluster of the folder to 0x9200 in memory
  mov dl, byte [var_boot_drive]
  mov di, 0x9200
  mov si, 0x9000
  call loadClusterToOffset32

  ; Prepare inputs for scanning function
  mov di, str_conf_filename
  mov si, 0x9200
  
  ; Told you we'd need this! Number of entries to scan.
  pop edx

  ; Okay, let's scan again for the file this time.
  call findEntryInDirectory32
  jnc foundConfig

  ; So the config doesn't seem to exist.
  mov si, str_error_no_config
  call printString
  jmp hang

; We've found our config as well! Cluster stored in EAX
foundConfig:
  mov si, str_found_config
  call printString


hang:
  cli
  hlt

; Includes
%include "Real_Mode_Includes/string.inc"
%include "Real_Mode_Includes/disk.inc"
%include "Stage_One/fsfat.inc"

; Constants, Strings, Variables
var_boot_drive:     db 0
var_esp_sig:        db 0x28, 0x73, 0x2a, 0xc1, 0x1f, 0xf8, 0xd2, 0x11
                    db 0xba, 0x4b, 0x00, 0xa0, 0xc9, 0x3e, 0xc9, 0x3b
str_folder_name:    db "BOOTK      "
str_conf_filename:  db "CONFIG  BIN"
str_found_esp:      db "Found the ESP.", 0xA, 0xD, 0
str_found_folder:   db "Found ESP://BOOTK/", 0xA, 0xD, 0
str_found_config:   db "Found ESP://BOOTK/CONFIG.BIN", 0xA, 0xD, 0
str_disk_read_error:db "Disk Read Error. ", 0
str_error_no_folder:db "Could not find ESP://BOOTK/", 0
str_error_no_config:  db "Could not find ESP://BOOTK/CONFIG.BIN.", 0
str_error_no_esp:   db "There is no FAT32 ESP partition found on disk.", 0

; Stack grows downwards
; We'll set up 128 bytes for our stack, we don't really need too much.
align 2
end_of_stack: times 127 db 0
stack: db 0

; We're gonna load our FAT here, one sector at a time to reduce memory usage.
align 16
fat_sector: times 512 db "a"

; File Size Guard, can't get larger than 4KB
times 4096 - ($-$$) db 0
