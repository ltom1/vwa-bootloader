#pragma once


#include <types.h>


typedef struct {

    u8  jmp[3];
    u8  oem_id[8];
    u16 bytes_per_sector;
    u8  sectors_per_cluster;
    u16 reserved_sectors;
    u8  num_fats;
    u16 max_root_entries;
    u16 num_sectors;
    u8  media_descriptor;

    // IMPORTANT: not used by FAT32
    u16 sectors_per_fat;

    u16 sectors_per_track;
    u16 sectors_per_head;
    u32 hidden_sectors;
    u32 total_sectors;

    // IMPORTANT: used by FAT32
    u32 big_sectors_per_fat;

    u16 flags;
    u16 fs_version;
    u32 root_directory_start;
    u16 fs_info_sector;
    u16 backup_boot_sector;

    u8  reserved[12];

    u8  drive_num;
    u8  reserved_byte;
    u8  signature;
    u32 volume_id;
    u8  volume_label[11];
    u8  system_id[8];

} PACKED FAT32BPB;


typedef struct {

    u8  attr;

    u8  c_start;
    u8  h_start;
    u8  s_start;

    u8  type;

    u8  c_end;
    u8  h_end;
    u8  s_end;

    u32 lba_start;
    u32 num_sectors;

} PACKED PartitionTableEntry;

#define PARTITION_TABLE_ADDR        0x7be
#define BPB_ADDR                    0x7c00

#define ROOT_DIR_LOAD_ADDR          0x9c00
#define FAT_LOAD_ADDR               0xac00
#define FAT32_FILENAME_SIZE         11
#define FAT32_ENTRIES_PER_CLUSTER   1024

#define FAT32_EOF                   0x0FFFFFF8  // if cluster number >= FAT32_EOF -> last cluster
#define FAT32_BAD                   0x0FFFFFF7  // if cluster number >= FAT32_EOF -> last cluster
#define FAT32_CLUSTER_MASK          0xFFFFFFF   // highest 4 bits are reserved and ignored
#define FAT32_DIR_ENTRY_SIZE        32

#define FAT32_DIR_ENTRY_HIGH_LBA    20
#define FAT32_DIR_ENTRY_LOW_LBA     26
#define FAT32_FILESIZE              28

u32 fat32_load_file(const char* filename, u32 buf);
void fat32_load_cluster(u32 cluster, u32 buf);
void fat32_init(void);
