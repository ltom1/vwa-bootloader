asm(".code16gcc\n");

//==================================================
// Includes
//==================================================

#include <types.h>
#include <disk.h>
#include <dbg.h>


extern void ReadSectors(void);
extern DAP dap;


//==================================================
// disk_read: reads <num_sec> sectors from <sec_start> to address <buf>
//==================================================

void disk_read(u32 sec_start, u16 num_secs, u32 buf) {

    dap.num_secs = num_secs;
    dap.lba1 = sec_start;

    // error if buf is larger than the highest possible address using segment:offset addressing
    if (buf > SEG_OFF_MAX) dbg_err("buf exceeds seg:off limit");

    u32 seg = buf / 16;
    if (seg > U16_MAX) {
        dap.buf_seg = U16_MAX;
    } else {
        dap.buf_seg = buf / 16;
    }

    dap.buf_off = buf - (16 * dap.buf_seg);

    dbg_info("\nReading from disk\ndap_size=%u\nnum_secs=%u\nbuf_off=%x\nbuf_seg=%x\nlba1=%u\nlba2=%u\n",
            dap.dap_size, dap.num_secs, dap.buf_off, dap.buf_seg, dap.lba1, dap.lba2);
    ReadSectors();
    dbg_info("Finished reading\n");
}


//==================================================
// End
//==================================================
