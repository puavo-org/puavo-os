#ifndef ORGJSON_H
#define ORGJSON_H

#include <jansson.h>

struct orgjson {
    json_t *root;
    json_t *owners;
};

struct orgjson *orgjson_load(void);
void orgjson_free(struct orgjson *const orgjson);

#endif // ORGJSON_H
