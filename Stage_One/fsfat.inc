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

; Values below are offsets. You can include them in your code by doing
; REG = [MBR], [REG+Offset] to properly access them
; At the end of each constant's name is the size.

; BIOS Parameter Block: 36 Bytes Long
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
sf_ebr_drive_number_byte:       equ 0x24
sf_ebr_reserved_nt_byte:        equ 0x25
sf_ebr_signature_byte:          equ 0x26 ; Should be either 0x28 / 0x29
sf_ebr_volume_id_dword:         equ 0x27
sf_ebr_volume_label_11b:        equ 0x2B ; Padded with spaces
sf_ebr_sys_identifier_qword:    equ 0x36 ; Never trust contents of this

; Extended Boot Record FAT32: 90 Bytes Long
f32_ebr_sectors_fat_dword:      equ 0x24
f32_ebr_flags_word:             equ 0x28
f32_ebr_fat_version_word:       equ 0x2A
f32_ebr_c_num_rootdir_dword:    equ 0x2C ; Will probably be cluster 2
f32_ebr_sector_fsinfo_word:     equ 0x30
f32_ebr_sector_backup_word:     equ 0x32 ; LBA of the backup bootsector
f32_ebr_null_reserved_12b:      equ 0x34
f32_ebr_drive_number_byte:      equ 0x40
f32_ebr_nt_reserved_byte:       equ 0x41
f32_ebr_signature_byte:         equ 0x42 ; Should be either 0x28 / 0x29
f32_ebr_volume_id_dword:        equ 0x43
f32_ebr_volume_label_11b:       equ 0x47 ; Padded with spaces
f32_ebr_system_string_qword:    equ 0x52 ; Always "FAT32   ", don't trust

; 8.3 Directory Entry Format, 32 Bytes Long
dir_filename_11b:               equ 0x00 ; 8.3 File Name, padded with spaces
dir_attributes_byte:            equ 0x0B
dir_reserved_byte:              equ 0x0C
dir_ctime_total_byte:           equ 0x0D
dir_ctime_word:                 equ 0x0E
dir_cdate_word:                 equ 0x10
dir_last_access_word:           equ 0x12
dir_first_cluster_hi_word:      equ 0x14 ; This will always be zero on FAT12|16
dir_last_mod_time_word:         equ 0x16
dir_last_mod_date_word:         equ 0x18
dir_first_cluster_lo_word:      equ 0x1A ; This is what you want!
dir_file_size_bytes_dword:      equ 0x1C ; File size in bytes

; LFN Directory Entry Format, 32 Bytes Long
lfn_entry_order_byte:           equ 0x00
lfn_five_characters_10b:        equ 0x01 ; First five characters of filename
lfn_attribute_byte:             equ 0x0B ; Should always be 0x0F
lfn_long_entry_type_byte:       equ 0x0C ; 0x00 for Name Entries
lfn_short_checksum_byte:        equ 0x0D
lfn_six_characters_12b:         equ 0x0E ; Middle six characters of entry
lfn_null_word:                  equ 0x1A
lfn_two_characters_dword:       equ 0x1C ; Last two characters of entry
