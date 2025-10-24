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
; Product operation broadcast test for VPU0
;

; Available VPUs: vpu0 and vpu1
; Available threads: th0 - th7

; Set VPU0, thread 0
setacc vpu0, th0, 0.0      ; Accumulator register (floating-point value)
setvl  vpu0, th0, 1        ; Vectors length
setrs  vpu0, th0, 0x2000   ; Address of 1st vector
setrt  vpu0, th0, 0x3000   ; Address of 2nd vector
setrd  vpu0, th0, 0x4000   ; Result destination address
seten  vpu0, th0, set      ; Enable thread 0

; Set VPU0, thread 1
setacc vpu0, th1, 0.0      ; Accumulator register (floating-point value)
setvl  vpu0, th1, 1        ; Vectors length
setrs  vpu0, th1, 0x2004   ; Address of 1st vector
setrt  vpu0, th1, 0x3004   ; Address of 2nd vector
setrd  vpu0, th1, 0x4004   ; Result destination address
seten  vpu0, th1, set      ; Enable thread 1

; Set VPU0, thread 2
setacc vpu0, th2, 0.0      ; Accumulator register (floating-point value)
setvl  vpu0, th2, 1        ; Vectors length
setrs  vpu0, th2, 0x2008   ; Address of 1st vector
setrt  vpu0, th2, 0x3008   ; Address of 2nd vector
setrd  vpu0, th2, 0x4008   ; Result destination address
seten  vpu0, th2, set      ; Enable thread 2

; Set VPU0, thread 3
setacc vpu0, th3, 0.0      ; Accumulator register (floating-point value)
setvl  vpu0, th3, 1        ; Vectors length
setrs  vpu0, th3, 0x200C   ; Address of 1st vector
setrt  vpu0, th3, 0x300C   ; Address of 2nd vector
setrd  vpu0, th3, 0x400C   ; Result destination address
seten  vpu0, th3, set      ; Enable thread 3

; Set VPU0, thread 4
setacc vpu0, th4, 0.0      ; Accumulator register (floating-point value)
setvl  vpu0, th4, 1        ; Vectors length
setrs  vpu0, th4, 0x2010   ; Address of 1st vector
setrt  vpu0, th4, 0x3010   ; Address of 2nd vector
setrd  vpu0, th4, 0x4010   ; Result destination address
seten  vpu0, th4, set      ; Enable thread 4

; Set VPU0, thread 5
setacc vpu0, th5, 0.0      ; Accumulator register (floating-point value)
setvl  vpu0, th5, 1        ; Vectors length
setrs  vpu0, th5, 0x2014   ; Address of 1st vector
setrt  vpu0, th5, 0x3014   ; Address of 2nd vector
setrd  vpu0, th5, 0x4014   ; Result destination address
seten  vpu0, th5, set      ; Enable thread 5

; Set VPU0, thread 6
setacc vpu0, th6, 0.0      ; Accumulator register (floating-point value)
setvl  vpu0, th6, 1        ; Vectors length
setrs  vpu0, th6, 0x2018   ; Address of 1st vector
setrt  vpu0, th6, 0x3018   ; Address of 2nd vector
setrd  vpu0, th6, 0x4018   ; Result destination address
seten  vpu0, th6, set      ; Enable thread 6

; Set VPU0, thread 7
setacc vpu0, th7, 0.0      ; Accumulator register (floating-point value)
setvl  vpu0, th7, 1        ; Vectors length
setrs  vpu0, th7, 0x201C   ; Address of 1st vector
setrt  vpu0, th7, 0x301C   ; Address of 2nd vector
setrd  vpu0, th7, 0x401C   ; Result destination address
seten  vpu0, th7, set      ; Enable thread 7

; Set VPU1, thread 0
setacc vpu1, th0, -1.0     ; Accumulator register (floating-point value)
setvl  vpu1, th0, 1        ; Vectors length
setrs  vpu1, th0, 0x2020   ; Address of 1st vector
setrt  vpu1, th0, 0x3020   ; Address of 2nd vector
setrd  vpu1, th0, 0x4020   ; Result destination address
seten  vpu1, th0, set      ; Enable thread 0

; Set VPU1, thread 1
setacc vpu1, th1, -1.0     ; Accumulator register (floating-point value)
setvl  vpu1, th1, 1        ; Vectors length
setrs  vpu1, th1, 0x2024   ; Address of 1st vector
setrt  vpu1, th1, 0x3024   ; Address of 2nd vector
setrd  vpu1, th1, 0x4024   ; Result destination address
seten  vpu1, th1, set      ; Enable thread 1

; Set VPU1, thread 2
setacc vpu1, th2, -1.0     ; Accumulator register (floating-point value)
setvl  vpu1, th2, 1        ; Vectors length
setrs  vpu1, th2, 0x2028   ; Address of 1st vector
setrt  vpu1, th2, 0x3028   ; Address of 2nd vector
setrd  vpu1, th2, 0x4028   ; Result destination address
seten  vpu1, th2, set      ; Enable thread 2

; Set VPU1, thread 3
setacc vpu1, th3, -1.0     ; Accumulator register (floating-point value)
setvl  vpu1, th3, 1        ; Vectors length
setrs  vpu1, th3, 0x202C   ; Address of 1st vector
setrt  vpu1, th3, 0x302C   ; Address of 2nd vector
setrd  vpu1, th3, 0x402C   ; Result destination address
seten  vpu1, th3, set      ; Enable thread 3

; Set VPU1, thread 4
setacc vpu1, th4, -1.0     ; Accumulator register (floating-point value)
setvl  vpu1, th4, 1        ; Vectors length
setrs  vpu1, th4, 0x2030   ; Address of 1st vector
setrt  vpu1, th4, 0x3030   ; Address of 2nd vector
setrd  vpu1, th4, 0x4030   ; Result destination address
seten  vpu1, th4, set      ; Enable thread 4

; Set VPU1, thread 5
setacc vpu1, th5, -1.0     ; Accumulator register (floating-point value)
setvl  vpu1, th5, 1        ; Vectors length
setrs  vpu1, th5, 0x2034   ; Address of 1st vector
setrt  vpu1, th5, 0x3034   ; Address of 2nd vector
setrd  vpu1, th5, 0x4034   ; Result destination address
seten  vpu1, th5, set      ; Enable thread 5

; Set VPU1, thread 6
setacc vpu1, th6, -1.0     ; Accumulator register (floating-point value)
setvl  vpu1, th6, 1        ; Vectors length
setrs  vpu1, th6, 0x2038   ; Address of 1st vector
setrt  vpu1, th6, 0x3038   ; Address of 2nd vector
setrd  vpu1, th6, 0x4038   ; Result destination address
seten  vpu1, th6, set      ; Enable thread 6

; Set VPU1, thread 7
setacc vpu1, th7, -1.0     ; Accumulator register (floating-point value)
setvl  vpu1, th7, 1        ; Vectors length
setrs  vpu1, th7, 0x203C   ; Address of 1st vector
setrt  vpu1, th7, 0x303C   ; Address of 2nd vector
setrd  vpu1, th7, 0x403C   ; Result destination address
seten  vpu1, th7, set      ; Enable thread 7

prod vpu0                  ; Run product operation on VPU0

store                      ; Run store operation

sync stop, int             ; Sync: stop and send interrupt

; END
