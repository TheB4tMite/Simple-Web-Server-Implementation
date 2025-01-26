.intel_syntax noprefix
.globl _start

.section .text

_start:
    jmp socket

socket:
    mov rdi, 2
    mov rsi, 1
    mov rax, 41
    syscall
    mov rbx, rax

bind:
    mov rdi, rbx
    sub rsp, 16
    mov word ptr [rsp], 0x02
    mov word ptr [rsp+2], 0x5000
    mov dword ptr [rsp+4], 0x0
    mov rsi, rsp
    add rsp, 16
    mov rdx, 16
    mov rax, 49
    syscall

listen:
    mov rdi, rbx
    xor rsi, rsi
    mov rax, 50
    syscall

accept_conn:
    mov rdi, rbx
    xor rsi, rsi
    xor rdx, rdx
    mov rax, 43
    syscall
    xor r14, r14
    mov r14, rax

fork:
    mov rax, 57
    syscall
    cmp rax, 0
    je child_proc_start

close_conn_parent:
    mov rdi, r14
    mov rax, 3
    syscall
    jmp accept_conn

# rbx - socket fd
# r14 - conn fd
# r15 - file fd

child_proc_start:
    close_sock_child:
        mov rdi, rbx
        mov rax, 3
        syscall

    read_req:
        mov rdi, r14
        lea rsi, rd_f
        mov rax, 0
        mov rdx, 500
        syscall
        mov rdi, rsi
        call get_file_GET
        test rcx, rcx
        jnz open_file_POST
        
    open_file:
        open_file_GET:
            lea rdi, read_file
            mov rsi, 0
            mov rax, 2
            syscall
            mov r15, rax
            jmp read_file_GET

        open_file_POST:
            lea rdi, write_file
            mov rsi, 0x41
            mov rdx, 511
            mov rax, 2
            syscall
            mov r15, rax
            lea rdi, rd_f
            call get_file_cont
            jmp write_to_file_POST

GET:
    read_file_GET:
        mov rdi, r15
        lea rsi, read_fcont
        mov rdx, 500
        mov rax, 0
        syscall
        mov r10, rax

    close_file_GET:
        mov rdi, r15
        mov rax, 3
        syscall

    write_conn_GET:
        mov rdi, r14
        lea rsi, req
        mov rdx, 19
        mov rax, 1
        syscall

    write_to_file_GET:
        lea rsi, read_fcont
        mov rdx, r10
        mov rax, 1
        syscall
        jmp exit

# address already stored using get_file_cont
# length already stored using get_cont_len

POST:
    write_to_file_POST:
        mov rdi, r15
        mov rax, 1
        syscall

    close_file_POST:
        mov rax, 3
        syscall

    write_req_POST:
        mov rdi, r14
        lea rsi, req
        mov rdx, 19
        mov rax, 1
        syscall

    exit:
        mov rdi, 0
        mov rax, 60     
        syscall

get_file:
    get_file_GET:
        xor r10, r10
        xor rcx, rcx
        mov rdi, rsi
        cmp byte ptr [rdi], 0x47
        jne get_file_POST
        cmp byte ptr [rdi+1], 0x45
        jne exit
        cmp byte ptr [rdi+2], 0x54
        jne exit
        cmp byte ptr [rdi+3], 0x20
        jne exit
        add r10, 4
        lea r11, read_file
        jmp get_file_loop

    get_file_POST:
        xor r10, r10
        cmp byte ptr [rdi], 0x50
        jne get_file_fail
        cmp byte ptr [rdi+1], 0x4f
        jne exit
        cmp byte ptr [rdi+2], 0x53
        jne exit
        cmp byte ptr [rdi+3], 0x54
        jne exit
        cmp byte ptr [rdi+4], 0x20
        jne exit
        add r10, 5
        inc rcx
        lea r11, write_file
        jmp get_file_loop

    get_file_loop:
        cmp byte ptr [rdi+r10], 0x20
        je get_file_end        
        movzx r12, byte ptr [rdi+r10]
        mov byte ptr [r11], r12b
        inc r10
        inc r11
        jmp get_file_loop

    get_file_fail:
        mov rdi, -1
        mov rax, 60
        syscall
        ret

    get_file_end:
        mov byte ptr [r11], 0
        ret

get_file_cont:
    xor r11, r11
    xor r12, r12
    xor r13, r13
    mov r11, rdi
    cmp byte ptr [r11], 0x0d
    jne get_cont_loop1
    
    get_cont_loop1:
        inc r11
        cmp byte ptr [r11], 0x0d
        jne get_cont_loop1
        jmp get_cont_loop2
    
    get_cont_loop2:
        cmp dword ptr [r11], 0x0a0d0a0d
        jne get_cont_loop1
        add r11, 4
        push r11

    get_cont_len:
        inc r11
        inc r13
        movzx r12, byte ptr [r11]
        cmp r12, 0
        jne get_cont_len
        push r13
        pop rdx
        pop rsi
        ret
    
    
.section .data
    req: .string "HTTP/1.0 200 OK\r\n\r\n"
    rd_f: .space 200
    read_file: .space 100
    read_fcont: .space 500
    write_file: .space 100 
