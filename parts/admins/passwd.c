// Standard library includes.
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <nss.h>
#include <pwd.h>
#include <grp.h>
#include <sys/types.h>

// Third-party includes.
#include <jansson.h>

#define PUAVOADMINS_GRNAM "_puavoadmins"
#define PUAVOADMINS_GRGID 555

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

enum nss_status _nss_puavoadmins_setgrent(void);
enum nss_status _nss_puavoadmins_endgrent(void);
enum nss_status _nss_puavoadmins_getgrent_r(struct group *gr,
                                            char *buffer,
                                            size_t buflen,
                                            int *errnop);
enum nss_status _nss_puavoadmins_getgrnam_r(const char *name,
                                            struct group *gr,
                                            char *buffer,
                                            size_t buflen,
                                            int *errnop);
enum nss_status _nss_puavoadmins_getgrgid_r(const gid_t gid,
                                            struct group *gr,
                                            char *buffer,
                                            size_t buflen,
                                            int *errnop);

static size_t g_ent_index;
static json_t *g_json_root;
static json_t *g_owners;

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

struct ctx {
    json_t *json_root;
    json_t *json_owners;
};

static struct ctx *init_ctx(void)
{
    struct ctx *ctx;

    ctx = malloc(sizeof(struct ctx));
    if (!ctx)
        return NULL;

    ctx->json_root = json_load_file("/etc/puavo/org.json", 0, NULL);
    if (!ctx->json_root) {
        free(ctx);
        return NULL;
    }

    ctx->json_owners = json_object_get(ctx->json_root, "owners");
    if (!json_is_array(ctx->json_owners)) {
        json_decref(ctx->json_root);
        free(ctx);
        return NULL;
    }

    return ctx;
}

static void free_ctx(struct ctx *const ctx)
{
    if (!ctx)
        return;

    if (ctx->json_root)
        json_decref(ctx->json_root);

    free(ctx);
}

static int init_json(void) {
    if (g_json_root) {
      json_decref(g_json_root);
      g_json_root = NULL;
    }

    g_json_root = json_load_file("/etc/puavo/org.json", 0, NULL);

    if (!g_json_root) {
        return -1;
    }

    g_owners = json_object_get(g_json_root, "owners");

    if (!json_is_array(g_owners)) {
       json_decref(g_json_root);
       return -1;
    }

    return 0;
}

static void free_json(void) {
    json_decref(g_json_root);
    g_json_root = NULL;
    g_owners = NULL;
}

enum nss_status _nss_puavoadmins_getpwuid_r(const uid_t uid,
                                            struct passwd *const result,
                                            char *const buf,
                                            const size_t buflen,
                                            int *const errnop) {
    json_t *user;
    json_t *uid_number;

    *errnop = 0;

    if (init_json()) {
	*errnop = errno;
	return NSS_STATUS_UNAVAIL;
    }

    while (g_ent_index < json_array_size(g_owners)) {
        user = json_array_get(g_owners, g_ent_index);
        g_ent_index++;

        uid_number = json_object_get(user, "uid_number");

        if (json_integer_value(uid_number) != uid)
            continue;

        return populate_passwd(user, result, buf, buflen);
    }

    free_json();
}

enum nss_status _nss_puavoadmins_getpwnam_r(const char *const name,
                                            struct passwd *const result,
                                            char *const buf,
                                            const size_t buflen,
                                            int *const errnop) {
    json_t *user;
    json_t *username;

    *errnop = 0;

    if (init_json()) {
	*errnop = errno;
	return NSS_STATUS_UNAVAIL;
    }

    while (g_ent_index < json_array_size(g_owners)) {
        user = json_array_get(g_owners, g_ent_index);
        g_ent_index++;

        username = json_object_get(user, "username");

        if (strcmp(name, json_string_value(username)))
            continue;

        return populate_passwd(user, result, buf, buflen);
    }

    free_json();
}

enum nss_status _nss_puavoadmins_setpwent(void) {
    g_ent_index = 0;

    if (init_json()) {
	return NSS_STATUS_UNAVAIL;
    }

    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_endpwent(void) {
    free_json();

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

    while (g_ent_index < json_array_size(g_owners)) {
        user = json_array_get(g_owners, g_ent_index);
        g_ent_index++;

        ret = populate_passwd(user, pw, buf, buflen);

        if (ret == NSS_STATUS_UNAVAIL)
            continue;

        return ret;
    }

    return NSS_STATUS_NOTFOUND;
}


static int g_group_called = 0;

enum nss_status _nss_puavoadmins_setgrent(void) {
    g_group_called = 0;

    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_endgrent(void) {
    // We always return just one group, so no need to finalise anything

    return NSS_STATUS_SUCCESS;
}

static enum nss_status fill_group_members(struct group *const gr,
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

    if (init_json()) {
	*errnop = errno;
	return NSS_STATUS_UNAVAIL;
    }

    memset(buffer, 0, buflen);
    member_count = json_array_size(g_owners);
    members = (char **)buffer;
    member = buffer + sizeof(char *) * (member_count + 1);

    for (i=0; i < json_array_size(g_owners); i++) {
        user = json_array_get(g_owners, i);
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
    gr->gr_gid = PUAVOADMINS_GRGID;
    gr->gr_mem = members;

    free_json();

    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_getgrent_r(struct group *const gr,
                                            char *const buffer,
                                            const size_t buflen,
                                            int *const errnop) {
    *errnop = 0;

    if (g_group_called)
        return NSS_STATUS_NOTFOUND;

    g_group_called = 1;

    return fill_group_members(gr, buffer, buflen, errnop);
}

enum nss_status _nss_puavoadmins_getgrnam_r(const char *const name,
                                            struct group *const gr,
                                            char *const buffer,
                                            const size_t buflen,
                                            int *const errnop) {
    *errnop = 0;

    if (strcmp(name, PUAVOADMINS_GRNAM))
        return NSS_STATUS_NOTFOUND;

    return fill_group_members(gr, buffer, buflen, errnop);
}

enum nss_status _nss_puavoadmins_getgrgid_r(const gid_t gid,
                                            struct group *const gr,
                                            char *const buffer,
                                            const size_t buflen,
                                            int *const errnop) {
    *errnop = 0;

    if (gid != PUAVOADMINS_GRGID)
        return NSS_STATUS_NOTFOUND;

    return fill_group_members(gr, buffer, buflen, errnop);
}
