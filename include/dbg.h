#pragma once


#include <types.h>


#define DBG_PORT 0xE9

void dbg_info(char *fmt, ...);
void dbg_warn(char *fmt, ...);
void NORETURN dbg_err(char *fmt, ...);
