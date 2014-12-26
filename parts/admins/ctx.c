// Standard library includes.
#include <stdlib.h>

#include "ctx.h"

struct ctx *init_ctx(void)
{
    struct ctx *ctx;

    ctx = malloc(sizeof(struct ctx));
    if (!ctx)
        return NULL;

    ctx->json_root = json_load_file("/etc/puavo/org.json", 0, NULL);
    if (!ctx->json_root) {
        free(ctx);
        return NULL;
    }

    ctx->json_owners = json_object_get(ctx->json_root, "owners");
    if (!json_is_array(ctx->json_owners)) {
        json_decref(ctx->json_root);
        free(ctx);
        return NULL;
    }

    return ctx;
}

void free_ctx(struct ctx *const ctx)
{
    if (!ctx)
        return;

    if (ctx->json_root)
        json_decref(ctx->json_root);

    free(ctx);
}
