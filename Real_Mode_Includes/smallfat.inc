; smallfat.inc - FAT12/FAT16 Filesystem Constants, Routines
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

; BIOS Parameter Block: 36 Bytes Long
bpb_oem_identifier:       times  8 db ' '
bpb_bytes_per_sector:     dw 0
bpb_sectors_per_cluster:  db 0 ; We want this
bpb_reserved_sectors:     dw 0 ; Reserved from start of partition
bpb_total_fats:           db 0 ; Will probably be 2
bpb_root_dir_entries:     dw 0 ; This is gonna be handy
bpb_vol_total_sectors:    dw 0 ; 32768 for a 16MB volume
bpb_media_descriptor:     db 0 ; Ignore
bpb_sectors_per_fat:      dw 0
bpb_sectors_per_track:    dw 0 ; !!!IGNORE!!!
bpb_total_heads:          dw 0 ; !!!IGNORE!!!
bpb_hidden_sectors:       dd 0 ; LBA of the start of this partition
bpb_large_sector_count:   dd 0 ; Only set if the previous sector count is maxed

; Extended Boot Record FAT12|16: 26 Bytes Long
ebr_drive_number:         db 0    ; Ignore!
ebr_reserved_nt:          db 0    ; Reserved, useless to us
ebr_signature:            db 0x28 ; Must be 0x28/0x29
ebr_volume_id:            dd 0    ; Might be handy
ebr_volume_label:         times 11 db ' '
ebr_system_identifier:    times  8 db ' '

; 8.3 Directory Entry Format, these are offset values
dir_filename:             equ  0
dir_attributes:           equ 11
dir_reserved:             equ 12
dir_ctime_total:          equ 13
dir_ctime:                equ 14
dir_cdate:                equ 16
dir_last_access:          equ 18
dir_first_cluster_hi:     equ 20 ; This will always be zero on small FATs
dir_last_mod_time:        equ 22
dir_last_mod_date:        equ 24
dir_first_cluster_lo:     equ 26 ; This is what you want!
dir_file_size_bytes:      equ 28
