; macOS/Linux compatible ISO 8601 datetime with microseconds and offset
%ifidn __OUTPUT_FORMAT__, macho64
    %pragma macho64 platform macosx 14.4
    %define SYM(x) _ %+ x
    %define TM_GMT_OFF 40
    %define EXIT_SYSCALL 0x2000001
%else
    %define SYM(x) x
    %define TM_GMT_OFF 32
    %define EXIT_SYSCALL 60
    section .note.GNU-stack noalloc noexec nowrite progbits ; Linux only
%endif

section .data
    iso_fmt: db "%Y-%m-%dT%H:%M:%S",0
    output_fmt: db "%s.%06ld%c%02ld%02ld",10,0

section .bss
    tv: resq 2
    tm: resb 56      ; Size for both OS
    time_str: resb 20

section .text
    global SYM(main)
    extern SYM(gettimeofday)
    extern SYM(localtime_r)
    extern SYM(strftime)
    extern SYM(printf)

SYM(main):
    %ifidn __OUTPUT_FORMAT__, macho64
    push rbp
    mov rbp, rsp
    and rsp, -16     ; macOS stack alignment
    %endif

    ; Get time of day
    lea rdi, [rel tv]
    xor rsi, rsi
    call SYM(gettimeofday)

    ; Convert to local time
    lea rdi, [rel tv]
    lea rsi, [rel tm]
    call SYM(localtime_r)

    ; Format ISO string
    lea rdi, [rel time_str]
    mov rsi, 20
    lea rdx, [rel iso_fmt]
    lea rcx, [rel tm]
    call SYM(strftime)

    ; Timezone offset calculation
    mov rax, [rel tm + TM_GMT_OFF]
    mov rbx, '+'     ; Default sign
    test rax, rax
    jns .positive
    mov rbx, '-'     ; Negative offset
    neg rax
.positive:
    ; Hours/minutes calculation
    xor rdx, rdx
    mov rcx, 3600
    div rcx          ; rax=hours, rdx=remaining sec
    mov r8, rax      ; store hours
    mov rax, rdx
    xor rdx, rdx
    mov rcx, 60
    div rcx          ; rax=minutes

    ; Prepare printf args
    lea rdi, [rel output_fmt]
    lea rsi, [rel time_str]
    mov rdx, [rel tv+8]  ; microseconds
    movzx rcx, bl        ; sign
    mov r9, rax          ; minutes

    %ifidn __OUTPUT_FORMAT__, elf64
    xor eax, eax        ; Linux varargs requirement
    %endif
    call SYM(printf)

    ; Clean exit
    %ifidn __OUTPUT_FORMAT__, macho64
    mov rsp, rbp
    pop rbp
    mov rax, EXIT_SYSCALL
    %else
    mov eax, EXIT_SYSCALL
    %endif
    xor edi, edi
    syscall

