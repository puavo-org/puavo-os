#define _GNU_SOURCE         /* See feature_test_macros(7) */

#include <sys/types.h>

#include <grp.h>
#include <jansson.h>
#include <stdio.h>
#include <security/pam_modules.h>
#include <unistd.h>

#define PUAVODESKTOPFILES_DIR "/var/lib/puavo-desktop/users"

#define STUDENT_GID	977
#define TEACHER_GID	978
#define ADMIN_GID	979

int
pam_sm_authenticate(pam_handle_t *pamh, int flags, int argc, const char **argv)
{
	return PAM_IGNORE;
}

int
pam_sm_setcred (pam_handle_t *pamh, int flags, int argc, const char **argv)
{
	json_t *node, *root;
	gid_t *groups;
	gid_t rolegroup_gid;
	const char *user, *user_type;
	char *puavodesktop_path;
	int group_count, retvalue;

	retvalue = PAM_SUCCESS;

	groups = NULL;

	if (!(flags & (PAM_ESTABLISH_CRED | PAM_REINITIALIZE_CRED)))
		return PAM_SUCCESS;

	if (pam_get_user(pamh, &user, NULL) != PAM_SUCCESS)
		return PAM_USER_UNKNOWN;

	if (asprintf(&puavodesktop_path,
	    PUAVODESKTOPFILES_DIR "/%s/puavo_session.json", user) == -1)
		return PAM_SYSTEM_ERR;

	if ((root = json_load_file(puavodesktop_path, 0, NULL)) == NULL) {
		retvalue = PAM_NO_MODULE_DATA;
		goto finish;
	}

	if (!json_is_object(root)) {
		retvalue = PAM_NO_MODULE_DATA;
		goto finish;
	}

	if ((node = json_object_get(root, "user")) == NULL) {
		retvalue = PAM_NO_MODULE_DATA;
		goto finish;
	}

	if (!json_is_object(node)) {
		retvalue = PAM_NO_MODULE_DATA;
		goto finish;
	}

	if ((node = json_object_get(node, "user_type")) == NULL) {
		retvalue = PAM_NO_MODULE_DATA;
		goto finish;
	}

	if (!json_is_string(node)) {
		retvalue = PAM_NO_MODULE_DATA;
		goto finish;
	}

	if ((user_type = json_string_value(node)) == NULL) {
		retvalue = PAM_NO_MODULE_DATA;
		goto finish;
	}

	if (strcmp("student", user_type) == 0) {
		rolegroup_gid = STUDENT_GID;
	} else if (strcmp("teacher", user_type) == 0) {
		rolegroup_gid = TEACHER_GID;
	} else if (strcmp("admin", user_type) == 0) {
		rolegroup_gid = ADMIN_GID;
	} else {
		goto finish;
	}

	group_count = getgroups(0, NULL);
	if ((groups = calloc(group_count + 1, sizeof(gid_t))) == NULL) {
		retvalue = PAM_SYSTEM_ERR;
		goto finish;
	}

	if (getgroups(group_count, groups) == -1) {
		retvalue = PAM_SYSTEM_ERR;
		goto finish;
	}

	groups[group_count] = rolegroup_gid;
	if (setgroups(group_count + 1, groups) == -1) {
		retvalue = PAM_SYSTEM_ERR;
		goto finish;
	}

finish:
	if (groups)
		free(groups);
	if (root)
		json_decref(root);

	free(puavodesktop_path);

	return retvalue;
}
