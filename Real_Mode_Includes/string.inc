; string.inc - Various Real Mode String Routines
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
; Variable for Storage
hex_output: db "0x0000", 10, 13, 0
; Print DX Register
printRegister:
  pusha
  mov cx, 0
.loop:
  cmp cx, 4
  je .exit

  mov ax, dx
  and ax, 0x000F
  add al, 0x30
  cmp al, 0x39
  jle .step2
  add al, 7
.step2:
  mov bx, hex_output + 5
  sub bx, cx
  mov [bx], al
  ror dx, 4

  add cx, 1
  jmp .loop
.exit:
  mov si, hex_output
  call printString
  popa
  ret

;-------------------------------------------------------------------------------
; Compare Two Strings located at SI, DI
; Bytes to scan in CX (THIS DOESN'T WORK WITH C-STRINGS)
; ZF Clear if they don't match up
compareString:
  push si
  push di
  cld
  repe cmpsb
  pop di
  pop si
  ret
;-------------------------------------------------------------------------------
; Print String located at SI
printString:
  pusha
.loop:
  lodsb
  or al, al
  jz .exit
  mov ah, 0xE
  int 10h
  jmp .loop
.exit:
  popa
  ret
