// Standard library includes.
#include <errno.h>
#include <string.h>
#include <nss.h>
#include <pwd.h>
#include <grp.h>
#include <sys/types.h>

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

static enum nss_status fill_group_members(orgjson_t *const orgjson,
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

        if (!orgjson_get_owner(orgjson, i, &owner))
            return NSS_STATUS_UNAVAIL;

        username_len = strlen(owner.username);
        // If we run out of buffer space, we need to return an error
        if (member + username_len > buffer + buflen)
            return NSS_STATUS_TRYAGAIN;

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

    *errnop = 0;

    if (g_group_called)
        return NSS_STATUS_NOTFOUND;

    orgjson = orgjson_load();
    if (!orgjson) {
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    g_group_called = 1;

    retval = fill_group_members(orgjson, gr, buffer, buflen, errnop);

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

    *errnop = 0;

    if (strcmp(name, PUAVOADMINS_GRNAM))
        return NSS_STATUS_NOTFOUND;

    orgjson = orgjson_load();
    if (!orgjson) {
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    retval = fill_group_members(orgjson, gr, buffer, buflen, errnop);

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

    *errnop = 0;

    if (gid != PUAVOADMINS_GRGID)
        return NSS_STATUS_NOTFOUND;

    orgjson = orgjson_load();
    if (!orgjson) {
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    retval = fill_group_members(orgjson, gr, buffer, buflen, errnop);

    orgjson_free(orgjson);
    orgjson = NULL;

    return retval;
}
