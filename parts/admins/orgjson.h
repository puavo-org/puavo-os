#ifndef ORGJSON_H
#define ORGJSON_H

#include <sys/types.h>

#define ORGJSON_ERROR_TEXT_LEN 240

struct orgjson_error {
    enum {
      ORGJSON_ERROR_CODE_SYS=1,
      ORGJSON_ERROR_CODE_JSON,
    } code;
    char text[ORGJSON_ERROR_TEXT_LEN];
};

struct orgjson_owner {
    const char *username;
    const char *first_name;
    const char *last_name;
    uid_t uid_number;
    gid_t gid_number;
};

// Opaque type representing parsed /etc/puavo/org.json.
typedef struct orgjson orgjson_t;

orgjson_t *orgjson_load(struct orgjson_error *error);
void orgjson_free(orgjson_t *orgjson);

struct orgjson_owner *orgjson_get_owner(const orgjson_t *orgjson,
                                        const size_t i,
                                        struct orgjson_owner *owner,
                                        struct orgjson_error *error);
size_t orgjson_get_owner_count(const orgjson_t *orgjson);

#endif // ORGJSON_H
