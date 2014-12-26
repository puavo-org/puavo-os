#ifndef ORGJSON_H
#define ORGJSON_H

#include <jansson.h>

struct orgjson {
    json_t *root;
    json_t *owners;
};

typedef struct orgjson orgjson_t;

orgjson_t *orgjson_load(void);
void orgjson_free(orgjson_t *const orgjson);

#endif // ORGJSON_H
