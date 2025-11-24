#ifndef BUNDLE_REPLAY_H
#define BUNDLE_REPLAY_H

#include <stdint.h>
#include <stddef.h>

/* Initialize bundles from JSON file.
 */
int bundles_init(const char *path, uintptr_t addr_base);

/* Free internal structures */
void bundles_free(void);

/* Trigger prefetch for the bundle that contains `pc`.
 */
int bundles_prefetch_for_pc(uintptr_t pc, int use_madvise, int do_prefetch_lines);

/* A small helper that prints loaded bundles (for debug) */
void bundles_print_stats(void);

#endif 

