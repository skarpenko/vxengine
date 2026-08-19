;
; Copyright (c) 2020-2026 The VxEngine Project. All rights reserved.
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
; Program that doesn't pass verification by kernel driver
;


; Set VPU0, thread 0 - 7
seten  vpu0, th0, clr      ; Disable thread 0
seten  vpu0, th1, clr      ; Disable thread 1
seten  vpu0, th2, clr      ; Disable thread 2
seten  vpu0, th3, clr      ; Disable thread 3
seten  vpu0, th4, clr      ; Disable thread 4
seten  vpu0, th5, clr      ; Disable thread 5
seten  vpu0, th6, clr      ; Disable thread 6
seten  vpu0, th7, clr      ; Disable thread 7

; Set VPU1, thread 0 - 7
seten  vpu1, th0, clr      ; Disable thread 0
seten  vpu1, th1, clr      ; Disable thread 1
seten  vpu1, th2, clr      ; Disable thread 2
seten  vpu1, th3, clr      ; Disable thread 3
seten  vpu1, th4, clr      ; Disable thread 4
seten  vpu1, th5, clr      ; Disable thread 5
seten  vpu1, th6, clr      ; Disable thread 6
seten  vpu1, th7, clr      ; Disable thread 7


; Bad code follows below

;seten  vpu0, th0, set      ; Enable thread 0
; Enabled but not fully configured threads are not allowed for user mode.
; Kernel driver's program verification function must return error.

sync stop, int             ; Sync: stop and send interrupt
; "stop" and "int" flags are not allowed for use by user mode. Kernel driver's
; program verification function must return error.

; END
