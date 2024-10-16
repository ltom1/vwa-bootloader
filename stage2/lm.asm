; https://wiki.osdev.org/Entering_Long_Mode_Directly

bits    16


    %define PAGE_PRESENT    (1 << 0)
    %define PAGE_WRITE      (1 << 1)
    %define PAGE_HUGE       (1 << 7)

global  CheckLongMode
global  EnterLongMode


KERNEL_ENTRY_VADDR  equ 0x00000000c0010000
BOOT_INFO_VADDR     equ 0x00000000c0001000

section .text


;===================================================
; CheckLongMode: checks for long mode support;
;
; ax = 1   ->  supported
; ax = 0   ->  not supported
;===================================================

CheckLongMode:
    ; check for cpuid:
    ; update flags by changing bit 21
    pushfd
    pop     eax
    mov     ecx, eax
    xor     eax, 1 << 21
    push    eax
    popfd
    
    ; check if setting the bit was successful
    pushfd
    pop     eax
    xor     eax, ecx
    shr     eax, 21     ; isolating
    and     eax, 1      ; trimming
    push    ecx
    popfd

    test    eax, eax
    jz      .NOT_SUPPORTED

    ; cpuid available
    mov     eax, 0x80000000   
    cpuid
    
    ; check if 0x80000001 function of cpuid is available
    cmp     eax, 0x80000001
    jb      .NOT_SUPPORTED

    ; 0x80000001 available
    mov     eax, 0x80000001
    cpuid

    ; test for long mode bit (29th)
    test    edx, 1 << 29
    jz      .NOT_SUPPORTED
    
    mov     ax, 1
    ret

.NOT_SUPPORTED:
    mov     ax, 0
    ret


;===================================================
; EnterLongMode: switches to long mode: identity maps first 1GB (using huge 2MB pages)
;===================================================
    
    %define PT4          0x2000
    %define PT3          0x3000
    %define PT2_IDENTITY 0x4000
    %define PT2_KERNEL   0x5000

    %define CODE_SEG     0x0008
    %define DATA_SEG     0x0010
 

EnterLongMode:

    ; zero out page table locations
    ; ecx=0x1000 -> 0x1000 times 4 zero bytes -> 4 pages (starting from PT4)
    mov     edi, PT4
    mov     ecx, 0x1000
    xor     eax, eax
    cld
    rep     stosd
 
    ; build PT4
    mov     eax, PT3
    or      eax, PAGE_PRESENT | PAGE_WRITE
    mov     [PT4], eax 
 
 
    ; build PT3
    mov     eax, PT2_IDENTITY
    or      eax, PAGE_PRESENT | PAGE_WRITE 
    mov     [PT3], eax
    mov     eax, PT2_KERNEL
    or      eax, PAGE_PRESENT | PAGE_WRITE
    mov     [PT3 + 3 * 8], eax        

  ; fill identity mapping page table and kernel page table (kernel is also identity mapped + 0xc0000000)
    mov     ecx, 0                          ; counter (512 entries)

    ; loop through entries
    .LOOP:
        mov     eax, 0x200000
        mul     ecx
        or      eax, PAGE_WRITE | PAGE_PRESENT | PAGE_HUGE

        mov     DWORD [PT2_IDENTITY + ecx * 8], eax
        mov     DWORD [PT2_KERNEL + ecx * 8], eax

        inc     ecx                             ; next entry
        cmp     ecx, 512
        jne     .LOOP

    ; disable IRQs
    mov     al, 0xFF
    out     0xA1, al
    out     0x21, al
 
    nop
    nop

    ; zero IDT -> any unexpected exception will cause a triple fault
    cli
    lidt    [IDT]
    sti
 
    ; enter long mode.
    mov     eax, 10100000b          ; PAE and paging bits
    mov     cr4, eax
 
    mov     edx, PT4                ; cr3 -> PT4
    mov     cr3, edx
 
    mov     ecx, 0xC0000080         ; read from the EFER MSR. 
    rdmsr    
 
    or      eax, 0x00000100         ; LME bit
    wrmsr
 
    mov     ebx, cr0                ; activate long mode
    or      ebx,0x80000001          ; enable paging and protection simultaneously
    mov     cr0, ebx                    

    cli
    lgdt    [GDT.Pointer]           ; load GDT
    sti

    jmp     CODE_SEG:LongMode       ; load cs with 64 bit segment and flush the instruction cache
 
 

bits    64      

LongMode:
    
    ; reload segment registers
    mov     ax, DATA_SEG
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    ; pass boot info to kernel
    mov     rbx, BOOT_INFO_VADDR

    ; jmp to higher half kernel
    mov     rdi, KERNEL_ENTRY_VADDR
    push    rdi
    ret


;===================================================
; Variables
;===================================================

section .data

bits    16
 
ALIGN 4
IDT:
    .Length       dw 0
    .Base         dd 0

 
GDT:
.Null:
    dq  0x0000000000000000             ; null descriptor required
 
.Code:
    dq  0x00209A0000000000             ; 64-bit code descriptor (exec/read)
    dq  0x0000920000000000             ; 64-bit data descriptor (read/write)
 
ALIGN 4
    dw  0                              ; Padding to make the "address of the GDT" field aligned on a 4-byte boundary
 
.Pointer:
    dw  $ - GDT - 1                    ; 16-bit Size (Limit) of GDT.
    dd  GDT                            ; 32-bit Base Address of GDT. (CPU will zero extend to 64-bit)


;===================================================
; End
;===================================================
