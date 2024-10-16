asm(".code16gcc\n");

//==================================================
// Includes
//==================================================

#include <types.h>
#include <dbg.h>
#include <mmap.h>


//==================================================
// detect_mem_map: detects the memory map, loads it into buf and returns the number of entries 
//==================================================

u32 detect_mmap(MemRegion *buf) {
    u32 continuation = 0;
    u32 entries = 0;
    u32 signature;
    u32 num_bytes;

    do {
        asm volatile ("int  $0x15" 
				: "=a"(signature), "=c"(num_bytes), "=b"(continuation)
				: "a"(0xE820), "b"(continuation), "c"(24), "d"(E820_SIGNATURE), "D"(buf));

        if (signature != E820_SIGNATURE) dbg_err("Error E820 invalid signature\n");

        if (num_bytes > 20 && (buf->apci & 0x0001) == 0) {
            // ignored byte not set -> will be ignored
        } else {
            buf++;
            entries++;
        }
            
    } while (continuation != 0 && entries < MAX_REGIONS);

    return entries;
}


//==================================================
// End
//==================================================
