#pragma once


#include <types.h>
#include <mmap.h>
#include <fat32.h>


typedef struct {
    u32 physical_low;
    u32 physical_high;
    u32 virtual_low;
    u32 virtual_high;
    u32 size_low;
    u32 size_high;
} PACKED Mapping;

typedef struct {
    u8 boot_drive;

    u32 kernel_filesize;

    u32 kernel_load_addr_low;
    u32 kernel_load_addr_high;
    u32 kernel_load_vaddr_low;
    u32 kernel_load_vaddr_high;

    Mapping identity_map;
    Mapping kernel_map;

    FAT32BPB *vbr;
    u8 boot_partition;
    PartitionTableEntry partitions[4];
    
    u32 num_regions;
    MemRegion regions[];
} PACKED BootInfo;


void build_bootinfo(u32 kernel_filesize);
