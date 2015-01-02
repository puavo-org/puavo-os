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

static enum nss_status populate_passwd(const struct orgjson_owner *const owner,
                                       struct passwd *const pw,
                                       char *const buf,
                                       const size_t bufsize,
                                       int *const errnop) {
    static const char *const ADM_HOME_PATH = "/adm-home/";
    size_t pw_name_size;
    size_t pw_gecos_size;
    size_t pw_dir_size;

    char *pw_name;
    char *pw_gecos;
    char *pw_dir;

    pw_name_size = strlen(owner->username) + 1;
    pw_gecos_size = strlen(owner->first_name) + 1 + strlen(owner->last_name) + 1;
    pw_dir_size = strlen(ADM_HOME_PATH) + strlen(owner->username) + 1;

    if ((pw_name_size + pw_gecos_size + pw_dir_size) > bufsize) {
        *errnop = ERANGE;
        return NSS_STATUS_TRYAGAIN;
    }

    pw_name = buf;
    if (snprintf(pw_name, pw_name_size, "%s", owner->username) < 0) {
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    pw_gecos = pw_name + pw_name_size;
    if (snprintf(pw_gecos, pw_gecos_size, "%s %s",
                 owner->first_name, owner->last_name) < 0) {
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    pw_dir = pw_gecos + pw_gecos_size;
    if (snprintf(pw_dir, pw_dir_size, "%s%s",
                 ADM_HOME_PATH, owner->username) < 0) {
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    pw->pw_name   = pw_name;
    pw->pw_uid    = owner->uid_number;
    pw->pw_gid    = owner->gid_number;
    pw->pw_passwd = "x";
    pw->pw_gecos  = pw_gecos;
    pw->pw_dir    = pw_dir;
    pw->pw_shell  = "/bin/bash";

    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_getpwuid_r(const uid_t uid,
                                            struct passwd *const result,
                                            char *const buf,
                                            const size_t bufsize,
                                            int *const errnop) {
    orgjson_t *orgjson;
    enum nss_status retval;
    struct orgjson_error error;

    orgjson = orgjson_load(&error);
    if (!orgjson) {
        log(LOG_ERR, "failed to load puavoadmins passwd database: %s",
            error.text);
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    for (size_t i = 0; i < orgjson_get_owner_count(orgjson); ++i) {
        struct orgjson_owner owner;

        if (!orgjson_get_owner(orgjson, i, &owner, &error)) {
            log(LOG_ERR, "failed to get puavoadmins passwd entry by uid %d: %s",
                uid, error.text);
            *errnop = EINVAL;
            retval = NSS_STATUS_UNAVAIL;
            goto out;
        }

        if (owner.uid_number != uid)
            continue;

        retval = populate_passwd(&owner, result, buf, bufsize, errnop);
        goto out;
    }

    *errnop = ENOENT;
    retval = NSS_STATUS_NOTFOUND;

 out:

    orgjson_free(orgjson);
    orgjson = NULL;

    return retval;
}

enum nss_status _nss_puavoadmins_getpwnam_r(const char *const name,
                                            struct passwd *const result,
                                            char *const buf,
                                            const size_t bufsize,
                                            int *const errnop) {
    orgjson_t *orgjson;
    enum nss_status retval;
    struct orgjson_error error;

    orgjson = orgjson_load(&error);
    if (!orgjson) {
        log(LOG_ERR, "failed to load puavoadmins passwd database: %s",
            error.text);
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    for (size_t i = 0; i < orgjson_get_owner_count(orgjson); ++i) {
        struct orgjson_owner owner;

        if (!orgjson_get_owner(orgjson, i, &owner, &error)) {
            log(LOG_ERR, "failed to get puavoadmins passwd entry by name '%s': %s",
                name, error.text);
            *errnop = EINVAL;
            retval = NSS_STATUS_UNAVAIL;
            goto out;
        }

        if (strcmp(name, owner.username))
            continue;

        retval = populate_passwd(&owner, result, buf, bufsize, errnop);
        goto out;
    }

    *errnop = ENOENT;
    retval = NSS_STATUS_NOTFOUND;

 out:

    orgjson_free(orgjson);
    orgjson = NULL;

    return retval;
}

static inline int passwd_init(void) {
    struct orgjson_error error;

    g_orgjson = orgjson_load(&error);
    if (!g_orgjson) {
        log(LOG_ERR, "failed to load puavoadmins passwd database: %s",
            error.text);
        return -1;
    }

    return 0;
}

enum nss_status _nss_puavoadmins_setpwent(void) {
    g_ent_index = 0;

    if (!g_orgjson && passwd_init())
        return NSS_STATUS_UNAVAIL;

    return NSS_STATUS_SUCCESS;
}

static inline void passwd_free(void) {
    orgjson_free(g_orgjson);
    g_orgjson = NULL;
}

enum nss_status _nss_puavoadmins_endpwent(void) {
    passwd_free();

    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_getpwent_r(struct passwd *const pw,
                                            char *const buf,
                                            const size_t bufsize,
                                            int *const errnop) {
    /* On the very first run, ensure the database is initialized,
     * because setpwent() might not have been called before. */
    if (!g_ent_index && !g_orgjson && passwd_init()) {
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    while (g_ent_index < orgjson_get_owner_count(g_orgjson)) {
        struct orgjson_owner owner;
        struct orgjson_error error;
        enum nss_status retval;

        if (!orgjson_get_owner(g_orgjson, g_ent_index, &owner, &error)) {
            log(LOG_ERR,
                "failed to get puavoadmins passwd entry by index %ld: %s",
                g_ent_index, error.text);
            *errnop = EINVAL;
            return NSS_STATUS_UNAVAIL;
        }

        retval = populate_passwd(&owner, pw, buf, bufsize, errnop);
        if (retval == NSS_STATUS_SUCCESS) {
            /* We can safely move to the next entry only after the
             * current entry is returned succesfully. */
            ++g_ent_index;
        }

        return retval;
    }

    /* Free all resources after going through all entries. */
    passwd_free();

    *errnop = ENOENT;
    return NSS_STATUS_NOTFOUND;
}
