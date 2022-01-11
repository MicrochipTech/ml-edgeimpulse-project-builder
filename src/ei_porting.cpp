#include <cstdlib>
#include <cstdio>
#include <cstdarg>
#include "edge-impulse-sdk/porting/ei_classifier_porting.h"

void *ei_malloc(size_t size) {
    return malloc(size);
}

void *ei_calloc(size_t nitems, size_t size) {
    return calloc(nitems, size);
}

void ei_free(void *ptr) {
    free(ptr);
}

EI_IMPULSE_ERROR ei_run_impulse_check_canceled() {
    return EI_IMPULSE_OK;
}

void ei_printf(const char *format, ...) {
    va_list myargs;
    va_start(myargs, format);
    vprintf(format, myargs);
    va_end(myargs);
}

void DebugLog(const char* s) {
    ei_printf("%s", s);
}

void ei_printf_float(float f) {
    ei_printf("%f", f);
}

extern "C" int _open (const char *buf, int flags, int mode)
{
    return 0;
}