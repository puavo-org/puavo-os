// Standard library includes.
#include <errno.h>
#include <string.h>
#include <nss.h>
#include <pwd.h>
#include <grp.h>
#include <sys/types.h>

#include "log.h"
#include "orgjson.h"

#define PUAVOADMINS_GRNAM "_puavoadmins"
#define PUAVOADMINS_GRGID 555

static int g_group_called = 0;

enum nss_status _nss_puavoadmins_setgrent(void) {
    g_group_called = 0;

    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_endgrent(void) {
    // We always return just one group, so no need to finalise anything

    return NSS_STATUS_SUCCESS;
}

static enum nss_status fill_group_members(const orgjson_t *const orgjson,
                                          struct orgjson_error *const error,
                                          struct group *const gr,
                                          char *const buffer,
                                          const size_t buflen,
                                          int *const errnop) {
    char **members;
    char *member;
    size_t member_count;

    memset(buffer, 0, buflen);
    member_count = orgjson_get_owner_count(orgjson);
    members = (char **)buffer;
    member = buffer + sizeof(char *) * (member_count + 1);

    for (size_t i = 0; i < member_count; ++i) {
        struct orgjson_owner owner;
        size_t username_len;

        if (!orgjson_get_owner(orgjson, i, &owner, error))
            return NSS_STATUS_UNAVAIL;

        username_len = strlen(owner.username);
        // If we run out of buffer space, we need to return an error
        if (member + username_len > buffer + buflen) {
            *errnop = ERANGE;
            return NSS_STATUS_TRYAGAIN;
        }

        strcpy(member, owner.username);
        members[i] = member;
        member += username_len + 1;
    }

    gr->gr_name = PUAVOADMINS_GRNAM;
    gr->gr_passwd = "x";
    gr->gr_gid = PUAVOADMINS_GRGID;
    gr->gr_mem = members;

    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_getgrent_r(struct group *const gr,
                                            char *const buffer,
                                            const size_t buflen,
                                            int *const errnop) {
    enum nss_status retval;
    orgjson_t *orgjson;
    struct orgjson_error error;

    if (g_group_called)
        return NSS_STATUS_NOTFOUND;

    orgjson = orgjson_load(&error);
    if (!orgjson) {
        log(LOG_ERR, "failed to get next puavoadmins group entry: %s",
            error.text);
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    g_group_called = 1;

    retval = fill_group_members(orgjson, &error, gr, buffer, buflen, errnop);
    if (retval == NSS_STATUS_UNAVAIL)
        log(LOG_ERR, "failed to get next puavoadmins group entry: %s",
            error.text);

    orgjson_free(orgjson);
    orgjson = NULL;

    return retval;
}

enum nss_status _nss_puavoadmins_getgrnam_r(const char *const name,
                                            struct group *const gr,
                                            char *const buffer,
                                            const size_t buflen,
                                            int *const errnop) {
    enum nss_status retval;
    orgjson_t *orgjson;
    struct orgjson_error error;

    if (strcmp(name, PUAVOADMINS_GRNAM))
        return NSS_STATUS_NOTFOUND;

    orgjson = orgjson_load(&error);
    if (!orgjson) {
        log(LOG_ERR, "failed to get puavoadmins group entry by name '%s': %s",
            name, error.text);
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    retval = fill_group_members(orgjson, &error, gr, buffer, buflen, errnop);
    if (retval == NSS_STATUS_UNAVAIL)
        log(LOG_ERR, "failed to get puavoadmins group entry by name '%s': %s",
            name, error.text);

    orgjson_free(orgjson);
    orgjson = NULL;

    return retval;
}

enum nss_status _nss_puavoadmins_getgrgid_r(const gid_t gid,
                                            struct group *const gr,
                                            char *const buffer,
                                            const size_t buflen,
                                            int *const errnop) {
    enum nss_status retval;
    orgjson_t *orgjson;
    struct orgjson_error error;

    if (gid != PUAVOADMINS_GRGID)
        return NSS_STATUS_NOTFOUND;

    orgjson = orgjson_load(&error);
    if (!orgjson) {
        log(LOG_ERR, "failed to get puavoadmins group entry by gid %d: %s",
            gid, error.text);
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    retval = fill_group_members(orgjson, &error, gr, buffer, buflen, errnop);
    if (retval == NSS_STATUS_UNAVAIL)
        log(LOG_ERR, "failed to get puavoadmins group entry by gid %d: %s",
            gid, error.text);

    orgjson_free(orgjson);
    orgjson = NULL;

    return retval;
}
