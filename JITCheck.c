#include "JITCheck.h"
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <libkern/OSCacheControl.h>
#include <sys/mman.h>
#include <sys/sysctl.h>
#include <sys/proc.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

// universal.js implements these calls. The script must still be attached;
// JITCheckRun verifies both CS_DEBUGGED and P_TRACED before reaching them.
__attribute__((noinline, optnone, naked))
static void *JIT26PrepareRegion(void *address, size_t length) {
    __asm__("mov x16, #1\n"
            "brk #0xf00d\n"
            "ret\n");
}

__attribute__((noinline, optnone, naked))
static void JIT26Detach(void) {
    __asm__("mov x16, #0\n"
            "brk #0xf00d\n"
            "ret\n");
}

static int debugged(void) {
    struct csops_flags { uint32_t flags; } flags = {0};
    extern int csops(pid_t, unsigned int, void *, size_t);
    if (csops(getpid(), 0, &flags, sizeof(flags)) != 0) return 0;
    return (flags.flags & 0x10000000u) != 0; // CS_DEBUGGED
}

static int hasLiveTracer(void) {
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid() };
    struct kinfo_proc info;
    size_t infoSize = sizeof(info);
    memset(&info, 0, sizeof(info));
    if (sysctl(mib, 4, &info, &infoSize, NULL, 0) != 0) return 0;
    return (info.kp_proc.p_flag & P_TRACED) != 0;
}

static int debuggerReady(void) {
    return debugged() && hasLiveTracer();
}

int32_t JITCheckRun(void) {
#if !defined(__arm64__)
    return -1;
#else
    // LiveContainer may attach after process launch. CS_DEBUGGED can remain
    // set after detach, so require a live ptrace tracer as well.
    for (unsigned int attempt = 0; attempt < 50 && !debuggerReady(); ++attempt) {
        usleep(100000);
    }
    if (!debuggerReady()) return -2;

    const vm_size_t pageSize = (vm_size_t)getpagesize();

    // Ask universal.js/debugserver to create and bless an RX page. Passing a
    // null address is part of the universal protocol: x0 receives the page.
    void *rxPage = JIT26PrepareRegion(NULL, (size_t)pageSize);
    if (rxPage == NULL || rxPage == (void *)-1) return -4;

    // Create a separate writable alias for code emission, preserving W^X.
    vm_address_t rwAddress = 0;
    vm_prot_t currentProtection = VM_PROT_NONE;
    vm_prot_t maximumProtection = VM_PROT_NONE;
    kern_return_t remapResult = vm_remap(
        mach_task_self(), &rwAddress, pageSize, 0, VM_FLAGS_ANYWHERE,
        mach_task_self(), (vm_address_t)rxPage, FALSE,
        &currentProtection, &maximumProtection, VM_INHERIT_NONE);
    if (remapResult != KERN_SUCCESS) {
        vm_deallocate(mach_task_self(), (vm_address_t)rxPage, pageSize);
        return -3;
    }

    kern_return_t protectResult = vm_protect(
        mach_task_self(), rwAddress, pageSize, FALSE,
        VM_PROT_READ | VM_PROT_WRITE);
    if (protectResult != KERN_SUCCESS) {
        vm_deallocate(mach_task_self(), rwAddress, pageSize);
        vm_deallocate(mach_task_self(), (vm_address_t)rxPage, pageSize);
        return -3;
    }

    // ARM64: mov w0, #42; ret
    const uint32_t code[] = { 0x52800540u, 0xD65F03C0u };
    memcpy((void *)rwAddress, code, sizeof(code));
    sys_icache_invalidate(rxPage, sizeof(code));

    // The script's documented order is prepare regions, then detach, then run.
    if (!debuggerReady()) {
        vm_deallocate(mach_task_self(), rwAddress, pageSize);
        vm_deallocate(mach_task_self(), (vm_address_t)rxPage, pageSize);
        return -5;
    }
    JIT26Detach();

    int (*run)(void) = (int (*)(void))rxPage;
    int result = run();
    vm_deallocate(mach_task_self(), rwAddress, pageSize);
    vm_deallocate(mach_task_self(), (vm_address_t)rxPage, pageSize);
    return result;
#endif
}
