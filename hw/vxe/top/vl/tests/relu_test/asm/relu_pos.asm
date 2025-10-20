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
; ReLU test for positive values
;

; Available VPUs: vpu0 and vpu1
; Available threads: th0 - th7

; Set VPU0, thread 0
setacc vpu0, th0, 65536.0  ; Accumulator register (floating-point value)
setvl  vpu0, th0, 0        ; Vectors length
setrs  vpu0, th0, 0x0000   ; Address of 1st vector
setrt  vpu0, th0, 0x0000   ; Address of 2nd vector
setrd  vpu0, th0, 0x5000   ; Result destination address
seten  vpu0, th0, set      ; Enable thread 0

; Set VPU0, thread 1
setacc vpu0, th1, 32768.0  ; Accumulator register (floating-point value)
setvl  vpu0, th1, 0        ; Vectors length
setrs  vpu0, th1, 0x0000   ; Address of 1st vector
setrt  vpu0, th1, 0x0000   ; Address of 2nd vector
setrd  vpu0, th1, 0x5004   ; Result destination address
seten  vpu0, th1, set      ; Enable thread 1

; Set VPU0, thread 2
setacc vpu0, th2, 16384.0  ; Accumulator register (floating-point value)
setvl  vpu0, th2, 0        ; Vectors length
setrs  vpu0, th2, 0x0000   ; Address of 1st vector
setrt  vpu0, th2, 0x0000   ; Address of 2nd vector
setrd  vpu0, th2, 0x5008   ; Result destination address
seten  vpu0, th2, set      ; Enable thread 2

; Set VPU0, thread 3
setacc vpu0, th3, 8192.0   ; Accumulator register (floating-point value)
setvl  vpu0, th3, 0        ; Vectors length
setrs  vpu0, th3, 0x0000   ; Address of 1st vector
setrt  vpu0, th3, 0x0000   ; Address of 2nd vector
setrd  vpu0, th3, 0x500C   ; Result destination address
seten  vpu0, th3, set      ; Enable thread 3

; Set VPU0, thread 4
setacc vpu0, th4, 4096.0   ; Accumulator register (floating-point value)
setvl  vpu0, th4, 0        ; Vectors length
setrs  vpu0, th4, 0x0000   ; Address of 1st vector
setrt  vpu0, th4, 0x0000   ; Address of 2nd vector
setrd  vpu0, th4, 0x5010   ; Result destination address
seten  vpu0, th4, set      ; Enable thread 4

; Set VPU0, thread 5
setacc vpu0, th5, 2048.0   ; Accumulator register (floating-point value)
setvl  vpu0, th5, 0        ; Vectors length
setrs  vpu0, th5, 0x0000   ; Address of 1st vector
setrt  vpu0, th5, 0x0000   ; Address of 2nd vector
setrd  vpu0, th5, 0x5014   ; Result destination address
seten  vpu0, th5, set      ; Enable thread 5

; Set VPU0, thread 6
setacc vpu0, th6, 1024.0   ; Accumulator register (floating-point value)
setvl  vpu0, th6, 0        ; Vectors length
setrs  vpu0, th6, 0x0000   ; Address of 1st vector
setrt  vpu0, th6, 0x0000   ; Address of 2nd vector
setrd  vpu0, th6, 0x5018   ; Result destination address
seten  vpu0, th6, set      ; Enable thread 6

; Set VPU0, thread 7
setacc vpu0, th7, 512.0    ; Accumulator register (floating-point value)
setvl  vpu0, th7, 0        ; Vectors length
setrs  vpu0, th7, 0x0000   ; Address of 1st vector
setrt  vpu0, th7, 0x0000   ; Address of 2nd vector
setrd  vpu0, th7, 0x501C   ; Result destination address
seten  vpu0, th7, set      ; Enable thread 7

; Set VPU1, thread 0
setacc vpu1, th0, 256.0    ; Accumulator register (floating-point value)
setvl  vpu1, th0, 0        ; Vectors length
setrs  vpu1, th0, 0x0000   ; Address of 1st vector
setrt  vpu1, th0, 0x0000   ; Address of 2nd vector
setrd  vpu1, th0, 0x5020   ; Result destination address
seten  vpu1, th0, set      ; Enable thread 0

; Set VPU1, thread 1
setacc vpu1, th1, 128.0    ; Accumulator register (floating-point value)
setvl  vpu1, th1, 0        ; Vectors length
setrs  vpu1, th1, 0x0000   ; Address of 1st vector
setrt  vpu1, th1, 0x0000   ; Address of 2nd vector
setrd  vpu1, th1, 0x5024   ; Result destination address
seten  vpu1, th1, set      ; Enable thread 1

; Set VPU1, thread 2
setacc vpu1, th2, 64.0     ; Accumulator register (floating-point value)
setvl  vpu1, th2, 0        ; Vectors length
setrs  vpu1, th2, 0x0000   ; Address of 1st vector
setrt  vpu1, th2, 0x0000   ; Address of 2nd vector
setrd  vpu1, th2, 0x5028   ; Result destination address
seten  vpu1, th2, set      ; Enable thread 2

; Set VPU1, thread 3
setacc vpu1, th3, 32.0     ; Accumulator register (floating-point value)
setvl  vpu1, th3, 0        ; Vectors length
setrs  vpu1, th3, 0x0000   ; Address of 1st vector
setrt  vpu1, th3, 0x0000   ; Address of 2nd vector
setrd  vpu1, th3, 0x502C   ; Result destination address
seten  vpu1, th3, set      ; Enable thread 3

; Set VPU1, thread 4
setacc vpu1, th4, 16.0     ; Accumulator register (floating-point value)
setvl  vpu1, th4, 0        ; Vectors length
setrs  vpu1, th4, 0x0000   ; Address of 1st vector
setrt  vpu1, th4, 0x0000   ; Address of 2nd vector
setrd  vpu1, th4, 0x5030   ; Result destination address
seten  vpu1, th4, set      ; Enable thread 4

; Set VPU1, thread 5
setacc vpu1, th5, 8.0      ; Accumulator register (floating-point value)
setvl  vpu1, th5, 0        ; Vectors length
setrs  vpu1, th5, 0x0000   ; Address of 1st vector
setrt  vpu1, th5, 0x0000   ; Address of 2nd vector
setrd  vpu1, th5, 0x5034   ; Result destination address
seten  vpu1, th5, set      ; Enable thread 5

; Set VPU1, thread 6
setacc vpu1, th6, 4.0      ; Accumulator register (floating-point value)
setvl  vpu1, th6, 0        ; Vectors length
setrs  vpu1, th6, 0x0000   ; Address of 1st vector
setrt  vpu1, th6, 0x0000   ; Address of 2nd vector
setrd  vpu1, th6, 0x5038   ; Result destination address
seten  vpu1, th6, set      ; Enable thread 6

; Set VPU1, thread 7
setacc vpu1, th7, 2.0      ; Accumulator register (floating-point value)
setvl  vpu1, th7, 0        ; Vectors length
setrs  vpu1, th7, 0x0000   ; Address of 1st vector
setrt  vpu1, th7, 0x0000   ; Address of 2nd vector
setrd  vpu1, th7, 0x503C   ; Result destination address
seten  vpu1, th7, set      ; Enable thread 7

relu                       ; Run relu

store                      ; Run store operation

sync stop, int             ; Sync: stop and send interrupt

; END
