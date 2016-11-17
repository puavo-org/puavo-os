/* puavo-conf-update
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

/*
 * puavo-template is a templating system which uses CTPL
 * (https://ctpl.tuxfamily.org/) as a template engine, and where
 * puavo-conf variables are available (with '.' characters converted
 * to '_').  It reads templates from standard input, and outputs
 * to standard output, or alternatively to a file when given an argument.
 */

#define _GNU_SOURCE

#include <ctpl/ctpl.h>
#include <err.h>
#include <glib.h>
#include <gio/gio.h>
#include <gio/gunixoutputstream.h>
#include <stdio.h>
#include <stdlib.h>

#include "conf.h"

CtplOutputStream	*get_outputstream(const char *);
char			*get_tempfile_path(const char *);
static gboolean		 handle_template(CtplEnviron *, const char *);

int
main(int argc, char *argv[])
{
	puavo_conf_t *conf;
	struct puavo_conf_list list;
	struct puavo_conf_err err;
	CtplEnviron *ctpl_env;
	size_t i, j;
	int status;

	status = EXIT_SUCCESS;

	if (argc != 2)
		errx(1, "Usage: puavo-template outputfile");

	if (puavo_conf_open(&conf, &err))
		errx(1, "Failed to open config backend: %s", err.msg);

	if (puavo_conf_get_all(conf, &list, &err)) {
		warnx("Failed to get parameter list: %s", err.msg);
		status = EXIT_FAILURE;
	}

	if ((ctpl_env = ctpl_environ_new()) == NULL) {
		warnx("ctpl_environ_new() error");
		status = EXIT_FAILURE;
		goto finish;
	}

	for (i = 0; i < list.length; i++) {
		/* XXX ugly hack to get rid of "." in keys */
		for (j = 0; list.keys[i][j] != '\0'; j++) {
			if (list.keys[i][j] == '.')
				list.keys[i][j] = '_';
		}

		ctpl_environ_push_string(ctpl_env, list.keys[i],
		    list.values[i]);
	}

	if (!handle_template(ctpl_env, argv[1]))
		status = EXIT_FAILURE;

finish:
	if (puavo_conf_close(conf, &err) == -1) {
		warnx("Failed to close config backend: %s", err.msg);
		status = EXIT_FAILURE;
	}

	if (ctpl_env != NULL)
		ctpl_environ_unref(ctpl_env);

	return status;
}

static gboolean
handle_template(CtplEnviron *ctpl_env, const char *outputpath)
{
	CtplInputStream 	*instream;
	CtplOutputStream	*outstream;
	CtplToken		*tree;
	GError			*err;
	char 			*tmp_outputpath;
	gboolean		 rv;

	err = NULL;
	instream = ctpl_input_stream_new_for_path("/dev/stdin", &err);
	if (instream == NULL) {
		warnx("ctpl_input_stream_new_for_path() error: %s",
		    err->message);
		g_error_free(err);
		return FALSE;
	}

	err = NULL;
	tree = ctpl_lexer_lex(instream, &err);
	ctpl_input_stream_unref(instream);
	if (tree == NULL) {
		warnx("error lexing template: %s", err->message);
		g_error_free(err);
		return FALSE;
	}

	if ((tmp_outputpath = get_tempfile_path(outputpath)) == NULL) {
		ctpl_token_free(tree);
		return FALSE;
	}

	outstream = get_outputstream(tmp_outputpath);
	if (outstream == NULL) {
		free(tmp_outputpath);
		ctpl_token_free(tree);
		return FALSE;
	}

	err = NULL;
	rv = ctpl_parser_parse(tree, ctpl_env, outstream, &err);
	if (!rv)
		warnx("error parsing template: %s", err->message);

	ctpl_output_stream_unref(outstream);

	if (rename(tmp_outputpath, outputpath) == -1) {
		warn("could not rename %s to %s", tmp_outputpath, outputpath);
		rv = FALSE;
	}

	free(tmp_outputpath);
	ctpl_token_free(tree);

	return rv;
}

char *
get_tempfile_path(const char *path_prefix)
{
	char	*tmpfile_path;
	size_t	 path_size;

	path_size = strlen(path_prefix);
	tmpfile_path = malloc(path_size + sizeof(".tmp"));
	if (tmpfile_path == NULL) {
		warnx("malloc failure");
		return NULL;
	}

	(void) strncpy(tmpfile_path, path_prefix, path_size + 1);
	(void) strncat(tmpfile_path, ".tmp", sizeof(".tmp"));

	return tmpfile_path;
}

CtplOutputStream *
get_outputstream(const char *outputpath)
{
	CtplOutputStream	*outstream;
	GError			*err;
	GFile			*file;
	GFileOutputStream	*gfostream;
	GOutputStream   	*gostream;

	err = NULL;

	file = g_file_new_for_commandline_arg(outputpath);
	gfostream = g_file_replace(file, NULL, FALSE, 0, NULL, &err);
	if (!gfostream) {
		warnx("could not open %s for writing: %s", outputpath,
		    err->message);
		g_object_unref(file);
		return NULL;
	}

	gostream = G_OUTPUT_STREAM(gfostream);
	outstream = ctpl_output_stream_new(gostream);
	g_object_unref(gostream);
	g_object_unref(file);

	return outstream;
}
