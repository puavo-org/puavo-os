// Standard library includes.
#include <errno.h>
#include <string.h>
#include <nss.h>
#include <pwd.h>
#include <grp.h>
#include <sys/types.h>

#include "ctx.h"

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

static enum nss_status fill_group_members(json_t *json_owners,
					  struct group *const gr,
					  char *const buffer,
					  const size_t buflen,
					  int *const errnop) {
    json_t *user;
    json_t *username;
    char **members;
    char *member;
    const char *username_str;
    int member_count;
    size_t i;
    int username_len;

    memset(buffer, 0, buflen);
    member_count = json_array_size(json_owners);
    members = (char **)buffer;
    member = buffer + sizeof(char *) * (member_count + 1);

    for (i=0; i < json_array_size(json_owners); ++i) {
        user = json_array_get(json_owners, i);
        username = json_object_get(user, "username");

        if (username && json_is_string(username)) {
            username_str = json_string_value(username);
            username_len = strlen(username_str);

            // If we run out of buffer space, we need to return an error
            if (member+username_len+1 > buffer+buflen)
                return NSS_STATUS_TRYAGAIN;

            strcpy(member, username_str);
            members[i] = member;
            member += username_len + 1;
        }
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
    struct ctx *ctx;

    *errnop = 0;

    if (g_group_called)
        return NSS_STATUS_NOTFOUND;

    ctx = init_ctx();
    if (!ctx) {
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    g_group_called = 1;

    retval = fill_group_members(ctx->json_owners, gr, buffer, buflen, errnop);

    free_ctx(ctx);
    ctx = NULL;

    return retval;
}

enum nss_status _nss_puavoadmins_getgrnam_r(const char *const name,
                                            struct group *const gr,
                                            char *const buffer,
                                            const size_t buflen,
                                            int *const errnop) {
    enum nss_status retval;
    struct ctx *ctx;

    *errnop = 0;

    if (strcmp(name, PUAVOADMINS_GRNAM))
        return NSS_STATUS_NOTFOUND;

    ctx = init_ctx();
    if (!ctx) {
	*errnop = errno;
	return NSS_STATUS_UNAVAIL;
    }

    retval = fill_group_members(ctx->json_owners, gr, buffer, buflen, errnop);

    free_ctx(ctx);
    ctx = NULL;

    return retval;
}

enum nss_status _nss_puavoadmins_getgrgid_r(const gid_t gid,
                                            struct group *const gr,
                                            char *const buffer,
                                            const size_t buflen,
                                            int *const errnop) {
    enum nss_status retval;
    struct ctx *ctx;

    *errnop = 0;

    if (gid != PUAVOADMINS_GRGID)
        return NSS_STATUS_NOTFOUND;

    ctx = init_ctx();
    if (!ctx) {
	*errnop = errno;
	return NSS_STATUS_UNAVAIL;
    }

    retval = fill_group_members(ctx->json_owners, gr, buffer, buflen, errnop);

    free_ctx(ctx);
    ctx = NULL;

    return retval;
}
