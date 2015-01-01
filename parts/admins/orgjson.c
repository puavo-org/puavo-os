// Standard library includes.
#include <stdlib.h>

#include <jansson.h>

#include "orgjson.h"

static const char ORGJSON_PATH[] = "/etc/puavo/org.json";

struct orgjson {
    json_t *root;
    json_t *owners;
};

struct orgjson *orgjson_load(struct orgjson_error *const error)
{
    struct orgjson *orgjson;
    json_error_t json_error;

    orgjson = malloc(sizeof(struct orgjson));
    if (!orgjson) {
        if (error) {
            error->code = ORGJSON_ERROR_CODE_SYS;
            snprintf(error->text, ORGJSON_ERROR_TEXT_LEN, "malloc failed: %m");
        }
        return NULL;
    }

    orgjson->root = json_load_file(ORGJSON_PATH, 0, &json_error);
    if (!orgjson->root) {
        free(orgjson);
        if (error) {
            error->code = ORGJSON_ERROR_CODE_JSON;
            snprintf(error->text, ORGJSON_ERROR_TEXT_LEN,
                     "failed to load %s: %s", ORGJSON_PATH, json_error.text);
        }
        return NULL;
    }

    orgjson->owners = json_object_get(orgjson->root, "owners");
    if (!json_is_array(orgjson->owners)) {
        json_decref(orgjson->root);
        free(orgjson);
        if (error) {
            error->code = ORGJSON_ERROR_CODE_JSON;
            snprintf(error->text, ORGJSON_ERROR_TEXT_LEN,
                     "owners field is missing or is not an array");
        }
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

    user = json_array_get(orgjson->owners, i);
    if (!user) {
        if (error) {
            error->code = ORGJSON_ERROR_CODE_JSON;
            snprintf(error->text, ORGJSON_ERROR_TEXT_LEN,
                     "owners array does not have item at i=%ld", i);
        }
        return NULL;
    }

    username = json_object_get(user, "username");
    if (!username || !json_is_string(username)) {
        if (error) {
            error->code = ORGJSON_ERROR_CODE_JSON;
            snprintf(error->text, ORGJSON_ERROR_TEXT_LEN,
                     "owner (i=%ld) has invalid or missing username", i);

        }
        return NULL;
    }

    uid_number = json_object_get(user, "uid_number");
    if (!uid_number || !json_is_integer(uid_number)) {
        if (error) {
            error->code = ORGJSON_ERROR_CODE_JSON;
            snprintf(error->text, ORGJSON_ERROR_TEXT_LEN,
                     "owner (i=%ld) has invalid or missing uid_number", i);
        }
        return NULL;
    }

    gid_number = json_object_get(user, "gid_number");
    if (!gid_number || !json_is_integer(gid_number)) {
        if (error) {
            error->code = ORGJSON_ERROR_CODE_JSON;
            snprintf(error->text, ORGJSON_ERROR_TEXT_LEN,
                     "owner (i=%ld) has invalid or missing gid_number", i);
        }
        return NULL;
    }

    first_name = json_object_get(user, "first_name");
    if (!first_name || !json_is_string(first_name)) {
        if (error) {
            error->code = ORGJSON_ERROR_CODE_JSON;
            snprintf(error->text, ORGJSON_ERROR_TEXT_LEN,
                     "owner (i=%ld) has invalid or missing first_name", i);
        }
        return NULL;
    }

    last_name = json_object_get(user, "last_name");
    if (!last_name || !json_is_string(last_name)) {
        if (error) {
            error->code = ORGJSON_ERROR_CODE_JSON;
            snprintf(error->text, ORGJSON_ERROR_TEXT_LEN,
                     "owner (i=%ld) has invalid or missing last_name", i);
        }
        return NULL;
    }

    owner->username = json_string_value(username);
    owner->uid_number = json_integer_value(uid_number);
    owner->gid_number = json_integer_value(gid_number);
    owner->first_name = json_string_value(first_name);
    owner->last_name = json_string_value(last_name);

    return owner;
}

size_t orgjson_get_owner_count(const struct orgjson *const orgjson)
{
    return json_array_size(orgjson->owners);
}
