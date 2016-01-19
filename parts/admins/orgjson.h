/* puavoadmins
 * Copyright (C) 2014, 2015 Opinsys
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef ORGJSON_H
#define ORGJSON_H

/* Standard library includes. */
#include <sys/types.h>

#define ORGJSON_ERROR_TEXT_SIZE 240

struct orgjson_error {
        enum {
                ORGJSON_ERROR_CODE_SYS=1,
                ORGJSON_ERROR_CODE_JSON,
        } code;
        char text[ORGJSON_ERROR_TEXT_SIZE];
};

struct orgjson_owner {
        const char *username;
        const char *first_name;
        const char *last_name;
        const char *ssh_public_key;
        uid_t uid_number;
        gid_t gid_number;
};

/* Opaque type representing parsed /etc/puavo/org.json. */
typedef struct orgjson orgjson_t;

orgjson_t *orgjson_load(struct orgjson_error *error);
orgjson_t *orgjson_load2(const char *filepath, struct orgjson_error *error);
void orgjson_free(orgjson_t *orgjson);

struct orgjson_owner *orgjson_get_owner(const orgjson_t *orgjson,
                                        const size_t i,
                                        struct orgjson_owner *owner,
                                        struct orgjson_error *error);
size_t orgjson_get_owner_count(const orgjson_t *orgjson);

int orgjson_exists();

#endif /* ORGJSON_H */
