;
; Copyright (c) 2020-2025 The VxEngine Project. All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;    notice, this list of conditions and the following disclaimer in the
;    documentation and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
; SUCH DAMAGE.
;

;
; VxEngine assembler example
;

; Available VPUs: vpu0 and vpu1
; Available threads: th0 - th7

; Set VPU0, thread 0
setacc vpu0, th0, 0.0   ; Accumulator register (floating-point value)
setvl vpu0, th0, 8192   ; Vectors length
setrs vpu0, th0, 0x8000 ; Vector1 address
setrt vpu0, th0, 0xc000 ; Vector1 address
setrd vpu0, th0, 0xa000 ; Result destination address
seten vpu0, th0, set    ; Enable thread 0
seten vpu0, th1, clr    ; Disable thread 1

prod                    ; Run product operation
prod vpu0               ; Run product operation on VPU0 only

store                   ; Run store operation
store vpu0              ; Run store operation on VPU0 only

nop                     ; No operation

sync stop, int          ; Sync: stop and send interrupt
sync nostop, noint      ; Sync and continue

relu                    ; Run relu operation
relu vpu0               ; Run relu operation on VPU0 only

lrelu 0                 ; Run lrelu operation
lrelu vpu0, 0           ; Run lrelu operation on VPU0 only
lrelu -9                ; Run lrelu operation with exp diff -9
lrelu vpu1, -9          ; Run lrelu operation with exp diff -9 on VPU1 only

nop
nop

; END
