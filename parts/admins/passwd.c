// Standard library includes.
#include <errno.h>
#include <string.h>
#include <nss.h>
#include <pwd.h>
#include <grp.h>
#include <sys/types.h>

#include "ctx.h"

enum nss_status _nss_puavoadmins_getpwuid_r(uid_t,
                                            struct passwd *,
                                            char *,
                                            size_t,
                                            int *);
enum nss_status _nss_puavoadmins_setpwent(void);
enum nss_status _nss_puavoadmins_endpwent(void);
enum nss_status _nss_puavoadmins_getpwnam_r(const char *,
                                            struct passwd *,
                                            char *,
                                            size_t, int *);
enum nss_status _nss_puavoadmins_getpwent_r(struct passwd *,
                                            char *,
                                            size_t, int *);

static size_t g_ent_index;
static struct ctx *g_ctx;

static enum nss_status populate_passwd(json_t *const user,
                                       struct passwd *const pw,
                                       char *const buf,
                                       const size_t buflen) {
    static const char *const ADM_HOME_PATH = "/adm-home/";
    json_t *username;
    json_t *uid_number;
    json_t *gid_number;
    json_t *first_name;
    json_t *last_name;
    size_t username_size;
    size_t gecos_size;
    size_t home_size;

    username = json_object_get(user, "username");
    uid_number = json_object_get(user, "uid_number");
    gid_number = json_object_get(user, "gid_number");
    first_name = json_object_get(user, "first_name");
    last_name = json_object_get(user, "last_name");

    if (!json_is_string(username)) {
//        fprintf(stderr, "error: username is not a string\n");
        return NSS_STATUS_UNAVAIL;
    }

    if (!json_is_integer(uid_number)) {
//        fprintf(stderr, "error: uid_number is not an integer\n");
        return NSS_STATUS_UNAVAIL;
    }

    if (!json_is_integer(gid_number)) {
//        fprintf(stderr, "error: gid_number is not an integer\n");
        return NSS_STATUS_UNAVAIL;
    }

    if (!json_is_string(first_name)) {
//        fprintf(stderr, "error: first_name is not a string\n");
        return NSS_STATUS_UNAVAIL;
    }

    if (!json_is_string(last_name)) {
//        fprintf(stderr, "error: last_name is not a string\n");
        return NSS_STATUS_UNAVAIL;
    }

    username_size = strlen(json_string_value(username)) + 1;
    gecos_size = strlen(json_string_value(first_name)) + 1
            + strlen(json_string_value(last_name)) + 1;
    home_size = strlen(ADM_HOME_PATH)
            + strlen(json_string_value(username)) + 1;

    if ((username_size + gecos_size + home_size) > buflen)
        return NSS_STATUS_TRYAGAIN;

    snprintf(buf, username_size, "%s", json_string_value(username));
    snprintf(buf + username_size, gecos_size, "%s %s",
             json_string_value(first_name),
             json_string_value(last_name));
    snprintf(buf + username_size + gecos_size, home_size, "%s%s",
             ADM_HOME_PATH, json_string_value(username));

    pw->pw_name = buf;
    pw->pw_uid = json_integer_value(uid_number);
    pw->pw_gid = json_integer_value(gid_number);
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
    struct ctx *ctx;
    enum nss_status retval = NSS_STATUS_NOTFOUND;

    ctx = init_ctx();
    if (!ctx) {
        *errnop = errno;
        return NSS_STATUS_UNAVAIL;
    }

    for (size_t i = 0; i < json_array_size(ctx->json_owners); ++i) {
	json_t *user;
	json_t *uid_number;

        user = json_array_get(ctx->json_owners, i);

        uid_number = json_object_get(user, "uid_number");

        if (json_integer_value(uid_number) != uid)
            continue;

        retval = populate_passwd(user, result, buf, buflen);
        break;
    }

    free_ctx(ctx);
    ctx = NULL;

    return retval;
}

enum nss_status _nss_puavoadmins_getpwnam_r(const char *const name,
                                            struct passwd *const result,
                                            char *const buf,
                                            const size_t buflen,
                                            int *const errnop) {
    struct ctx *ctx;
    enum nss_status retval = NSS_STATUS_NOTFOUND;

    ctx = init_ctx();
    if (!ctx) {
	*errnop = errno;
	return NSS_STATUS_UNAVAIL;
    }

    for (size_t i = 0; i < json_array_size(ctx->json_owners); ++i) {
	json_t *user;
	json_t *username;

        user = json_array_get(ctx->json_owners, i);

        username = json_object_get(user, "username");

        if (strcmp(name, json_string_value(username)))
            continue;

        retval = populate_passwd(user, result, buf, buflen);
	break;
    }

    free_ctx(ctx);
    ctx = NULL;

    return retval;
}

enum nss_status _nss_puavoadmins_setpwent(void) {
    g_ent_index = 0;

    g_ctx = init_ctx();
    if (!g_ctx)
	return NSS_STATUS_UNAVAIL;

    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_endpwent(void) {
    free_ctx(g_ctx);
    g_ctx = NULL;

    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_getpwent_r(struct passwd *const pw,
                                            char *const buf,
                                            const size_t buflen,
                                            int *const errnop) {
    json_t *user;
    enum nss_status ret;

    *errnop = 0;

    if (!pw) {
        return NSS_STATUS_UNAVAIL;
    }

    while (g_ent_index < json_array_size(g_ctx->json_owners)) {
        user = json_array_get(g_ctx->json_owners, g_ent_index);
        g_ent_index++;

        ret = populate_passwd(user, pw, buf, buflen);

        if (ret == NSS_STATUS_UNAVAIL)
            continue;

        return ret;
    }

    return NSS_STATUS_NOTFOUND;
}
