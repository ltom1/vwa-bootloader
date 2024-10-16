bits    16

extern  ERROR

global  EnableA20
global  CheckA20

section .text


;===================================================
; EnableA20: enables the a20 address line
;===================================================

EnableA20:

        ; first of all
        ; check if the a20 line is already enabled
        call    CheckA20
        cmp     ax, 1
        je      .ENABLED
        
        ; if it isn't...

    ; ...try using 0x15 BIOS interrupt
    .BIOS:
         
        mov     ax, 0x2403                  ; int 0x15: ax=0x2403 -> check if this feature is supported
        int     0x15

        jb      .BIOS_FAIL                  ; int 0x15 not supported
        cmp     ah, 0
        jnz     .BIOS_FAIL                  ; int 0x15 not supported


        mov     ax, 0x2402                  ; int 0x15: ax=0x2402 -> check a20 gate status
        int     0x15

        jb      .BIOS_FAIL                  ; couldn't get status
        cmp     ah, 0
        jnz     .BIOS_FAIL                  ; couldn't get status


        mov     ax, 0x2401                  ; int 0x15: ax=0x2402 -> enable a20 gate
        int     0x15

        jb      .BIOS_FAIL                  ; couldn't enable
        cmp     ah, 0
        jnz     .BIOS_FAIL                  ; couldn't enable

        ; if we got that far, a20 should actually be enabled
        call    CheckA20                    ; check if it really is enabled
        cmp     ax, 1
        je      .ENABLED

    .BIOS_FAIL:


    ; ...try using the keyboard controller
    .KEYBOARD:

        cli                                 ; disable interrupts

        call    WaitCommand
        mov     al, 0xad                    ; disable keyboard
        out     0x64, al
        
        call    WaitCommand
        mov     al, 0xd0                    ; mode: read 
        out     0x64, al

        call    WaitData
        in      al, 0x60                    ; read value from data port (0x60)
        push    ax                          ; save it for later

        call    WaitCommand
        mov     al, 0xd1                    ; mode: write
        out     0x64, al

        call    WaitCommand
        pop     ax                          ; restore the read value
        or      al, 2                       ; set the second bit
        out     0x60, al                    ; send it back

        call    WaitCommand
        mov     al, 0xae                    ; reenable keyboard
        out     0x64, al

        call    WaitCommand                 ; wait until finished
        sti                                 ; enable interrupts

        call    CheckA20                    ; check if it worked
        cmp     ax, 1
        je      .ENABLED
   
        ; todo check in a loop as this method might take some time


    ; ..try enabling it by reading from IO port 0xee
    .PORT:

        in      al, 0xee                    ; the read value does not matter

        call    CheckA20                    ; check if it worked
        cmp     ax, 1
        je      .ENABLED

         
    ; ...try using the FastA20 method, which talks directly to the chipset
    ; might be risky therefore it goes last
    .FAST_A20:

        in      al, 0x92
        or      al, 2
        out     0x92, al

        call    CheckA20
        cmp     ax, 1
        je      .ENABLED
        
        ; todo check in a loop as FastA20 might take some time

         
    ; if this code is reached, it could not be activated by any of the above methods
    .COULD_NOT_ENABLE:

        call    ERROR

    .ENABLED:
        ret


    ; waits for the keyboard controller to be ready for a command
    WaitCommand:

        in      al, 0x64
        test    al, 2                       ; if second bit is not 0, the keyboard controller is busy
        jnz     WaitCommand
        ret

    ; waits for the keyboard controller to be ready for data
    WaitData:

        in      al, 0x64
        test    al, 1                       ; if first bit is not 0, the keyboard controller is busy
        jnz     WaitData
        ret


;===================================================
; CheckA20: checks if the a20 address line is enabled
; 
; ax = 1   ->  enabled
; ax = 0   ->  disabled
;===================================================

CheckA20:

    ; first check boot signature
    .FIRST:

        mov     dx, [0x7dfe]                ; save boot signature 0xAA55 at 0x7DFE (0x7C00 + 510 bytes (signature is 2 bytes long))

        mov     bx, 0xffff                  ; set up general purpose segment register es
        mov     es, bx

        mov     bx, 0x7e0e                  ; 0x7e0e: FFFF:7E0E = 1MB after the boot signature (if a20 is disabled this should wrap and be the same as the previous one)

        mov     ax, [es:bx]                 ; get the second value
        cmp     ax, dx
        jne     .ENABLED                    ; if they don't match -> it did not wrap -> a20 line is already enabled


    ; else check again but rotate the boot signature (1 byte to the right in this case)
    .SECOND:

        mov     dx, [0x7dff]                ; the same as above but one byte off (should be 0x00AA)

        mov     bx, 0xffff                
        mov     es, bx

        mov     bx, [0x7e0f]                ; + 1 byte

        mov     ax, [es:bx]
        cmp     ax, dx
        jne     .ENABLED                    ; after the second try, if it kept matching, it is pretty sure that the a20 line is disabled


    .DISABLED:                              ; if a20 is disabled
        xor     ax, ax                      ; return 0
        ret

    .ENABLED:                               ; if a20 is enabled
        mov     ax, 1                       ; return 1
        ret


;===================================================
; End
;===================================================
