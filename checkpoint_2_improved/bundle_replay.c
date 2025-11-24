#define _GNU_SOURCE
#include "bundle_replay.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <inttypes.h>

typedef struct {
    uintptr_t start_pc;
    uintptr_t end_pc;
    uintptr_t start_page;
    uintptr_t end_page; /* exclusive: page address after last page */
} bundle_entry_t;

static bundle_entry_t *g_bundles = NULL;
static size_t g_num_bundles = 0;
static size_t g_capacity = 0;
static uintptr_t g_addr_base = 0;
static size_t g_page_size = 4096;

static void page_align_range(uintptr_t s, uintptr_t e, uintptr_t *ps, uintptr_t *pe) {
    uintptr_t page = g_page_size;
    uintptr_t start_page = (s / page) * page;
    /* end_page is exclusive */
    uintptr_t end_page = ((e + page - 1) / page) * page;
    *ps = start_page;
    *pe = end_page;
}

/* Tiny JSON-ish parser: extract numbers after "start_pc" and "end_pc". */
static int parse_bundle_file(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) {
        perror("bundles_init fopen");
        return -1;
    }
    char line[4096];
    uintptr_t cur_start = 0;
    uintptr_t cur_end = 0;
    int have_start = 0;
    while (fgets(line, sizeof(line), f)) {
        char *p = line;
        /* lowercase copy for easier token find */
        for (; *p; ++p) {
            /* no-op */
        }
        /* find "start_pc" or "end_pc" tokens */
        char *spos = strstr(line, "start_pc");
        if (spos) {
            /* find number after ':' */
            char *colon = strchr(spos, ':');
            if (!colon) continue;
            char *num = colon + 1;
            /* skip whitespace */
            while (*num && isspace((unsigned char)*num)) num++;
            /* accept "0x.." or digits; also accept quoted string */
            if (*num == '\"') num++;
            errno = 0;
            uintptr_t val = (uintptr_t)strtoull(num, NULL, 0); /* base 0 allows 0x */
            if (errno) continue;
            cur_start = val + g_addr_base;
            have_start = 1;
            continue;
        }
        char *epos = strstr(line, "end_pc");
        if (epos) {
            char *colon = strchr(epos, ':');
            if (!colon) continue;
            char *num = colon + 1;
            while (*num && isspace((unsigned char)*num)) num++;
            if (*num == '\"') num++;
            errno = 0;
            uintptr_t val = (uintptr_t)strtoull(num, NULL, 0);
            if (errno) continue;
            cur_end = val + g_addr_base;
            if (!have_start) {
                /* malformed ordering; skip */
                continue;
            }
            /* store bundle */
            if (g_num_bundles + 1 > g_capacity) {
                size_t newcap = g_capacity ? g_capacity * 2 : 128;
                bundle_entry_t *tmp = realloc(g_bundles, newcap * sizeof(bundle_entry_t));
                if (!tmp) { fclose(f); return -1; }
                g_bundles = tmp;
                g_capacity = newcap;
            }
            uintptr_t ps, pe;
            page_align_range(cur_start, cur_end, &ps, &pe);
            g_bundles[g_num_bundles].start_pc = cur_start;
            g_bundles[g_num_bundles].end_pc = cur_end;
            g_bundles[g_num_bundles].start_page = ps;
            g_bundles[g_num_bundles].end_page = pe;
            g_num_bundles++;
            /* reset */
            have_start = 0;
            cur_start = cur_end = 0;
            continue;
        }
    }
    fclose(f);
    return 0;
}

int bundles_init(const char *path, uintptr_t addr_base) {
    g_addr_base = addr_base;
    long ps = sysconf(_SC_PAGESIZE);
    if (ps > 0) g_page_size = (size_t)ps;
    g_bundles = NULL;
    g_num_bundles = 0;
    g_capacity = 0;
    if (parse_bundle_file(path) != 0) {
        if (g_bundles) free(g_bundles);
        g_bundles = NULL;
        g_num_bundles = 0;
        return -1;
    }
    return 0;
}

void bundles_free(void) {
    if (g_bundles) free(g_bundles);
    g_bundles = NULL;
    g_num_bundles = 0;
    g_capacity = 0;
}

/* do madvise on pages [start_page, end_page) */
static void madvise_range(uintptr_t start_page, uintptr_t end_page) {
    uintptr_t p;
    for (p = start_page; p < end_page; p += g_page_size) {
        void *addr = (void *)p;
        /* best-effort, ignore errors */
        madvise(addr, g_page_size, MADV_WILLNEED);
    }
}

/* do a few __builtin_prefetch inside the range: sample N addresses equally spaced by cacheline */
static void prefetch_lines_in_range(uintptr_t start, uintptr_t end, int lines) {
    if (end <= start) return;
    size_t range = (size_t)(end - start);
    size_t step = range / (size_t)lines;
    if (step == 0) step = 64; /* fallback */
    for (int i = 0; i < lines; i++) {
        uintptr_t a = start + (size_t)i * step;
        void *p = (void *)a;
        __builtin_prefetch(p, 0, 1);
    }
}

/* find bundle containing pc (linear scan; number of bundles is usually small) */
static ssize_t find_bundle_for_pc(uintptr_t pc) {
    for (size_t i = 0; i < g_num_bundles; ++i) {
        if (pc >= g_bundles[i].start_pc && pc <= g_bundles[i].end_pc) return (ssize_t)i;
    }
    return -1;
}

int bundles_prefetch_for_pc(uintptr_t pc, int use_madvise, int do_prefetch_lines) {
    if (g_num_bundles == 0) return 0;
    ssize_t idx = find_bundle_for_pc(pc);
    if (idx < 0) return 0;
    bundle_entry_t *b = &g_bundles[idx];
    if (use_madvise) {
        madvise_range(b->start_page, b->end_page);
    }
    if (do_prefetch_lines) {
        /* Try prefetching a small number of lines inside the bundle range */
        prefetch_lines_in_range(b->start_pc, b->end_pc, 8);
    }
    return 1;
}

void bundles_print_stats(void) {
    fprintf(stderr, "bundle_replay: loaded %zu bundles (page_size=%zu)\n", g_num_bundles, g_page_size);
    for (size_t i = 0; i < g_num_bundles; ++i) {
        fprintf(stderr, "  %zu: start=0x%lx end=0x%lx pages=[0x%lx-0x%lx)\n",
                i,
                (unsigned long)g_bundles[i].start_pc,
                (unsigned long)g_bundles[i].end_pc,
                (unsigned long)g_bundles[i].start_page,
                (unsigned long)g_bundles[i].end_page);
    }
}

