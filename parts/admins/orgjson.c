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

/* Standard library includes. */
#include <sys/file.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

/* Third-party includes. */
#include <json-c/json.h>

/* Local includes. */
#include "orgjson.h"

static const char ORGJSON_PATH[] = "/etc/puavo/org.json";

struct orgjson {
        struct json_object *root;
        struct json_object *owners;
};

struct orgjson *orgjson_load2(const char *const filepath,
                              struct orgjson_error *const error)
{
        struct orgjson *orgjson;

        orgjson = malloc(sizeof(struct orgjson));
        if (!orgjson) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_SYS;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "malloc failed: %m");
                }
                return NULL;
        }

        orgjson->root = json_object_from_file(filepath);
        if (!orgjson->root) {
                free(orgjson);
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "failed to load %s", filepath);
                }
                return NULL;
        }

        if (!json_object_is_type(orgjson->root, json_type_object)) {
                json_object_put(orgjson->root);
                free(orgjson);
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "root object is not an object");
                }
                return NULL;
        }

        orgjson->owners = json_object_object_get(orgjson->root, "owners");
        if (!orgjson->owners) {
                json_object_put(orgjson->root);
                free(orgjson);
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owners field is missing");
                }
                return NULL;
        }

        if (!json_object_is_type(orgjson->owners, json_type_array)) {
                json_object_put(orgjson->root);
                free(orgjson);
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owners field is not an array");
                }
                return NULL;
        }

        return orgjson;
}

struct orgjson *orgjson_load(struct orgjson_error *const error)
{
        struct orgjson *retval;
        int lockfd;

        lockfd = open("/var/lib/puavoadmins/org.json.lock", O_RDONLY);
        if (lockfd < 0) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_SYS;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "failed to open the lock file: %m");
                }
                return NULL;
        }

        if (flock(lockfd, LOCK_SH)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_SYS;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "failed to obtain a read-lock: %m");
                }
                close(lockfd);
                return NULL;
        }

        retval = orgjson_load2(ORGJSON_PATH, error);

        if (close(lockfd)) {
                if (retval) {
                        orgjson_free(retval);
                }
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_SYS;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "failed to close the lock file: %m");
                }
                return NULL;
        }

        return retval;
}

void orgjson_free(struct orgjson *const orgjson)
{
        if (!orgjson)
                return;

        if (orgjson->root) {
                json_object_put(orgjson->root);
                orgjson->root = NULL;
        }

        free(orgjson);
}

struct orgjson_owner *orgjson_get_owner(const struct orgjson *const orgjson,
                                        const size_t i,
                                        struct orgjson_owner *const owner,
                                        struct orgjson_error *const error)
{
        struct json_object *user;
        struct json_object *username;
        struct json_object *uid_number;
        struct json_object *gid_number;
        struct json_object *first_name;
        struct json_object *last_name;
        struct json_object *ssh_public_key;

        user = json_object_array_get_idx(orgjson->owners, i);
        if (!user) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owners array does not have item at i=%zd", i);
                }
                return NULL;
        }

        if (!json_object_is_type(user, json_type_object)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) is not not an object", i);
                }
                return NULL;
        }

        username = json_object_object_get(user, "username");
        if (!username) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) is missing username", i);

                }
                return NULL;
        }

        if (!json_object_is_type(username, json_type_string)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) username is not not a string", i);
                }
                return NULL;
        }

        uid_number = json_object_object_get(user, "uid_number");
        if (!uid_number) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) is missing uid_number", i);
                }
                return NULL;
        }

        if (!json_object_is_type(uid_number, json_type_int)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) uid_number is not not an integer", i);
                }
                return NULL;
        }

        gid_number = json_object_object_get(user, "gid_number");
        if (!gid_number) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) is missing gid_number", i);
                }
                return NULL;
        }

        if (!json_object_is_type(gid_number, json_type_int)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) gid_number is not not an integer", i);
                }
                return NULL;
        }

        first_name = json_object_object_get(user, "first_name");
        if (!first_name) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) is missing first_name", i);
                }
                return NULL;
        }

        if (!json_object_is_type(first_name, json_type_string)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) first_name is not not a string", i);
                }
                return NULL;
        }

        last_name = json_object_object_get(user, "last_name");
        if (!last_name) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) is missing last_name", i);
                }
                return NULL;
        }

        if (!json_object_is_type(last_name, json_type_string)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) last_name is not not a string", i);
                }
                return NULL;
        }

        ssh_public_key = json_object_object_get(user, "ssh_public_key");
        if (ssh_public_key && !json_object_is_type(ssh_public_key, json_type_string)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) has invalid ssh_public_key", i);
                }
                return NULL;
        }

        owner->username         = json_object_get_string(username);
        owner->uid_number       = json_object_get_int(uid_number);
        owner->gid_number       = json_object_get_int(gid_number);
        owner->first_name       = json_object_get_string(first_name);
        owner->last_name        = json_object_get_string(last_name);
        owner->ssh_public_key   = ssh_public_key ? json_object_get_string(ssh_public_key) : NULL;

        return owner;
}

size_t orgjson_get_owner_count(const struct orgjson *const orgjson)
{
        return json_object_array_length(orgjson->owners);
}

int orgjson_exists()
{
        return access(ORGJSON_PATH, F_OK) == 0;
}
