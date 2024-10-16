asm(".code16gcc\n");

//==================================================
// Includes
//==================================================

#include <types.h>
#include <disk.h>
#include <dbg.h>
#include <fat32.h>
#include <mmap.h>
#include <layout.h>
#include <bootinfo.h>


extern void EnableA20(void);
extern bool CheckA20(void);

extern bool CheckLongMode(void);
extern void NORETURN EnterLongMode(void);

u32 kernel_filesize = 0;
u32 load_kernel(void);


//==================================================
// Boot main 
//==================================================

void NORETURN boot16(void) {

    dbg_info("Entered Boot Main\n");
    dbg_info("Test:\n%d\n%u\n%s\n%c\n%x\n%p\n%%\n%l\nEND\n", -1234, 1234, "String", 'X', 0xDEADBEEF, 0xC0FFEE);

    u32 kernel_filesize = load_kernel();

    build_bootinfo(kernel_filesize);

    EnableA20();
    if (CheckA20()) {
        dbg_info("A20 enabled\n");
    } else {
        dbg_err("Couldn't enable A20\n");
    }

    if (CheckLongMode()) {
        dbg_info("Long mode supported\n");
    } else {
        dbg_err("Long mode not supported\n");
    }

    EnterLongMode();
}


//==================================================
// load_kernel: loads the kernel into KERNEL_LOAD_ADDR and returns the kernel's filesize
//==================================================

u32 load_kernel(void) {

    fat32_init();
    return fat32_load_file("KERNEL  BIN", KERNEL_LOAD_ADDR);
}


//==================================================
// End
//==================================================
