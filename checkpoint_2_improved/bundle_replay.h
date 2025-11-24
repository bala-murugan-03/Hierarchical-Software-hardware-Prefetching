#ifndef BUNDLE_REPLAY_H
#define BUNDLE_REPLAY_H

#include <stdint.h>
#include <stddef.h>

/* Initialize bundles from JSON file.
 * path: path to bundle_addr_pcs.json
 * addr_base: add this base to all parsed start/end PCs (use 0 if JSON contains full virtual addresses).
 * Returns 0 on success, -1 on error.
 */
int bundles_init(const char *path, uintptr_t addr_base);

/* Free internal structures */
void bundles_free(void);

/* Trigger prefetch for the bundle that contains `pc`.
 * - pc: a PC address (use (uintptr_t)__builtin_return_address(0) or a persistent function pointer address)
 * - use_madvise: if non-zero, call madvise(MADV_WILLNEED) on pages
 * - do_prefetch_lines: if non-zero, do a few __builtin_prefetch on addresses inside the range
 *
 * Returns 1 if a matching bundle was found and prefetch attempted, 0 if no matching bundle.
 */
int bundles_prefetch_for_pc(uintptr_t pc, int use_madvise, int do_prefetch_lines);

/* A small helper that prints loaded bundles (for debug) */
void bundles_print_stats(void);

#endif /* BUNDLE_REPLAY_H */

