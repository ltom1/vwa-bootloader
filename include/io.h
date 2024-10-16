#pragma once


#include <types.h>


u8 x86_inb(u16 port);
void x86_outb(u16 port, u8 data);

u16 x86_inw(u16 port);
void x86_outw(u16 port, u16 data);
