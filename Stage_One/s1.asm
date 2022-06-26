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

  jmp 0:start

; We reserve 1KB for the stack. Temporary bodge to test if our stage is actually
; loaded properly, we'll put code right after this.
stack: times 1024 db 0

start:
  mov si, str_test
  call printString
  cli
  hlt

; Includes
%include "Real_Mode_Includes/string.inc"
%include "Real_Mode_Includes/disk.inc"
%include "Stage_One/fsfat.inc"

; Constants, Strings, Variables
str_s2_filename:    db "S2      BIN", 0
str_test:           db "This is a test string! You should see me right now!", 0
str_good:           db "*", 0

; File Size Guard, can't get larger than 4KB
times 4096 - ($-$$) db 0
