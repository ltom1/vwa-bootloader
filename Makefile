AS=nasm
CC=gcc
LK=ld
DBG=gdb

VM=qemu-system-x86_64

DISK_FORMAT=fdisk
DISK_FORMAT_COMMANDS=fdisk.txt
DISK_WRITE=dd

OBJCPY=objcopy
TERM=alacritty
WORKING_DIR=$(shell pwd)

STAGE2_AS_SRC=$(wildcard stage2/*.asm)
STAGE2_AS_OBJ=$(patsubst %.asm,%.o,$(STAGE2_AS_SRC))

STAGE2_C_SRC=$(wildcard stage2/*.c)
STAGE2_C_OBJ=$(patsubst %.c,%.o,$(STAGE2_C_SRC))

STAGE2_LINKER_SCRIPT=stage2/stage2.ld


IMG_SIZE_SECTORS=6000000
LOOP=/dev/loop0
LOOPP1=/dev/loop0p1
LOOPP2=/dev/loop0p2

IMG=os.img
KERNEL_SECTOR_SIZE=20
KERNEL_BIN=KERNEL.BIN
MNT=/mnt

all: clean run

run: $(IMG)
	$(VM) -d int -no-reboot -debugcon stdio -hda $<

debug: $(IMG)
	$(TERM) --working-directory $(WORKING_DIR) -e $(VM) -s -S -d int -no-reboot -debugcon stdio -hda $< &
	$(DBG) stage2.elf \
        -ex 'target remote localhost:1234' \
        -ex 'layout src' \
        -ex 'layout regs' \
        -ex 'break boot16' \
        -ex 'continue'

$(IMG): stage1.bin stage2.bin
	dd if=/dev/zero of=$@ bs=1 count=440 conv=notrunc
	dd if=stage1.bin of=$@ bs=1 count=440 conv=notrunc 

	dd if=$@ of=bpb.bin bs=1 skip=1048579 count=87 conv=notrunc
	dd if=stage2.bin of=$@ bs=1 seek=1048576 count=8192 conv=notrunc
	dd if=bpb.bin of=$@ bs=1 seek=1048579 count=87 conv=notrunc

stage1.bin: stage1/mbr.asm
	$(AS) -f bin $< -o $@

stage2.bin: stage2.elf
	$(OBJCPY) -O binary $< $@

stage2.elf: $(STAGE2_AS_OBJ) $(STAGE2_C_OBJ)
	$(LK) -m elf_i386 -o $@ -T $(STAGE2_LINKER_SCRIPT) $^

%.o: %.asm
	$(AS) -g3 -F dwarf -f elf32 $< -o $@

%.o: %.c
	$(CC) -Wall -Iinclude -m16 -ffreestanding -fno-pie -fno-stack-protector -g -c $< -o $@


img:
	$(DISK_WRITE) if=/dev/zero count=$(IMG_SIZE_SECTORS) of=$(IMG)
	#$(DISK_WRITE) if=/dev/zero bs=512 count=$(KERNEL_SECTOR_SIZE) | tr '\000' '1' > $(KERNEL_BIN)
	$(DISK_FORMAT) $(IMG) < $(DISK_FORMAT_COMMANDS)
	sudo losetup -P $(LOOP) $(IMG)
	sudo mkfs.vfat -F32 -f2 -R16 -s8 -S512 -v $(LOOPP1)
	sudo mkfs.vfat -F32 -f2 -R16 -s8 -S512 -v $(LOOPP2)
	sudo mount $(LOOPP1) $(MNT)
	sudo cp $(KERNEL_BIN) $(MNT)
	sudo umount $(LOOPP1)
	sudo losetup -d $(LOOP)

clean:
	rm -f -- *.bin
	rm -f -- stage1/*.bin
	rm -f -- stage2/*.bin
	rm -f -- *.mem
	rm -f -- *.o
	rm -f -- stage1/*.o
	rm -f -- stage2/*.o
	rm -f -- *.elf
	
