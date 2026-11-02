# Vorwissenschaftliche Arbeit

Bare-Metal 2-Stage 64-bit Bootloader für [vwa-kernel](https://github.com/ltom1/vwa-kernel).

Plattform: x86-64 (64-bit)

Funktionen: 
- Legacy-BIOS-Boot über den Master Boot Record (MBR)
- Zweistufige Bootloader-Architektur (Stage 1 und Stage 2)
- CPU-Initialisierung und Vorbereitung der Kernel-Ausführung
- Unterstützung mehrerer MBR-Partitionen
- FAT32 Dateisystem
- Laden des Kernels (KERNEL.BIN) von einer FAT32-Partition
- Eigenes Boot-Info-Format zur Übergabe von Informationen an den Kernel
