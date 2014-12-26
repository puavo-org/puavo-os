#ifndef CTX_H
#define CTX_H

#include <jansson.h>

struct ctx {
    json_t *json_root;
    json_t *json_owners;
};

struct ctx *init_ctx(void);
void free_ctx(struct ctx *const ctx);

#endif // CTX_H
