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

struct orgjson_owner *orgjson_get_owner(const orgjson_t *const orgjson, size_t i,
					struct orgjson_owner *const owner)
{
    json_t *user;
    json_t *username;
    json_t *uid_number;
    json_t *gid_number;
    json_t *first_name;
    json_t *last_name;

    user = json_array_get(orgjson->owners, i);
    if (!user)
	goto err;

    username = json_object_get(user, "username");
    if (!username)
	goto err;

    uid_number = json_object_get(user, "uid_number");
    if (!uid_number)
	goto err;

    gid_number = json_object_get(user, "gid_number");
    if (!gid_number)
	goto err;

    first_name = json_object_get(user, "first_name");
    if (!first_name)
	goto err;

    last_name = json_object_get(user, "last_name");
    if (!last_name)
	goto err;

    if (!json_is_string(username))
        goto err;

    if (!json_is_integer(uid_number))
        goto err;

    if (!json_is_integer(gid_number))
        goto err;

    if (!json_is_string(first_name))
        goto err;

    if (!json_is_string(last_name))
        goto err;

    owner->username = json_string_value(username);
    owner->uid_number = json_integer_value(uid_number);
    owner->gid_number = json_integer_value(gid_number);
    owner->first_name = json_string_value(first_name);
    owner->last_name = json_string_value(last_name);

    return owner;

  err:
    return NULL;
}

size_t orgjson_get_owner_count(const orgjson_t *const orgjson)
{
    return json_array_size(orgjson->owners);
}
