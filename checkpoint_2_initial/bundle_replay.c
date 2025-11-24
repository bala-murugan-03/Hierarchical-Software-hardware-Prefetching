#define _GNU_SOURCE
#include "bundle_replay.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <sys/mman.h>
#include <unistd.h>

#define MAX_BUNDLES 1024
#define MAX_NAME 256

typedef struct {
    char name[MAX_NAME];
    uint64_t start;
    uint64_t end;
} bundle_t;

static bundle_t bundles[MAX_BUNDLES];
static int bundle_count = 0;

static uint64_t hex_to_u64(const char *s) {
    // Handles "0x..." or plain hex/decimal strings
    return strtoull(s, NULL, 0);
}

void load_bundles_json(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) {
        fprintf(stderr, "bundle_replay: cannot open %s\n", path);
        return;
    }
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *buf = malloc(len + 1);
    if (!buf) { fclose(f); return; }
    fread(buf, 1, len, f);
    buf[len] = '\0';
    fclose(f);

    const char *p = buf;
    bundle_count = 0;
    while ((p = strstr(p, "\"function\"")) != NULL && bundle_count < MAX_BUNDLES) {
        // find function name
        const char *colon = strchr(p, ':');
        if (!colon) break;
        const char *q = strchr(colon, '\"');
        if (!q) break;
        q++;
        const char *r = strchr(q, '\"');
        if (!r) break;
        int n = (int)(r - q);
        if (n >= MAX_NAME) n = MAX_NAME - 1;
        strncpy(bundles[bundle_count].name, q, n);
        bundles[bundle_count].name[n] = '\0';

        // find start_pc after r
        uint64_t startv = 0, endv = 0;
        const char *start_key = strstr(r, "\"start_pc\"");
        if (start_key) {
            const char *s = strchr(start_key, ':');
            if (s) {
                const char *sq = strchr(s, '\"');
                if (sq) {
                    sq++;
                    const char *se = strchr(sq, '\"');
                    if (se) {
                        char tmp[64]; int tlen = (int)(se - sq);
                        if (tlen >= (int)sizeof(tmp)) tlen = (int)sizeof(tmp)-1;
                        strncpy(tmp, sq, tlen); tmp[tlen] = '\0';
                        startv = hex_to_u64(tmp);
                    }
                } else {
                    // number without quotes
                    s++;
                    char tmp[64]; int t=0;
                    while (*s && t < 63 && ( (*s>='0'&&*s<='9') || (*s>='a'&&*s<='f') || (*s>='A'&&*s<='F') || *s=='x' )) tmp[t++]=*s++;
                    tmp[t]=0;
                    if (t) startv = hex_to_u64(tmp);
                }
            }
        }

        // find end_pc after r
        const char *end_key = strstr(r, "\"end_pc\"");
        if (end_key) {
            const char *s = strchr(end_key, ':');
            if (s) {
                const char *sq = strchr(s, '\"');
                if (sq) {
                    sq++;
                    const char *se = strchr(sq, '\"');
                    if (se) {
                        char tmp[64]; int tlen = (int)(se - sq);
                        if (tlen >= (int)sizeof(tmp)) tlen = (int)sizeof(tmp)-1;
                        strncpy(tmp, sq, tlen); tmp[tlen] = '\0';
                        endv = hex_to_u64(tmp);
                    }
                } else {
                    s++;
                    char tmp[64]; int t=0;
                    while (*s && t < 63 && ( (*s>='0'&&*s<='9') || (*s>='a'&&*s<='f') || (*s>='A'&&*s<='F') || *s=='x' )) tmp[t++]=*s++;
                    tmp[t]=0;
                    if (t) endv = hex_to_u64(tmp);
                }
            }
        }

        bundles[bundle_count].start = startv;
        bundles[bundle_count].end = endv;
        bundle_count++;
        p = r + 1;
    }

    free(buf);
    fprintf(stderr, "bundle_replay: loaded %d bundles from %s\n", bundle_count, path);
}

// Prefetch implementation: page-level madvise + builtin prefetch for each page
void bundle_prefetch_by_name(const char *fname) {
    for (int i = 0; i < bundle_count; i++) {
        if (strncmp(bundles[i].name, fname, MAX_NAME) == 0) {
            uint64_t s = bundles[i].start;
            uint64_t e = bundles[i].end;
            if (e <= s) return; // nothing to do
            const size_t pagesz = (size_t) sysconf(_SC_PAGESIZE);
            uint64_t page_start = s & ~(pagesz - 1);
            uint64_t total_pages = ((e - page_start) / pagesz) + 1;
            const uint64_t max_pages = 256; // safety cap, tune this if needed
            if (total_pages > max_pages) total_pages = max_pages;
            for (uint64_t pg = 0; pg < total_pages; pg++) {
                void *addr = (void*)(page_start + pg * pagesz);
                // Hint to OS to bring page in. In gem5 SE mode, this will cause page to be mapped/prefaulted.
                madvise(addr, pagesz, MADV_WILLNEED);
                // Also attempt data prefetch (may be no-op)
                __builtin_prefetch(addr, 0, 3);
            }
            return;
        }
    }
    // not found => no-op
}

