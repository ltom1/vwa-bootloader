asm(".code16gcc\n");

//==================================================
// Includes
//==================================================

#include <types.h>
#include <utils.h>
#include <disk.h>
#include <dbg.h>
#include <fat32.h>
#include <mmap.h>
#include <layout.h>
#include <bootinfo.h>


//==================================================
// build_bootinfo: creates the bootinfo structure at BOOT_INFO_ADDR
//==================================================

void build_bootinfo(u32 kernel_filesize) {
    BootInfo *bootinfo = (BootInfo*)BOOT_INFO_ADDR;

    bootinfo->num_regions = detect_mmap(bootinfo->regions);
    for (u32 i = 0; i < bootinfo->num_regions; i++) {
        dbg_info("Region %x%x - %x%x type=%u apci=%x\n", 
                bootinfo->regions[i].base_high, bootinfo->regions[i].base_low, 
                bootinfo->regions[i].base_high + bootinfo->regions[i].length_high, bootinfo->regions[i].base_low + bootinfo->regions[i].length_low, 
                bootinfo->regions[i].type, bootinfo->regions[i].apci);
    }
    
    bootinfo->boot_drive = BOOT_DRIVE;
    bootinfo->kernel_filesize = kernel_filesize;


    bootinfo->kernel_map.physical_low = 0; 
    bootinfo->kernel_map.physical_high = 0; 

    bootinfo->kernel_map.virtual_low = KERNEL_MAP_BASE & 0xFFFFFFFF; 
    bootinfo->kernel_map.virtual_high= (KERNEL_MAP_BASE >> 32) & 0xFFFFFFFF; 

    bootinfo->kernel_map.size_low = KERNEL_MAP_SIZE & 0xFFFFFFFF; 
    bootinfo->kernel_map.size_high= (KERNEL_MAP_SIZE >> 32) & 0xFFFFFFFF; 


    bootinfo->identity_map.physical_low = 0; 
    bootinfo->identity_map.physical_high = 0; 

    bootinfo->identity_map.virtual_low = 0; 
    bootinfo->identity_map.virtual_high= 0; 

    bootinfo->identity_map.size_low = IDENTITY_MAP_SIZE & 0xFFFFFFFF; 
    bootinfo->identity_map.size_high= (IDENTITY_MAP_SIZE >> 32) & 0xFFFFFFFF;


    bootinfo->kernel_load_addr_low = KERNEL_LOAD_ADDR & 0xFFFFFFFF; 
    bootinfo->kernel_load_addr_high = (KERNEL_LOAD_ADDR >> 32) & 0xFFFFFFFF; 

    bootinfo->kernel_load_vaddr_low = KERNEL_LOAD_VADDR & 0xFFFFFFFF; 
    bootinfo->kernel_load_vaddr_high = (KERNEL_LOAD_VADDR >> 32) & 0xFFFFFFFF; 

    bootinfo->vbr = (FAT32BPB*)BPB_ADDR;

    bootinfo->boot_partition = *(u8*)0x800;

    mem_cpy((u8*)bootinfo->partitions, (u8*)PARTITION_TABLE_ADDR, 4 * sizeof(PartitionTableEntry));
}


//==================================================
// End
//==================================================
