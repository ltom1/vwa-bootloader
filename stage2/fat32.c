asm(".code16gcc\n");

//==================================================
// Includes
//==================================================

#include <types.h>
#include <disk.h>
#include <dbg.h>
#include <fat32.h>


FAT32BPB *bpb = (FAT32BPB*)BPB_ADDR;
PartitionTableEntry *partitions = (PartitionTableEntry*)PARTITION_TABLE_ADDR;
u32 *fat = (u32*)FAT_LOAD_ADDR;

u32 partition_start_lba = 0;
u32 fat_start_lba = 0;
u32 data_start_lba = 0;
u32 cur_fat_cluster = 0;

bool fat32_cmp_filenames(const char *filename1, const char *filename2);


//==================================================
// fat32_init: initializes fat32 filesystem
//==================================================

void fat32_init(void) {
    for (u8 i = 0; i < 4; i++) {
        dbg_info("Partition %u: lba_start=%u num_sectors=%u attr=%x\n", i, partitions[i].lba_start, partitions[i].num_sectors, partitions[i].attr);
    }
    partition_start_lba = *(u32*)0x0802;
    fat_start_lba = partition_start_lba + bpb->reserved_sectors;
    data_start_lba = fat_start_lba + bpb->num_fats * bpb->big_sectors_per_fat;
    
    dbg_info("partition_start_lba=%u\n", partition_start_lba);
    dbg_info("fat_start_lba=%u\n", fat_start_lba);
    dbg_info("data_start_lba=%u\n", data_start_lba);

    fat32_load_cluster(bpb->root_directory_start, ROOT_DIR_LOAD_ADDR);
    disk_read(fat_start_lba, bpb->sectors_per_cluster, FAT_LOAD_ADDR);
}


//==================================================
// fat32_load_cluster: loads a FAT32 cluster into buf
//==================================================

void fat32_load_cluster(u32 cluster, u32 buf) {

    u32 cluster_start_lba = data_start_lba + (cluster - 2) * bpb->sectors_per_cluster;
    disk_read(cluster_start_lba, bpb->sectors_per_cluster, buf);
}


//==================================================
// fat32_load_cluster_chain: loads all FAT32 clusters of a file into buf
//==================================================

void fat32_load_cluster_chain(u32 cluster, u32 buf) {

    u32 next_cluster = cluster;

    while (1) {
        if (next_cluster == FAT32_BAD) dbg_err("Bad cluster %x\n", next_cluster);

        dbg_info("Cluster chain: Loading cluster %x\n", next_cluster);
        fat32_load_cluster(next_cluster, buf);
        buf += bpb->sectors_per_cluster * 512;

        if (cur_fat_cluster != cluster / FAT32_ENTRIES_PER_CLUSTER) {
            cur_fat_cluster = cluster / FAT32_ENTRIES_PER_CLUSTER;
            disk_read(fat_start_lba + cur_fat_cluster * bpb->sectors_per_cluster, bpb->sectors_per_cluster, FAT_LOAD_ADDR);
        }

        next_cluster = fat[next_cluster % FAT32_ENTRIES_PER_CLUSTER];
        next_cluster &= FAT32_CLUSTER_MASK;
        if (next_cluster >= FAT32_EOF) return;
    }
}


//==================================================
// fat32_load_file: loads a FAT32 file into buf and returns the filesize
//==================================================

u32 fat32_load_file(const char *filename, u32 buf) {
    for (u32 i = ROOT_DIR_LOAD_ADDR; i < ROOT_DIR_LOAD_ADDR + bpb->sectors_per_cluster * 512; i += FAT32_DIR_ENTRY_SIZE) {

        if (*(u8*)i == 0) dbg_err("Could not find file \'%s\'\n", filename); // reached end of directory

        if (fat32_cmp_filenames(filename, (const char*)i)) {

            u32 start_cluster = DWORD(*(u16*)(i + FAT32_DIR_ENTRY_HIGH_LBA), *(u16*)(i + FAT32_DIR_ENTRY_LOW_LBA));

            dbg_info("i=%x start_cluster=%x\n", i, start_cluster);
            fat32_load_cluster_chain(start_cluster, buf);
            dbg_info("Loaded file %s\n", filename);

            return *(u32*)(i + FAT32_FILESIZE);
        }
    }
    dbg_err("Could not find file \'%s\'\n", filename); // reached end of directory todo: read following clusters but idc
}


//==================================================
// fat32_cmp_filenames: compares two filenames
//==================================================

bool fat32_cmp_filenames(const char* filename1, const char *filename2) {
    for (u32 i = 0; i < FAT32_FILENAME_SIZE; i++) {
        if (filename1[i] != filename2[i]) return false;
    }
    return true;
}


//==================================================
// End
//==================================================
