#pragma once


#include <types.h>


#define SEG_OFF_MAX 0x10FFEF


typedef struct {
    u8 dap_size;
    u8 zero;
    u16 num_secs;
    u16 buf_off; 
    u16 buf_seg;
    u32 lba1;
    u32 lba2;
} PACKED DAP;

#define BOOT_DRIVE 0x80


void disk_read(u32 sec_start, u16 num_secs, u32 buf);
