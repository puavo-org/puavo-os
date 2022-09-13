#define _GNU_SOURCE         /* See feature_test_macros(7) */

#include <sys/types.h>

#include <grp.h>
#include <jansson.h>
#include <stdio.h>
#include <security/pam_modules.h>
#include <unistd.h>

#define PUAVODESKTOPFILES_DIR "/var/lib/puavo-desktop/users"

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
	const char *user, *user_type;
	char *puavodesktop_path;
	int no_groups, retvalue;

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

	no_groups = getgroups(0, NULL);
	if ((groups = calloc(no_groups + 1, sizeof(gid_t))) == NULL) {
		retvalue = PAM_SYSTEM_ERR;
		goto finish;
	}
        if (getgroups(no_groups, groups) == -1) {
		retvalue = PAM_SYSTEM_ERR;
		goto finish;
        }

	/* XXX should determine the correct group by user_type */
	groups[no_groups] = 999;

	if (setgroups(no_groups + 1, groups) == -1) {
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
