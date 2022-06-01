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

; This is older code back from the first revision of KoiOS when I was in High
; School. I see no reason to change it.

[bits 16]
;-------------------------------------------------------------------------------
; DISK ADDRESS PACKET
dap:
                  db 10h ; Size of Packet, 16B
                  db 0
dap_sector_count: dw 28 ; Number of Sectors to Read
dap_offset:       dw 0x0000
dap_segment:      dw 0x0000
dap_lba:          dq 0
;-------------------------------------------------------------------------------

; @TODO Add a function to verify extended int 13h interrupts are accessible
; Should have a failure routine if this doesn't work other than just hoping
; that it does. This is annoying. Shame on 18 year old me.

; @TODO Change this section to accept registers as inputs.
; Honestly it's kinda clunky having to edit the DAP, annoying as well.
; If we load multiple sectors it also starts to waste code space.

readSectorsLBA:
	pusha
	mov ah, 42h ; EXT Read Sectors
	mov si, dap
	int 13h ; Read Sectors
	mov ah, 0xE
	jc .error
.success:
	mov al, '*'
	int 0x10
	popa
	ret
.error:

  ; @TODO This is honestly kinda unacceptable. Should probably print a more
  ; specific message. I've changed it from "!" to "<" so that it's less generic

	; Carry Flag Set
	mov al, '<'
	int 0x10
	cli
	jmp $ ; Hang Here
