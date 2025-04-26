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
; Full compute load
;


; VPU0, thread 0
setacc vpu0, th0, 0.0       ; Set accumulator value
setrs  vpu0, th0, 0x000000  ; Set address of vector 1
setrt  vpu0, th0, 0x001000  ; Set address of vector 2
setrd  vpu0, th0, 0x002000  ; Set result destination address
setvl  vpu0, th0, 0x4       ; Set vectors length
seten  vpu0, th0, set       ; Enable thread
; VPU0, thread 1
setacc vpu0, th1, 0.0       ; Set accumulator value
setrs  vpu0, th1, 0x010000  ; Set address of vector 1
setrt  vpu0, th1, 0x011000  ; Set address of vector 2
setrd  vpu0, th1, 0x012000  ; Set result destination address
setvl  vpu0, th1, 0x4       ; Set vectors length
seten  vpu0, th1, set       ; Enable thread
; VPU0, thread 2
setacc vpu0, th2, 0.0       ; Set accumulator value
setrs  vpu0, th2, 0x020000  ; Set address of vector 1
setrt  vpu0, th2, 0x021000  ; Set address of vector 2
setrd  vpu0, th2, 0x022000  ; Set result destination address
setvl  vpu0, th2, 0x4       ; Set vectors length
seten  vpu0, th2, set       ; Enable thread
; VPU0, thread 3
setacc vpu0, th3, 0.0       ; Set accumulator value
setrs  vpu0, th3, 0x030000  ; Set address of vector 1
setrt  vpu0, th3, 0x031000  ; Set address of vector 2
setrd  vpu0, th3, 0x032000  ; Set result destination address
setvl  vpu0, th3, 0x4       ; Set vectors length
seten  vpu0, th3, set       ; Enable thread
; VPU0, thread 4
setacc vpu0, th4, 0.0       ; Set accumulator value
setrs  vpu0, th4, 0x040000  ; Set address of vector 1
setrt  vpu0, th4, 0x041000  ; Set address of vector 2
setrd  vpu0, th4, 0x042000  ; Set result destination address
setvl  vpu0, th4, 0x4       ; Set vectors length
seten  vpu0, th4, set       ; Enable thread
; VPU0, thread 5
setacc vpu0, th5, 0.0       ; Set accumulator value
setrs  vpu0, th5, 0x050000  ; Set address of vector 1
setrt  vpu0, th5, 0x051000  ; Set address of vector 2
setrd  vpu0, th5, 0x052000  ; Set result destination address
setvl  vpu0, th5, 0x4       ; Set vectors length
seten  vpu0, th5, set       ; Enable thread
; VPU0, thread 6
setacc vpu0, th6, 0.0       ; Set accumulator value
setrs  vpu0, th6, 0x060000  ; Set address of vector 1
setrt  vpu0, th6, 0x061000  ; Set address of vector 2
setrd  vpu0, th6, 0x062000  ; Set result destination address
setvl  vpu0, th6, 0x4       ; Set vectors length
seten  vpu0, th6, set       ; Enable thread
; VPU0, thread 7
setacc vpu0, th7, 0.0       ; Set accumulator value
setrs  vpu0, th7, 0x070000  ; Set address of vector 1
setrt  vpu0, th7, 0x071000  ; Set address of vector 2
setrd  vpu0, th7, 0x072000  ; Set result destination address
setvl  vpu0, th7, 0x4       ; Set vectors length
seten  vpu0, th7, set       ; Enable thread

; VPU1, thread 0
setacc vpu1, th0, 0.0       ; Set accumulator value
setrs  vpu1, th0, 0x100000  ; Set address of vector 1
setrt  vpu1, th0, 0x101000  ; Set address of vector 2
setrd  vpu1, th0, 0x102000  ; Set result destination address
setvl  vpu1, th0, 0x4       ; Set vectors length
seten  vpu1, th0, set       ; Enable thread
; VPU1, thread 1
setacc vpu1, th1, 0.0       ; Set accumulator value
setrs  vpu1, th1, 0x110000  ; Set address of vector 1
setrt  vpu1, th1, 0x111000  ; Set address of vector 2
setrd  vpu1, th1, 0x112000  ; Set result destination address
setvl  vpu1, th1, 0x4       ; Set vectors length
seten  vpu1, th1, set       ; Enable thread
; VPU1, thread 2
setacc vpu1, th2, 0.0       ; Set accumulator value
setrs  vpu1, th2, 0x120000  ; Set address of vector 1
setrt  vpu1, th2, 0x121000  ; Set address of vector 2
setrd  vpu1, th2, 0x122000  ; Set result destination address
setvl  vpu1, th2, 0x4       ; Set vectors length
seten  vpu1, th2, set       ; Enable thread
; VPU1, thread 3
setacc vpu1, th3, 0.0       ; Set accumulator value
setrs  vpu1, th3, 0x130000  ; Set address of vector 1
setrt  vpu1, th3, 0x131000  ; Set address of vector 2
setrd  vpu1, th3, 0x132000  ; Set result destination address
setvl  vpu1, th3, 0x4       ; Set vectors length
seten  vpu1, th3, set       ; Enable thread
; VPU1, thread 4
setacc vpu1, th4, 0.0       ; Set accumulator value
setrs  vpu1, th4, 0x140000  ; Set address of vector 1
setrt  vpu1, th4, 0x141000  ; Set address of vector 2
setrd  vpu1, th4, 0x142000  ; Set result destination address
setvl  vpu1, th4, 0x4       ; Set vectors length
seten  vpu1, th4, set       ; Enable thread
; VPU1, thread 5
setacc vpu1, th5, 0.0       ; Set accumulator value
setrs  vpu1, th5, 0x150000  ; Set address of vector 1
setrt  vpu1, th5, 0x151000  ; Set address of vector 2
setrd  vpu1, th5, 0x152000  ; Set result destination address
setvl  vpu1, th5, 0x4       ; Set vectors length
seten  vpu1, th5, set       ; Enable thread
; VPU1, thread 6
setacc vpu1, th6, 0.0       ; Set accumulator value
setrs  vpu1, th6, 0x160000  ; Set address of vector 1
setrt  vpu1, th6, 0x161000  ; Set address of vector 2
setrd  vpu1, th6, 0x162000  ; Set result destination address
setvl  vpu1, th6, 0x4       ; Set vectors length
seten  vpu1, th6, set       ; Enable thread
; VPU1, thread 7
setacc vpu1, th7, 0.0       ; Set accumulator value
setrs  vpu1, th7, 0x170000  ; Set address of vector 1
setrt  vpu1, th7, 0x171000  ; Set address of vector 2
setrd  vpu1, th7, 0x172000  ; Set result destination address
setvl  vpu1, th7, 0x4       ; Set vectors length
seten  vpu1, th7, set       ; Enable thread

prod                        ; Compute products
relu                        ; ReLU
lrelu -1                    ; Leaky ReLU

store                       ; Store results

sync stop, int              ; Sync: stop and send interrupt
