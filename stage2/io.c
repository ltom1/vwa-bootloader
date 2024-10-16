asm(".code16gcc\n");

//==================================================
// Includes
//==================================================

#include <types.h>
#include <io.h>


//==================================================
// x86_inb: reads a byte from port <port>
//==================================================

u8 x86_inb(u16 port) {

     u8 res;

     // "=a" (res) -> eax into res
     // "d" (port) -> port into edx
     __asm__("in %%dx, %%al" : "=a" (res) : "d" (port));

     return res;
}


//==================================================
// x86_outb: writes byte <data> to port <port>
//==================================================

void x86_outb(u16 port, u8 data) {

     // "a" (data) -> data into eax
     // "d" (port) -> port into edx
     __asm__("out %%al, %%dx" : : "a" (data), "d" (port));
}


//==================================================
// x86_inw: reads a word from port <port>
//==================================================

u16 x86_inw(u16 port) {

     u16 res;

     // "=a" (res) -> eax into res
     // "d" (port) -> port into edx
     __asm__("in %%dx, %%ax" : "=a" (res) : "d" (port));

     return res;
}


//==================================================
// x86_outw: writes word <data> to port <port>
//==================================================

void x86_outw(u16 port, u16 data) {

     // "a" (data) -> data into eax
     // "d" (port) -> port into edx
     __asm__("out %%ax, %%dx" : : "a" (data), "d" (port));
}


//==================================================
// End
//==================================================
