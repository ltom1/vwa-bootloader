asm(".code16gcc\n");

//==================================================
// Includes
//==================================================

#include <types.h>
#include <dbg.h>
#include <io.h>

#include <stdarg.h>


void dbg_putf(char *fmt, va_list vl);

void dbg_putc(char c);
void dbg_putd(s32 num);
void dbg_putu(u32 num);
void dbg_putx(u32 hex);
void dbg_puts(const char *str);


//==================================================
// dbg_info: writes information to debug
//==================================================

void dbg_info(char *fmt, ...) {

    va_list vl;
    va_start(vl, fmt);

    dbg_puts("\033[32m[INFO]   : ");
    dbg_putf(fmt, vl);

    va_end(vl);
}


//==================================================
// dbg_warn: writes warning to debug
//==================================================

void dbg_warn(char *fmt, ...) {

    va_list vl;
    va_start(vl, fmt);

    dbg_puts("\033[33m[WARNING]: ");
    dbg_putf(fmt, vl);

    va_end(vl);
}


//==================================================
// dbg_err: writes error to debug
//==================================================

void NORETURN dbg_err(char *fmt, ...) {

    va_list vl;
    va_start(vl, fmt);

    dbg_puts("\033[31m[ERROR]  : ");
    dbg_putf(fmt, vl);

    va_end(vl);

    while (1);
}


//==================================================
// dbg_putc: writes char c to debug
//==================================================

void dbg_putc(char c) {
    x86_outb(DBG_PORT, c);
}


//==================================================
// dbg_putf: prints a formatted string to debug
//==================================================

void dbg_putf(char *fmt, va_list vl) {

    char c;
    for (u32 i = 0; (c = fmt[i]) != 0; i++) {
        
        if (c != '%') {
            dbg_putc(c);
            continue;
        }

        i++;
        c = fmt[i];
        switch (c) {
            case 'd':
                dbg_putd((u32)va_arg(vl, int));
                break;
            case 'u':
                dbg_putu((s32)va_arg(vl, int));
                break;
            case 's':
                dbg_puts((const char*)va_arg(vl, int));
                break;
            case 'c':
                dbg_putc((char)va_arg(vl, int));
                break;
            case 'x':
            case 'p':
                dbg_putx((u32)va_arg(vl, int));
                break;
            case '%':
                dbg_putc('%');
                break;
            default:
                dbg_putc('%');
                dbg_putc(c);
                break;
        }
    }
}


//==================================================
// dbg_putu: prints an u32 to debug
//==================================================

void dbg_putu(u32 num) {

    char buf[16];
    s32 i = 0;

    do {
        buf[i++] = num % 10 + '0';
    } while ((num /= 10) != 0);

    while (--i >= 0)
        dbg_putc(buf[i]);
}


//==================================================
// dbg_putd: prints a s32 to debug
//==================================================

void dbg_putd(s32 num) {

    if (num < 0) {
        dbg_putc('-');
        num *= -1;
    }
    dbg_putu(num);
}


//==================================================
// dbg_putx: prints an u32 hex to debug
//==================================================

void dbg_putx(u32 hex) {

    u32 tmp;
    for (s32 i = 7; i >= 0; i--) {
        tmp = hex;
        tmp = tmp >> i * 4;
        tmp &= 0xf;
        tmp += ((tmp < 10) ? '0' : 'a' - 10);
        dbg_putc(tmp);
    }
}

//==================================================
// dbg_putd: prints a null-terminated string to debug
//==================================================

void dbg_puts(const char *str) {

    u32 i = 0;
    char c = str[i];
    while (c != 0) {
        dbg_putc(c);
        i++;
        c = str[i];
    }
}


//==================================================
// End
//==================================================
