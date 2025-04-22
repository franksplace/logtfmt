%ifidn __OUTPUT_FORMAT__,macho64
    %pragma macho64 platform macosx 14.4
%endif

section .data
    iso_fmt: db "%Y-%m-%dT%H:%M:%S",0
    output_fmt: db "%s.%06ld%c%02ld%02ld",10,0

section .bss
    tv: resq 2
    tm: resb 56         ; macOS struct tm size (56 bytes)
    time_str: resb 20

section .text
    global _main
    extern _gettimeofday
    extern _localtime_r
    extern _strftime
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    and rsp, -16        ; 16-byte stack alignment

    ; Get current time (seconds + microseconds)
    lea rdi, [rel tv]
    xor rsi, rsi
    call _gettimeofday

    ; Convert to local time
    lea rdi, [rel tv]
    lea rsi, [rel tm]
    call _localtime_r

    ; Format ISO 8601 base string
    lea rdi, [rel time_str]
    mov rsi, 20
    lea rdx, [rel iso_fmt]
    lea rcx, [rel tm]
    call _strftime

    ; Calculate timezone offset (tm_gmtoff at offset 40)
    mov rax, [rel tm + 40]  ; Load tm_gmtoff
    mov rbx, '+'            ; Default sign
    cmp rax, 0
    jge .positive
    mov rbx, '-'            ; Handle negative offset
    neg rax                 ; Work with absolute value
.positive:
    ; Compute hours and remainder_seconds
    xor rdx, rdx
    mov rcx, 3600
    div rcx                 ; RAX = hours, RDX = remainder_seconds
    mov r8, rax             ; Store hours
    mov rsi, rdx            ; Store remainder_seconds

    ; Compute minutes
    mov rax, rsi
    xor rdx, rdx
    mov rcx, 60
    div rcx                 ; RAX = minutes

    ; Prepare printf arguments
    lea rdi, [rel output_fmt]
    lea rsi, [rel time_str]
    mov rdx, [rel tv + 8]   ; Microseconds
    movzx rcx, bl           ; Sign character
    mov r9, rax             ; Minutes

    ; Print formatted datetime
    call _printf

    ; Clean exit
    mov rsp, rbp
    pop rbp
    mov rax, 0x2000001      ; macOS exit syscall
    xor rdi, rdi
    syscall

