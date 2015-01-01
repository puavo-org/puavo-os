// Standard library includes.
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <nss.h>
#include <pwd.h>
#include <grp.h>
#include <sys/types.h>

#include "log.h"
#include "orgjson.h"

static size_t g_ent_index;
static orgjson_t *g_orgjson;

static enum nss_status populate_passwd(struct orgjson_owner *owner,
                                       struct passwd *const pw,
                                       char *const buf,
                                       const size_t buflen,
                                       int *const errnop) {
    static const char *const ADM_HOME_PATH = "/adm-home/";
    size_t username_size;
    size_t gecos_size;
    size_t home_size;

    username_size = strlen(owner->username) + 1;
    gecos_size = strlen(owner->first_name) + 1
        + strlen(owner->last_name) + 1;
    home_size = strlen(ADM_HOME_PATH)
            + strlen(owner->username) + 1;

    if ((username_size + gecos_size + home_size) > buflen) {
        *errnop = ERANGE;
        return NSS_STATUS_TRYAGAIN;
    }

    snprintf(buf, username_size, "%s", owner->username);
    snprintf(buf + username_size, gecos_size, "%s %s",
             owner->first_name, owner->last_name);
    snprintf(buf + username_size + gecos_size, home_size, "%s%s",
             ADM_HOME_PATH, owner->username);

    pw->pw_name = buf;
    pw->pw_uid = owner->uid_number;
    pw->pw_gid = owner->gid_number;
    pw->pw_passwd = "x";
    pw->pw_gecos = buf + username_size;
    pw->pw_dir = buf + username_size + gecos_size;
    pw->pw_shell = "/bin/bash";

    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_getpwuid_r(const uid_t uid,
                                            struct passwd *const result,
                                            char *const buf,
                                            const size_t buflen,
                                            int *const errnop) {
    orgjson_t *orgjson;
    enum nss_status retval = NSS_STATUS_NOTFOUND;
    struct orgjson_error error;

    orgjson = orgjson_load(&error);
    if (!orgjson) {
        log(LOG_ERR, "failed to get puavoadmins passwd entry by uid %d: %s",
            uid, error.text);
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    for (size_t i = 0; i < orgjson_get_owner_count(orgjson); ++i) {
        struct orgjson_owner owner;

        if (!orgjson_get_owner(orgjson, i, &owner, &error)) {
            log(LOG_ERR, "failed to get puavoadmins passwd entry by uid %d: %s",
                uid, error.text);
            retval = NSS_STATUS_UNAVAIL;
            break;
        }

        if (owner.uid_number != uid)
            continue;

        retval = populate_passwd(&owner, result, buf, buflen, errnop);
        break;
    }

    orgjson_free(orgjson);
    orgjson = NULL;

    return retval;
}

enum nss_status _nss_puavoadmins_getpwnam_r(const char *const name,
                                            struct passwd *const result,
                                            char *const buf,
                                            const size_t buflen,
                                            int *const errnop) {
    orgjson_t *orgjson;
    enum nss_status retval = NSS_STATUS_NOTFOUND;
    struct orgjson_error error;

    orgjson = orgjson_load(&error);
    if (!orgjson) {
        log(LOG_ERR, "failed to get puavoadmins passwd entry by name '%s': %s",
            name, error.text);
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    for (size_t i = 0; i < orgjson_get_owner_count(orgjson); ++i) {
        struct orgjson_owner owner;

        if (!orgjson_get_owner(orgjson, i, &owner, &error)) {
            log(LOG_ERR, "failed to get puavoadmins passwd entry by name '%s': %s",
                name, error.text);
            retval = NSS_STATUS_UNAVAIL;
            break;
        }

        if (strcmp(name, owner.username))
            continue;

        retval = populate_passwd(&owner, result, buf, buflen, errnop);
        break;
    }

    orgjson_free(orgjson);
    orgjson = NULL;

    return retval;
}

enum nss_status _nss_puavoadmins_setpwent(void) {
    g_ent_index = 0;
    struct orgjson_error error;

    g_orgjson = orgjson_load(&error);
    if (!g_orgjson) {
        log(LOG_ERR, "failed to rewind to the first puavoadmins passwd entry: %s",
            error.text);
        return NSS_STATUS_UNAVAIL;
    }

    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_endpwent(void) {
    orgjson_free(g_orgjson);
    g_orgjson = NULL;

    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_getpwent_r(struct passwd *const pw,
                                            char *const buf,
                                            const size_t buflen,
                                            int *const errnop) {
    enum nss_status ret;

    *errnop = 0;

    if (!pw) {
        return NSS_STATUS_UNAVAIL;
    }

    while (g_ent_index < orgjson_get_owner_count(g_orgjson)) {
        struct orgjson_owner owner;
        struct orgjson_error error;

        if (!orgjson_get_owner(g_orgjson, g_ent_index++, &owner, &error)) {
            log(LOG_ERR, "failed to get next puavoadmins passwd entry: %s",
                error.text);
            continue;
        }

        ret = populate_passwd(&owner, pw, buf, buflen, errnop);

        if (ret == NSS_STATUS_UNAVAIL)
            continue;

        return ret;
    }

    return NSS_STATUS_NOTFOUND;
}
