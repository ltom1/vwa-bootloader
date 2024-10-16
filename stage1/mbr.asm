bits    16

org     0x0600


;===================================================
; MBR_START: starting point (will relocate MBR and stack to 0x0600)
;===================================================

MBR_START:

   ; initialize segments
    cli
    mov     ax, 0x0000      ; code loaded at 0x0000:0x7c00
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax

    ; initialize stack
    xor     ax, ax
    mov     ss, ax
    sti

    mov     ax, 0x0600
    mov     bp, ax
    mov     sp, ax
    
    cld
    mov     esi, 0x7c00
    mov     edi, 0x0600 
    mov     ecx, 0x0100
    rep     movsw

    jmp     0x0000:MBR_RELOCATED


;===================================================
; MBR_RELOCATED: MBR now at 0x0600
;===================================================

MBR_RELOCATED:

    mov     BYTE [BOOT_DRIVE], dl
    xor     cx, cx

    mov     al, BYTE [PARTITION_TABLE_ENTRY1_ADDR]
    cmp     al, 0x80
    mov     bx, PARTITION_TABLE_ENTRY1_ADDR
    je      .LOAD

    inc     cl
    mov     al, BYTE [PARTITION_TABLE_ENTRY2_ADDR]
    cmp     al, 0x80
    mov     bx, PARTITION_TABLE_ENTRY2_ADDR
    je      .LOAD
    
    inc     cl
    mov     al, BYTE [PARTITION_TABLE_ENTRY3_ADDR]
    cmp     al, 0x80
    mov     bx, PARTITION_TABLE_ENTRY3_ADDR
    je      .LOAD
    
    inc     cl
    mov     al, BYTE [PARTITION_TABLE_ENTRY4_ADDR]
    cmp     al, 0x80
    mov     bx, PARTITION_TABLE_ENTRY4_ADDR
    je      .LOAD
    
    jmp     ERROR.NO_BOOTABLE_PARTITION


;===================================================
; .LOAD: loads the VBR of the first bootable partition
;===================================================

.LOAD:

    mov     BYTE [MBR_PARTITION_NUM_ADDR], cl
    mov     BYTE [MBR_LOADED_ADDR], 1

    add     bx, PARTITION_TABLE_LBA_START_OFFSET
    mov     eax, DWORD [bx]
    mov     DWORD [MBR_PARTITION_START_LBA_ADDR], eax

    mov     DWORD [lba], eax

    call    ReadSectors

    mov     ax, WORD [VBR_SIGN_ADDR]
    cmp     ax, VBR_SIGN
    jne     ERROR.INVALID_SIGNATURE

    mov     dl, BYTE [BOOT_DRIVE]

    ; jump to stage2
    jmp     0x0000:VBR_LOAD_ADDR


;===================================================
; ReadSectors: reads sectors from BOOT_DRIVE according to dap
;===================================================

ReadSectors:

    clc
    mov     si, dap
    mov     ah, 0x42
    mov     dl, [BOOT_DRIVE]
    int     0x13

    jc      short ERROR.DISK
    ret


;===================================================
; HLT: halts the CPU
;===================================================

HLT:
    cli

    .loop:
        hlt
        jmp .loop


;===================================================
; ERROR: executed when error occured
;===================================================

ERROR:
    .DISK:
        mov     al, 0x44    ; D
        jmp     .COMMON
    .NO_BOOTABLE_PARTITION:
        mov     al, 0x42    ; B
        jmp     .COMMON
    .INVALID_SIGNATURE:
        mov     al, 0x53    ; S
        jmp     .COMMON

    .COMMON:
        mov     ah, 0x0E
        int     0x10

        jmp     HLT


;===================================================
; Variables
;===================================================

    PARTITION_TABLE_ENTRY1_ADDR         equ 0x0600 + 0x1be
    PARTITION_TABLE_ENTRY2_ADDR         equ 0x0600 + 0x1ce
    PARTITION_TABLE_ENTRY3_ADDR         equ 0x0600 + 0x1de
    PARTITION_TABLE_ENTRY4_ADDR         equ 0x0600 + 0x1ee

    MBR_PARTITION_NUM_ADDR              equ 0x0800
    MBR_LOADED_ADDR                     equ 0x0801
    MBR_PARTITION_START_LBA_ADDR        equ 0x0802

    PARTITION_TABLE_LBA_START_OFFSET    equ 8
    
    VBR_LOAD_ADDR                       equ 0x7c00
    VBR_SIGN_ADDR                       equ VBR_LOAD_ADDR + 510

    VBR_SIGN                            equ 0xAA55


    BOOT_DRIVE:                         db 0
    

    dap:
	    db	0x10            ; size 16B
	    db	0               ; always 0
    num_sectors:	
        dw	1		        ; will be set to the sectors actually written
    buf:	
        dw	VBR_LOAD_ADDR	; memory buffer destination address (0:7c00)
	    dw	0		        ; segment
    lba:	
        dd	0		        ; start address
	    dd	0		        ; for big lbas


;===================================================
; End
;===================================================
