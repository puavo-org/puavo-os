// Standard library includes.
#include <stdlib.h>

#include "orgjson.h"

struct orgjson *orgjson_load(void)
{
    struct orgjson *orgjson;

    orgjson = malloc(sizeof(struct orgjson));
    if (!orgjson)
        return NULL;

    orgjson->root = json_load_file("/etc/puavo/org.json", 0, NULL);
    if (!orgjson->root) {
        free(orgjson);
        return NULL;
    }

    orgjson->owners = json_object_get(orgjson->root, "owners");
    if (!json_is_array(orgjson->owners)) {
        json_decref(orgjson->root);
        free(orgjson);
        return NULL;
    }

    return orgjson;
}

void orgjson_free(struct orgjson *const orgjson)
{
    if (!orgjson)
        return;

    if (orgjson->root)
        json_decref(orgjson->root);

    free(orgjson);
}
