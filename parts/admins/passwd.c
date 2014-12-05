#include <stdio.h>
#include <string.h>
#include <nss.h>
#include <pwd.h>
#include <jansson.h>

enum nss_status _nss_puavoadmins_getpwuid_r(uid_t, struct passwd *, char *, size_t, int *);
enum nss_status _nss_puavoadmins_setpwent(void);
enum nss_status _nss_puavoadmins_endpwent(void);
enum nss_status _nss_puavoadmins_getpwnam_r(const char *, struct passwd *, char *, size_t, int *);
enum nss_status _nss_puavoadmins_getpwent_r(struct passwd *, char *, size_t, int *);

static int ent_index;
static json_t *json_root;
static json_t *owners;

static enum nss_status populate_passwd(json_t *user, struct passwd *pw, char *buf, size_t buflen) {
    json_t *username, *uid_number, *gid_number, *first_name, *last_name;
    int username_len, gecos_len, home_len;
    char *gecos, *home;

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

    username_len = strlen(json_string_value(username)) + 1;
    gecos_len = strlen(json_string_value(first_name)) + 1 + strlen(json_string_value(last_name)) + 1;
    home_len = 10 + strlen(json_string_value(username)) + 1;

    if ((username_len + gecos_len + home_len) > buflen)
        return NSS_STATUS_TRYAGAIN;

    snprintf(buf, username_len, "%s", json_string_value(username));
    snprintf(buf+username_len, gecos_len, "%s %s", json_string_value(first_name), json_string_value(last_name));
    snprintf(buf+username_len+gecos_len, home_len, "/adm-home/%s", json_string_value(username));

    pw->pw_name = buf;
    pw->pw_uid = json_integer_value(uid_number);
    pw->pw_gid = json_integer_value(gid_number);
    pw->pw_passwd = "x";
    pw->pw_gecos = buf+username_len;
    pw->pw_dir = buf+username_len+gecos_len;
    pw->pw_shell = "/bin/bash";

    return NSS_STATUS_SUCCESS;
}

static enum nss_status init_json() {
    json_error_t error;

    if (json_root) {
      json_decref(json_root);
      json_root = NULL;
    }

    json_root = json_load_file("/etc/puavo/org.json", 0, &error);

    if (!json_root) {
        return NSS_STATUS_UNAVAIL;
    }

    owners = json_object_get(json_root, "owners");

    if (!json_is_array(owners)) {
       json_decref(json_root);
       return NSS_STATUS_UNAVAIL;
    }

    return NSS_STATUS_SUCCESS;
}

static enum nss_status free_json() {
    json_decref(json_root);
    json_root = NULL;
}

enum nss_status _nss_puavoadmins_getpwuid_r(uid_t uid, struct passwd *result, char *buf, size_t buflen, int *errnop) {
    json_t *user, *username, *uid_number, *gid_number, *first_name, *last_name;
    int gecos_len, home_len;
    char *gecos, *home;

    init_json();

    while (ent_index < json_array_size(owners)) {
        user = json_array_get(owners, ent_index);
        ent_index++;

        uid_number = json_object_get(user, "uid_number");

        if (json_integer_value(uid_number) != uid)
            continue;

        return populate_passwd(user, result, buf, buflen);
    }

    free_json();
}

enum nss_status _nss_puavoadmins_getpwnam_r(const char *name, struct passwd *result, char *buf, size_t buflen, int *errnop) {
    json_t *user, *username, *uid_number, *gid_number, *first_name, *last_name;
    int gecos_len, home_len;
    char *gecos, *home;

    init_json();

    while (ent_index < json_array_size(owners)) {
        user = json_array_get(owners, ent_index);
        ent_index++;

        username = json_object_get(user, "username");

        if (strcmp(name, json_string_value(username)))
            continue;

        return populate_passwd(user, result, buf, buflen);
    }

    free_json();
}

enum nss_status _nss_puavoadmins_setpwent(void) {
    ent_index = 0;

    return init_json();
}

enum nss_status _nss_puavoadmins_endpwent(void) {
    free_json();
}

enum nss_status _nss_puavoadmins_getpwent_r(struct passwd *pw, char *buf, size_t buflen, int *errnop) {
    json_t *user;
    enum nss_status ret;

    *errnop = 0;

    if (!pw) {
        return NSS_STATUS_UNAVAIL;
    }

    while (ent_index < json_array_size(owners)) {
        user = json_array_get(owners, ent_index);
        ent_index++;

        ret = populate_passwd(user, pw, buf, buflen);

        if (ret == NSS_STATUS_UNAVAIL)
            continue;

        return ret;
    }

    return NSS_STATUS_NOTFOUND;
}
