bits    16

extern boot16

global dap
global ReadSectors
global PARTITION_INFO_ADDR
global ERROR
global BOOT_DRIVE

;===================================================
; starting point (placed at 0x7c00)
;===================================================

section .bootsector

jmp     short BPB_END
nop


;===================================================
; BIOS Parameter Block (BPB) will be overwritten
;===================================================

    OEM_ID                db 		"mkfs.fat"
    BytesPerSector        dw 		0x0200    
    SectorsPerCluster     db 		0x08      
    ReservedSectors       dw 		0x0008    
    TotalFATs             db 		0x02           ; second FAT for backup
    MaxRootEntries        dw 		0x0000         ; no fixed size for FAT32 -> 0
    NumberOfSectors       dw 		0x0000         ; more than 65535 sectors -> TotalSectors
    MediaDescriptor       db 		0xf8           ; normal hard drive
    SectorsPerFAT         dw 		0x0000         ; FAT12/FAT16 only
    SectorsPerTrack       dw 		0x003d    
    NumberOfHeads         dw 		0x0002    
    HiddenSectors         dd 		0x00000000     
    TotalSectors     	  dd 		0x001ffff8     ; 2097144 in total	
    BigSectorsPerFAT      dd 		0x00000800     ; 2048 per FAT
    Flags                 dw 		0x0000         ; both FATs synced
    FSVersion             dw 		0x0000         
    RootDirectoryStart    dd 		0x00000002     ; starts from first cluster (cluster 2)
    FSInfoSector          dw 		0x0001    
    BackupBootSector      dw 		0x0006         ; backup in 6th sector

    times 12              db        0x00           ; reserved always zero

    DriveNumber           db 		0x80           ; first hard drive
    ReservedByte          db   	    0x00           ; reserved always zero
    Signature             db 		0x29
    VolumeID              dd 		0xffffffff     ; serial number
    VolumeLabel           db 		"BOOT LOADER"  ; drive label
    SystemID              db 		"FAT32   "     ; file system type


;===================================================
; BPB_END: end of BPB
;===================================================

BPB_END:
    
    ; flush cs
    jmp     0x0000:STAGE2_START


;===================================================
; STAGE2_START: logic starting point
;===================================================

STAGE2_START:

    ; save boot drive number loaded into dl by BIOS todo old BIOS won't do that
    mov     BYTE [BOOT_DRIVE], dl

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

    mov     ax, 0x7c00
    mov     bp, ax
    mov     sp, ax


    ; updates hard drive geometry (BPB might be wrong)
    mov     ah, 8
    int     0x13
    inc     dh
    mov     BYTE [NumberOfHeads], dh
    and     cl, 0x3f
    mov     BYTE [SectorsPerTrack], cl
    
    ; gets partition info from stage1 (MBR)
    mov     dl, BYTE [MBR_LOADED_ADDR]
    cmp     dl, 1   ; check if this is the VBR or the MBR

    je      .VBR
    jmp     .MBR

.VBR:

    mov     esi, MBR_PARTITION_START_LBA_ADDR
    mov     edi, PARTITION_OFFSET_LBA

    movsd

.MBR:

    mov     eax, DWORD [PARTITION_OFFSET_LBA]
    add     eax, REL_SECTOR_START_REST
    mov     DWORD [lba], eax 

    mov     WORD [num_sectors], SECTOR_SIZE_REST
    mov     WORD [buf], REST_LOAD_ADDR

    call    ReadSectors

    ; jump to the second stage
    call    boot16


;===================================================
; ReadSectors: reads sectors from BOOT_DRIVE according to dap
;===================================================

ReadSectors:

    clc
    mov     si, dap
    mov     ah, 0x42
    mov     dl, BYTE [BOOT_DRIVE]

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
    .A20:
        mov     al, 0x41    ; A
        jmp     .COMMON
    .DISK:
        mov     al, 0x44    ; D
        jmp     .COMMON

    .COMMON:
        mov     ah, 0x0E
        int     0x10

        jmp     HLT


;===================================================
; Variables
;===================================================

    BOOT_DRIVE:             db 0


    align 4

    dap:
	    db	0x10    ; size 16B
	    db	0       ; always 0
    num_sectors:	
        dw	0		; will be set to the sectors actually written
    buf:	
        dw	0		; memory buffer destination address (0:7c00)
	    dw	0		; segment
    lba:	
        dd	1		; start address
	    dd	0		; for big lbas

    PARTITION_OFFSET_LBA:               dd 0

    REL_SECTOR_START_REST               equ 1
    SECTOR_SIZE_REST                    equ 15
    REST_LOAD_ADDR                      equ 0x7e00

    PARTITION_ENTRY_LBA_START_OFFSET    equ 0x08

    MBR_PARTITION_START_LBA_ADDR        equ 0x0802
    MBR_LOADED_ADDR                     equ 0x0801
    MBR_PARTITION_NUM_ADDR              equ 0x0800

    PARTITION_TABLE_ADDR                equ 0x0600 + 0x1be

    PARTITON_TABLE_ENTRY_SIZE           equ 16


;===================================================
; End
;===================================================
