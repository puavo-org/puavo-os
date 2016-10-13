/* puavo-conf-init
 * Copyright (C) 2016 Opinsys Oy
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include <sys/types.h>
#include <sys/mman.h>
#include <sys/stat.h>

#include <err.h>
#include <fcntl.h>
#include <glob.h>
#include <jansson.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "conf.h"

static int	handle_parameter_definitions(puavo_conf_t *);
static int	handle_paramdef_file(puavo_conf_t *, const char *);
static int	handle_paramdef_json(puavo_conf_t *, const char *);
static int	handle_one_paramdef(puavo_conf_t *, const char *, json_t *);
static int	glob_error(const char *, int);

int
main(void)
{
	puavo_conf_t *conf;
	struct puavo_conf_err err;
	int status;

	status = 0;

	if (puavo_conf_open(&conf, &err))
		errx(1, "Failed to open config backend: %s", err.msg);

	if (handle_parameter_definitions(conf) != 0) {
		warnx("failure in handling parameter definitions");
		status = EXIT_FAILURE;
	}

	if (puavo_conf_close(conf, &err) == -1) {
		warnx("Failed to close config backend: %s", err.msg);
		status = EXIT_FAILURE;
	}

	return status;
}

static int
handle_parameter_definitions(puavo_conf_t *conf)
{
	glob_t globbuf;
	size_t i;
	int ret, retvalue;

	retvalue = 0;

	ret = glob("/usr/share/puavo-conf/definitions/*.json", 0, glob_error,
	    &globbuf);
	if (ret != 0) {
		warnx("glob() failure");
		globfree(&globbuf);
		return 1;
	}

	for (i = 0; i < globbuf.gl_pathc; i++) {
		ret = handle_paramdef_file(conf, globbuf.gl_pathv[i]);
		if (ret != 0) {
			warnx("error handling %s", globbuf.gl_pathv[i]);
			/* Return error, but try other files. */
			retvalue = 1;
		}
	}

	globfree(&globbuf);

	return retvalue;
}

static int
glob_error(const char *epath, int errno)
{
	warnx("error in handling %s: %s", epath, strerror(errno));

	return 1;
}

static int
handle_paramdef_file(puavo_conf_t *conf, const char *filepath)
{
	int fd, ret;
	off_t len;
	char *json;

	ret = 0;

	if ((fd = open(filepath, O_RDONLY)) == -1) {
		warn("open() on %s", filepath);
		return 1;
	}

	if ((len = lseek(fd, 0, SEEK_END)) == -1) {
		warn("lseek() on %s", filepath);
		ret = 1;
		goto finish;
	}

	if ((json = mmap(0, len, PROT_READ, MAP_PRIVATE, fd, 0)) == NULL) {
		warn("mmap() on %s", filepath);
		ret = 1;
		goto finish;
	}

	if (handle_paramdef_json(conf, json) != 0) {
		warnx("handle_paramdef_json() on %s", filepath);
		ret = 1;
	}

finish:
	(void) close(fd);

	return ret;
}

static int
handle_paramdef_json(puavo_conf_t *conf, const char *json)
{
	json_t *root, *param_value;
	json_error_t error;
	const char *param_name;
	int ret;

	ret = 0;

	if ((root = json_loads(json, 0, &error)) == NULL) {
		warnx("error parsing json line %d: %s", error.line, error.text);
		return 1;
	}

	if (!json_is_object(root)) {
		warnx("root is not a json object");
		ret = 1;
		goto finish;
	}

	json_object_foreach(root, param_name, param_value) {
		if (handle_one_paramdef(conf, param_name, param_value) != 0) {
			warnx("error handling %s", param_name);
			/* Return error, but try other keys. */
			ret = 1;
		}
	}

finish:
	json_decref(root);

	return ret;
}

static int
handle_one_paramdef(puavo_conf_t *conf, const char *param_name,
    json_t *param_value)
{
	json_t *default_node;
	const char *value;
	struct puavo_conf_err err;

	if (!json_is_object(param_value)) {
		warnx("parameter %s does not have an object as value",
		    param_name);
		return 1;
	}

	if ((default_node = json_object_get(param_value, "default")) == NULL) {
		warnx("parameter %s does not have a default value", param_name);
		return 1;
	}

	if ((value = json_string_value(default_node)) == NULL) {
		warnx("parameter %s default is not a string", param_name);
		return 1;
	}

	if (puavo_conf_add(conf, param_name, value, &err) != 0) {
		warnx("error adding %s --> %s : %s", param_name, value,
		    err.msg);
		return 1;
	}

	return 0;
}
