#pragma once


typedef char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef signed char s8;
typedef signed short s16;
typedef signed int s32;
typedef unsigned long long u64;
typedef long long s64;

#define NORETURN __attribute((noreturn))
#define PACKED __attribute((packed))

#define bool        _Bool
#define true        1
#define false       0

#define U8_MAX      0xff 
#define U16_MAX     0xffff 
#define U32_MAX     0xffffffff 
#define U64_MAX     0xffffffffffffffff 

#define DWORD(high, low) ((high << 16) + low)
#define WORD(high, low) ((high << 8) + low)
