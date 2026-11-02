# Vorwissenschaftliche Arbeit – x86-64 Bootloader

Ein eigenständig entwickelter, zweistufiger 64-Bit-Bootloader für den [VWA Kernel](https://github.com/ltom1/vwa-kernel).

Der Bootloader initialisiert die CPU und lädt den Kernel von einem FAT32-Datenträger in den Speicher.

**Plattform:** x86-64 (64 Bit)  
**Bootverfahren:** Legacy BIOS / MBR

## Funktionen

- Legacy-BIOS-Boot über den Master Boot Record (MBR)
- Zweistufige Bootloader-Architektur (Stage 1 und Stage 2)
- CPU-Initialisierung und Vorbereitung des 64-Bit-Kernelstarts
- Unterstützung mehrerer MBR-Partitionen
- FAT32-Dateisystemunterstützung
- Laden des Kernels (`KERNEL.BIN`) von einer FAT32-Partition
- Eigenes Boot-Info-Format zur Übergabe von Informationen und Bootparametern an den Kernel
