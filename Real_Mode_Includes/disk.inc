; disk.inc - Various Real Mode Disk Routines
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

[bits 16]
;-------------------------------------------------------------------------------
; DISK ADDRESS PACKET
dap:
                  db 10h ; Size of Packet, 16B
                  db 0
dap_sector_count: dw 0 ; Number of Sectors to Read
dap_offset:       dw 0x0000
dap_segment:      dw 0x0000
dap_lba_lo:       dd 0 ; I briefly changed this to a qword. Moved it back since
dap_lba_hi:       dd 0 ; only the low 48 bits are read.
;-------------------------------------------------------------------------------

; readSectorsLBA: Read Sectors using the int 13h extension for LBA operations
; Will return CF set on error.
; EAX: LBA to start reading from
;  DS: Segment to load the sectors to
;  DI: Offset to load the sectors to
;  CX: How many sectors to read
;  DL: Drive Number
readSectorsLBA:
  mov [dap_lba_lo], eax       ; Starting LBA to read from
  mov [dap_segment], ds       ; Segment to load to
  mov [dap_offset], di        ; Offset to load to
  mov [dap_sector_count], cx  ; How many sectors to read
	mov ah, 42h                 ; EXT Read Sectors
	mov si, dap                 ; Data Segment already set to 0x0000
	int 13h                     ; Read Sectors
	ret
