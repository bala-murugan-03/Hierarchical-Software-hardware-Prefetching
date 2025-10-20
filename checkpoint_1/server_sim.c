/*
 server_sim.c
 Simple server-workload simulator (multi-threaded).
 - Generates synthetic HTTP-like requests.
 - Parses method/path/headers (string parsing).
 - Performs authentication check (string compare).
 - Executes "business logic" (CPU-heavy loops, math).
 - Does an in-memory hash-table "DB" lookup/update.
 - Simulates compression and logging.
 - Sleeps briefly to simulate network send.
 Compile: gcc -O2 -pthread server_sim.c -o server_sim
 Generate LLVM IR: clang -S -emit-llvm server_sim.c -o server_sim.ll
*/

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <pthread.h>
#include <time.h>
#include <unistd.h>

#define WORKER_THREADS 4
#define REQ_QUEUE_SIZE 1024
#define DB_SIZE 4096
#define MAX_HEADERS 16
#define MAX_PATH 256

typedef struct {
    char method[8];
    char path[MAX_PATH];
    char headers[ MAX_HEADERS ][64];
    int header_count;
    int client_id;
} request_t;

typedef struct db_entry {
    uint64_t key;
    int value;
    struct db_entry *next;
} db_entry_t;

static request_t req_queue[REQ_QUEUE_SIZE];
static int q_head = 0, q_tail = 0;
static pthread_mutex_t qlock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t qcond = PTHREAD_COND_INITIALIZER;

/* simple chained hash table for an in-memory DB */
static db_entry_t *db_table[DB_SIZE];
static pthread_mutex_t db_lock = PTHREAD_MUTEX_INITIALIZER;

/* utility random */
static inline uint64_t xorshift64(uint64_t *state) {
    uint64_t x = *state;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    *state = x;
    return x;
}

/* simulate parsing a raw HTTP-like request */
void make_request_text(int id, char *buf, size_t bufsz, uint64_t *rnd) {
    const char *methods[] = {"GET","POST","PUT","DELETE"};
    const char *paths[] = {"/index","/api/item","/api/search","/api/update","/static/img"};
    int m = xorshift64(rnd) % 4;
    int p = xorshift64(rnd) % 5;
    snprintf(buf, bufsz,
        "%s %s HTTP/1.1\r\nHost: example\r\nX-Client: %d\r\nX-Trace: %016lx\r\n\r\n",
        methods[m], paths[p], id, (unsigned long)xorshift64(rnd));
}

/* enqueue request */
void enqueue_request(request_t *r) {
    pthread_mutex_lock(&qlock);
    req_queue[q_tail] = *r;
    q_tail = (q_tail + 1) % REQ_QUEUE_SIZE;
    pthread_cond_signal(&qcond);
    pthread_mutex_unlock(&qlock);
}

/* dequeue request (blocks) */
int dequeue_request(request_t *out) {
    pthread_mutex_lock(&qlock);
    while (q_head == q_tail) {
        pthread_cond_wait(&qcond, &qlock);
    }
    *out = req_queue[q_head];
    q_head = (q_head + 1) % REQ_QUEUE_SIZE;
    pthread_mutex_unlock(&qlock);
    return 0;
}

/* simple parser that fills request_t from text */
void parse_request_text(const char *text, request_t *req) {
    // copy method and path
    const char *p = text;
    // method
    int i=0;
    while (*p && *p!=' ' && i < (int)sizeof(req->method)-1) req->method[i++]=*p++;
    req->method[i]=0;
    if (*p==' ') p++;
    // path
    i=0;
    while (*p && *p!=' ' && i < (int)sizeof(req->path)-1) req->path[i++]=*p++;
    req->path[i]=0;
    // headers
    req->header_count = 0;
    const char *line = strstr(text, "\r\n");
    if (!line) return;
    line += 2; // skip first CRLF after request line
    while (line && *line && *line!='\r' && req->header_count < MAX_HEADERS) {
        const char *next = strstr(line, "\r\n");
        if (!next) break;
        int len = (int)(next-line);
        if (len>0 && len < 64) {
            memcpy(req->headers[req->header_count], line, len);
            req->headers[req->header_count][len]=0;
            req->header_count++;
        }
        line = next + 2;
    }
}

/* business logic: a mixture of integer and float math, loop heavy */
int business_logic_sim(int client_id, const char *path) {
    // mix of control flow and math
    volatile double state = 1.0;
    int iterations = 1000 + (client_id % 500);
    if (strstr(path, "search")) iterations *= 2;
    for (int i=0;i<iterations;i++) {
        state += (i * 0.6180339) / (1 + (i%7));
        if ((i & 0x1FF) == 0) state = state * 1.0000001 + 0.000001;
    }
    // simple decision
    if ((int)state % 2 == 0) return 1; else return 0;
}

/* DB access: simple hashtable lookup and occasional update */
int db_lookup_update(uint64_t key, int do_update) {
    size_t idx = key % DB_SIZE;
    pthread_mutex_lock(&db_lock);
    db_entry_t *e = db_table[idx];
    while (e) {
        if (e->key == key) {
            int v = e->value;
            if (do_update) e->value = v + 1;
            pthread_mutex_unlock(&db_lock);
            return v;
        }
        e = e->next;
    }
    // not found: insert
    e = malloc(sizeof(db_entry_t));
    e->key = key;
    e->value = 1;
    e->next = db_table[idx];
    db_table[idx] = e;
    pthread_mutex_unlock(&db_lock);
    return 1;
}

/* simulate compression by doing some CPU work resembling compression */
size_t fake_compress(const char *in, size_t inlen, char *out, size_t outcap) {
    // produce a pseudo-compressed output length and scramble data
    if (outcap == 0) return 0;
    size_t w = 0;
    for (size_t i=0;i<inlen && w+8 < outcap;i+=8) {
        uint64_t v = 1469598103934665603ULL;
        for (int j=0;j<8 && i+j<inlen;j++) {
            v ^= (uint64_t)(unsigned char)in[i+j];
            v *= 1099511628211ULL;
        }
        // write 8 bytes transformed:
        if (w+8 <= outcap) {
            memcpy(out+w, &v, 8);
            w += 8;
        }
    }
    return w;
}

/* logging (serializes to stdout) */
void server_log(int client_id, const char *path, int status) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    printf("[%ld.%03ld] client=%d path=%s status=%d\n",
           ts.tv_sec, ts.tv_nsec/1000000, client_id, path, status);
}

/* Worker thread */
void *worker_fn(void *arg) {
    (void)arg;
    request_t req;
    char buffer[4096];
    char compbuf[1024];
    while (1) {
        dequeue_request(&req);
        // assemble a textual request to parse (simulate network RX)
        make_request_text(req.client_id, buffer, sizeof(buffer), &((uint64_t){rand()}));
        // parse it
        parse_request_text(buffer, &req);
        // auth check: search header "X-Client: <id>"
        int authorized = 0;
        for (int i=0;i<req.header_count;i++) {
            if (strstr(req.headers[i], "X-Client")) { authorized = 1; break; }
        }
        if (!authorized) {
            server_log(req.client_id, req.path, 401);
            continue;
        }
        // CPU-bound business logic
        int decision = business_logic_sim(req.client_id, req.path);
        // DB lookup/update with a pseudo-key
        uint64_t key = (uint64_t)req.client_id ^ (uint64_t)strlen(req.path);
        int dbv = db_lookup_update(key, decision);
        // fake response generation & compression
        char resp[256];
        int rv = snprintf(resp, sizeof(resp), "OK path=%s dbv=%d d=%d", req.path, dbv, decision);
        size_t clen = fake_compress(resp, (size_t)rv, compbuf, sizeof(compbuf));
        (void)clen; // pretend to send the compressed output
        // simulate network send delay (small)
        usleep(200 + (rand() % 200));
        server_log(req.client_id, req.path, 200);
    }
    return NULL;
}

/* Request generator thread */
void *generator_fn(void *arg) {
    (int)(uintptr_t)arg;
    uint64_t rnd = 88172645463325252ULL + (uintptr_t)arg;
    int client_id = (int)(uintptr_t)arg;
    while (1) {
        request_t r;
        r.client_id = client_id;
        // create dummy request metadata; actual parsing is done later from text
        snprintf(r.method, sizeof(r.method), "GET");
        strncpy(r.path, "/api", sizeof(r.path)-1);
        r.header_count = 0;
        enqueue_request(&r);
        // generate bursty arrivals
        usleep(1000 + (xorshift64(&rnd) % 10000));
    }
    return NULL;
}

/* init DB with some entries */
void db_init() {
    for (int i=0;i<DB_SIZE;i++) db_table[i]=NULL;
    for (int i=0;i<256;i++) {
        db_entry_t *e = malloc(sizeof(db_entry_t));
        e->key = i*7919;
        e->value = i%50;
        e->next = db_table[e->key % DB_SIZE];
        db_table[e->key % DB_SIZE] = e;
    }
}

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    srand(time(NULL));
    db_init();
    pthread_t workers[WORKER_THREADS];
    pthread_t gens[WORKER_THREADS];

    for (int i=0;i<WORKER_THREADS;i++) {
        pthread_create(&workers[i], NULL, worker_fn, NULL);
        pthread_create(&gens[i], NULL, generator_fn, (void*)(uintptr_t)(i+1));
    }

    for (int i=0;i<WORKER_THREADS;i++) {
        pthread_join(gens[i], NULL);
        pthread_join(workers[i], NULL);
    }
    return 0;
}

