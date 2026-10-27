#include "JITCheck.h"
#include <mach/mach.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

// StikDebug universal.js handles these BRK calls. Do not call without the
// debugger script attached: an unhandled BRK terminates the process.
__attribute__((noinline, optnone, naked))
static void *JIT26PrepareRegion(void *address, size_t length) {
    __asm__("mov x16, #1\n"
            "brk #0xf00d\n"
            "ret\n");
}

static int debugged(void) {
    struct csops_flags { uint32_t flags; } flags = {0};
    // csops(CS_OPS_STATUS) returns the task code-signing status.
    extern int csops(pid_t, unsigned int, void *, size_t);
    if (csops(getpid(), 0, &flags, sizeof(flags)) != 0) return 0;
    return (flags.flags & 0x10000000u) != 0; // CS_DEBUGGED
}

int32_t JITCheckRun(void) {
#if !defined(__arm64__)
    return -1;
#else
    if (!debugged()) return -2;

    const size_t pageSize = (size_t)getpagesize();
    void *page = mmap(NULL, pageSize, PROT_READ | PROT_WRITE,
                      MAP_PRIVATE | MAP_ANON, -1, 0);
    if (page == MAP_FAILED) return -3;

    // ARM64: mov w0, #42; ret
    const uint32_t code[] = { 0x52800540u, 0xD65F03C0u };
    memcpy(page, code, sizeof(code));
    sys_icache_invalidate(page, sizeof(code));

    void *execPage = JIT26PrepareRegion(page, pageSize);
    if (!execPage) {
        munmap(page, pageSize);
        return -4;
    }
    int (*run)(void) = (int (*)(void))execPage;
    int result = run();
    munmap(page, pageSize);
    return result;
#endif
}
