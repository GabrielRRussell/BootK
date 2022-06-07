; s2.asm - Stage 2 BootK
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

[bits 16]
[org 0x7C00] ; change this

; this is a dummy stub file for now
; this won't do anything

mov si, str_test
call printString

%include "Real_Mode_Includes/string.inc"
%include "Real_Mode_Includes/disk.inc"

str_test: db "Hey, you found me! I'm gonna halt now, sorry.", 0

; waste some space so that our filesystem actually has to work
times 512 dd 0xDEADBEEF
