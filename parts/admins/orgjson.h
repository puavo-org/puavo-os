#ifndef ORGJSON_H
#define ORGJSON_H

#include <sys/types.h>

#include <jansson.h>

struct orgjson_owner {
    const char *username;
    const char *first_name;
    const char *last_name;
    uid_t uid_number;
    gid_t gid_number;
};

struct orgjson {
    json_t *root;
    json_t *owners;
};

typedef struct orgjson orgjson_t;

orgjson_t *orgjson_load(void);
void orgjson_free(orgjson_t *const orgjson);

struct orgjson_owner *orgjson_get_owner(const orgjson_t *orgjson, size_t i,
					struct orgjson_owner *owner);

#endif // ORGJSON_H
