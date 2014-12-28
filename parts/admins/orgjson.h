#ifndef ORGJSON_H
#define ORGJSON_H

#include <sys/types.h>

struct orgjson_owner {
    const char *username;
    const char *first_name;
    const char *last_name;
    uid_t uid_number;
    gid_t gid_number;
};

// Opaque type representing parsed /etc/puavo/org.json.
typedef struct orgjson orgjson_t;

orgjson_t *orgjson_load(void);
void orgjson_free(orgjson_t *const orgjson);

struct orgjson_owner *orgjson_get_owner(const orgjson_t *orgjson, size_t i,
					struct orgjson_owner *owner);
size_t orgjson_get_owner_count(const orgjson_t *orgjson);

#endif // ORGJSON_H
