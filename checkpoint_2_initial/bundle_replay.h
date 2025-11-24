#ifndef BUNDLE_REPLAY_H
#define BUNDLE_REPLAY_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Load bundles JSON (call once at program start)
void load_bundles_json(const char *path);

// Prefetch pages/lines for a bundle identified by function name
// This is safe to call many times; the implementation caps prefetch size.
void bundle_prefetch_by_name(const char *fname);

#ifdef __cplusplus
}
#endif

#endif // BUNDLE_REPLAY_H

