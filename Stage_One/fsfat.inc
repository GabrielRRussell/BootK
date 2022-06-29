; fsfat.inc - FAT Filesystem Constants, Routines
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

; findDataStartLBA32
; Find the first data sector LBA in the BPB provided for FAT32
; Input:    SI: Pointer to BPB
; Output:  EAX: LBA of First Data Sector
findDataStartLBA32:
  ; Calculate size of FATs
  push ebx
  push edx
  xor ebx, ebx

  mov eax, dword [si+f32_ebr_sectors_fat_dword]
  mov  bl,  byte [si+bpb_total_fats_byte]
  mul  bx

  ; Add hidden, reserved sectors, then return
  add eax, dword [si+bpb_hidden_sectors_dword]
  mov  bx,  word [si+bpb_reserved_sectors_word]
  add eax, ebx

  pop edx
  pop ebx
  ret

; getSectorFromCluster32
; Calculate Sector Number of Cluster for FAT32
; Input:  EAX: Cluster
;          SI: Ptr to copy of BPB
; Return: EAX: Sector
getSectorFromCluster32:
  ; Preserve the original value in case needed
  push edx
  xor edx, edx

  ; Get the number of sectors per cluster
  mov dl, byte [si+bpb_sectors_per_cluster_byte]

  sub eax, 2
  mul dx
  xchg eax, edx
  ; Get the starting sector, add it to our calculation
  call findDataStartLBA32
  ; We have our result. Restore edx, and then return
  add eax, edx
  pop edx
  ret

; loadClusterToOffset32
; Loads a full Cluster to an offset in memory at DS:DI
; Input:  EAX: Cluster Number to Load
;          DL: Drive Number
;          DS: Segment to load cluster to
;          DI: Offset to Load Cluster to
;          SI: Ptr to copy of BPB
loadClusterToOffset32:
  pusha

  ; Get the starting sector of the cluster, and how many sectors long it is.
  call getSectorFromCluster32
  xor cx, cx
  mov cl, byte [si+bpb_sectors_per_cluster_byte]

  ; Load the sectors to DS:DI
  call readSectorsLBA

  ; Return
  popa
  ret

; loadFATSectorFromCluster32
; Given a cluster number, loads the next part of the FAT necessary to find the next cluster number
; or end of chain to memory.
; Input:  EAX: Cluster Number
;          SI: Ptr to copy of BPB
;          BX: Ptr to 512 Byte Region of Free Memory
;          DL: Boot Drive
loadFATSectorFromCluster32:
  pusha
  push dx
  xor dx, dx
  ; Find the sector offset
  ; EAX= Sector Offset
  ; We have to preserve DL
  mov cx, 128
  div cx
  pop dx

  add  ax,  word [si+bpb_reserved_sectors_word]
  add eax, dword [si+bpb_hidden_sectors_dword]
  mov cx, 1

  xchg di, bx
  call readSectorsLBA

  popa
  ret

; Values below are offsets. You can include them in your code by doing
; REG = [MBR], [REG+Offset] to properly access them
; At the end of each constant's name is the size.

; BIOS Parameter Block: 36 Bytes Long
; These are offsets.
bpb_oem_identifier_qword:     equ 0x03 ; Often ignored
bpb_bytes_per_sector_word:    equ 0x0B
bpb_sectors_per_cluster_byte: equ 0x0D
bpb_reserved_sectors_word:    equ 0x0E ; Sectors before first usable cluster
bpb_total_fats_byte:          equ 0x10 ; Usually 2
bpb_root_dir_entries_word:    equ 0x11 ; Set to fill entire sectors
bpb_vol_total_sectors_word:   equ 0x13 ; If 0, refer to 0x20
bpb_media_descriptor_byte:    equ 0x15
bpb_sectors_per_fat_word:     equ 0x16 ; Only for FAT12/16
bpb_sectors_per_track_word:   equ 0x18 ; Ignore.
bpb_total_heads_word:         equ 0x1A ; Ignore.
bpb_hidden_sectors_dword:     equ 0x1C ; Starting LBA of THIS partition
bpb_large_sector_count_dword: equ 0x20

; Extended Boot Record FAT12|16: 26 Bytes Long
; These are offsets.
sf_ebr_drive_number_byte:       equ 0x24
sf_ebr_reserved_nt_byte:        equ 0x25
sf_ebr_signature_byte:          equ 0x26 ; Should be either 0x28 / 0x29
sf_ebr_volume_id_dword:         equ 0x27
sf_ebr_volume_label_11b:        equ 0x2B ; Padded with spaces
sf_ebr_sys_identifier_qword:    equ 0x36 ; Never trust contents of this

; Extended Boot Record FAT32: 90 Bytes Long
; These are offsets.
f32_ebr_sectors_fat_dword:      equ 0x0024
f32_ebr_flags_word:             equ 0x0028
f32_ebr_fat_version_word:       equ 0x002A
f32_ebr_c_num_rootdir_dword:    equ 0x002C ; Will probably be cluster 2
f32_ebr_sector_fsinfo_word:     equ 0x0030
f32_ebr_sector_backup_word:     equ 0x0032 ; LBA of the backup bootsector
f32_ebr_null_reserved_12b:      equ 0x0034
f32_ebr_drive_number_byte:      equ 0x0040
f32_ebr_nt_reserved_byte:       equ 0x0041
f32_ebr_signature_byte:         equ 0x0042 ; Should be either 0x28 / 0x29
f32_ebr_volume_id_dword:        equ 0x0043
f32_ebr_volume_label_11b:       equ 0x0047 ; Padded with spaces
f32_ebr_system_string_qword:    equ 0x0502 ; Always "FAT32   ", don't trust

; FSInfo Structure FAT32: 512 Bytes Long
; These are offsets.
fsinfo_lead_signature_dword:    equ 0x0000
fsinfo_second_signature_dword:  equ 0x01E4
fsinfo_free_clusters_dword:     equ 0x01E8
fsinfo_first_free_cluster_dword:equ 0x01EC
fsinfo_reserved_b12:            equ 0x01F0
fsinfo_last_signature_dword:    equ 0x01FC

; FSInfo Signatures FAT32
; There are three signatures here. This is what they should equate to.
; These are constants.
fsinfo_sig_1st:                 equ 0x41615252 ; fsinfo_lead_signature_dword
fsinfo_sig_2nd:                 equ 0x61417272 ; fsinfo_second_signature_dword
fsinfo_sig_3rd:                 equ 0xAA550000 ; fsinfo_last_signature_dword

; 8.3 Directory Entry Format, 32 Bytes Long
; These are offsets.
dir_filename_11b:               equ 0x0000 ; 8.3 File Name, padded with spaces
dir_attributes_byte:            equ 0x000B
dir_reserved_byte:              equ 0x000C
dir_ctime_total_byte:           equ 0x000D
dir_ctime_word:                 equ 0x000E
dir_cdate_word:                 equ 0x0010
dir_last_access_word:           equ 0x0012
dir_first_cluster_hi_word:      equ 0x0014 ; Always zero on FAT12 and FAT16
dir_last_mod_time_word:         equ 0x0016
dir_last_mod_date_word:         equ 0x0018
dir_first_cluster_lo_word:      equ 0x001A ; This is what you want!
dir_file_size_bytes_dword:      equ 0x001C ; File size in bytes

; LFN Directory Entry Format, 32 Bytes Long
; These are offsets.
lfn_entry_order_byte:           equ 0x0000
lfn_five_characters_10b:        equ 0x0001 ; First five characters of filename
lfn_attribute_byte:             equ 0x000B ; Should always be 0x0F
lfn_long_entry_type_byte:       equ 0x000C ; 0x00 for Name Entries
lfn_short_checksum_byte:        equ 0x000D
lfn_six_characters_12b:         equ 0x000E ; Middle six characters of entry
lfn_null_word:                  equ 0x001A
lfn_two_characters_dword:       equ 0x001C ; Last two characters of entry
