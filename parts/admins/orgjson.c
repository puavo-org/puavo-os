// Standard library includes.
#include <stdlib.h>

#include "orgjson.h"

orgjson_t *orgjson_load(void)
{
    orgjson_t *orgjson;

    orgjson = malloc(sizeof(orgjson_t));
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

void orgjson_free(orgjson_t *const orgjson)
{
    if (!orgjson)
        return;

    if (orgjson->root)
        json_decref(orgjson->root);

    free(orgjson);
}
