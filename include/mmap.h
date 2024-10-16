#pragma once


#include <types.h>


typedef struct {
    u32 base_low;
    u32 base_high;
    u32 length_low;
    u32 length_high;
    u32 type;
    u32 apci;
} PACKED MemRegion;

#define E820_SIGNATURE          0x534d4150

#define REGIONS_BUF_SIZE        0x1000
#define MAX_REGIONS             (REGIONS_BUF_SIZE / sizeof(MemRegion))

u32 detect_mmap(MemRegion *buf);
