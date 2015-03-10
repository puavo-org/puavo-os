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

/* Third-party includes. */
#include <jansson.h>

/* Local includes. */
#include "orgjson.h"

static const char ORGJSON_PATH[] = "/etc/puavo/org.json";

struct orgjson {
        json_t *root;
        json_t *owners;
};

struct orgjson *orgjson_load2(const char *const filepath,
                              struct orgjson_error *const error)
{
        struct orgjson *orgjson;
        json_error_t json_error;

        orgjson = malloc(sizeof(struct orgjson));
        if (!orgjson) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_SYS;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "malloc failed: %m");
                }
                return NULL;
        }

        orgjson->root = json_load_file(filepath, 0, &json_error);
        if (!orgjson->root) {
                free(orgjson);
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "failed to load %s: %s",
                                 filepath, json_error.text);
                }
                return NULL;
        }

        orgjson->owners = json_object_get(orgjson->root, "owners");
        if (!json_is_array(orgjson->owners)) {
                json_decref(orgjson->root);
                free(orgjson);
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owners field is missing or is not an array");
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

        if (orgjson->root)
                json_decref(orgjson->root);

        free(orgjson);
}

struct orgjson_owner *orgjson_get_owner(const struct orgjson *const orgjson,
                                        const size_t i,
                                        struct orgjson_owner *const owner,
                                        struct orgjson_error *const error)
{
        json_t *user;
        json_t *username;
        json_t *uid_number;
        json_t *gid_number;
        json_t *first_name;
        json_t *last_name;
        json_t *ssh_public_key;

        user = json_array_get(orgjson->owners, i);
        if (!user) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owners array does not have item at i=%zd", i);
                }
                return NULL;
        }

        username = json_object_get(user, "username");
        if (!username || !json_is_string(username)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) has invalid or missing username",
                                 i);

                }
                return NULL;
        }

        uid_number = json_object_get(user, "uid_number");
        if (!uid_number || !json_is_integer(uid_number)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) has invalid or missing uid_number",
                                 i);
                }
                return NULL;
        }

        gid_number = json_object_get(user, "gid_number");
        if (!gid_number || !json_is_integer(gid_number)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) has invalid or missing gid_number",
                                 i);
                }
                return NULL;
        }

        first_name = json_object_get(user, "first_name");
        if (!first_name || !json_is_string(first_name)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) has invalid or missing first_name",
                                 i);
                }
                return NULL;
        }

        last_name = json_object_get(user, "last_name");
        if (!last_name || !json_is_string(last_name)) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) has invalid or missing last_name",
                                 i);
                }
                return NULL;
        }

        ssh_public_key = json_object_get(user, "ssh_public_key");
        if (!ssh_public_key ||
            (!json_is_string(ssh_public_key) && !json_is_null(ssh_public_key))) {
                if (error) {
                        error->code = ORGJSON_ERROR_CODE_JSON;
                        snprintf(error->text, ORGJSON_ERROR_TEXT_SIZE,
                                 "owner (i=%zd) has invalid or missing "
                                 "ssh_public_key", i);
                }
                return NULL;
        }

        owner->username = json_string_value(username);
        owner->uid_number = json_integer_value(uid_number);
        owner->gid_number = json_integer_value(gid_number);
        owner->first_name = json_string_value(first_name);
        owner->last_name = json_string_value(last_name);
        owner->ssh_public_key = json_string_value(ssh_public_key);

        return owner;
}

size_t orgjson_get_owner_count(const struct orgjson *const orgjson)
{
        return json_array_size(orgjson->owners);
}

int orgjson_exists()
{
        return access(ORGJSON_PATH, F_OK) == 0;
}
