;
; Copyright 2024-2025 Frank Stutz
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     https://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

.arch armv8-a
.section __DATA,__data
iso_fmt:    .asciz  "%Y-%m-%dT%H:%M:%S"
output_fmt: .asciz  "%s.%06ld%c%02ld%02ld\n"

.section __DATA,__bss
    .p2align 3
tv:     .space 16
tm:     .space 56
time_str: .space 20

.text
.global _main
.p2align 2

_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, tv@PAGE
    add x0, x0, tv@PAGEOFF
    mov x1, #0
    bl _gettimeofday

    adrp x0, tv@PAGE
    add x0, x0, tv@PAGEOFF
    adrp x1, tm@PAGE
    add x1, x1, tm@PAGEOFF
    bl _localtime_r

    adrp x0, time_str@PAGE
    add x0, x0, time_str@PAGEOFF
    mov x1, #20
    adrp x2, iso_fmt@PAGE
    add x2, x2, iso_fmt@PAGEOFF
    adrp x3, tm@PAGE
    add x3, x3, tm@PAGEOFF
    bl _strftime

    adrp x8, tm@PAGE
    add x8, x8, tm@PAGEOFF
    ldr w9, [x8, #40]
    mov w10, '+'
    tbnz w9, #31, negative
positive:
    mov w13, #3600
    udiv w11, w9, w13
    mul w14, w11, w13
    sub w12, w9, w14
    mov w13, #60
    udiv w12, w12, w13
    b printf_args
negative:
    neg w9, w9
    mov w10, '-'
    b positive

printf_args:
    adrp x0, output_fmt@PAGE
    add x0, x0, output_fmt@PAGEOFF
    adrp x1, time_str@PAGE
    add x1, x1, time_str@PAGEOFF
    adrp x2, tv@PAGE
    add x2, x2, tv@PAGEOFF
    ldr x2, [x2, #8]
    mov x3, x10
    mov x4, x11
    mov x5, x12

    sub sp, sp, #48
    str x1, [sp]
    str x2, [sp, #8]
    str x3, [sp, #16]
    str x4, [sp, #24]
    str x5, [sp, #32]
    bl _printf
    add sp, sp, #48

    movz x16, #0x2000, lsl #16
    movk x16, #0x0001
    mov x0, #0
    svc #0x80

    ldp x29, x30, [sp], #16
    ret

