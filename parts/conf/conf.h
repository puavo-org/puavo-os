/* puavo-conf
 * Copyright (C) 2016 Opinsys Oy
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef CONF_H
#define CONF_H

#include <stddef.h>

static const char *const PUAVO_CONF_DEFAULT_DB_FILEPATH = DEFAULT_DB_FILEPATH;

typedef struct puavo_conf puavo_conf_t;

struct puavo_conf_list {
        char **keys;
        char **values;
        size_t length;
};

/**
 * puavo_conf_init() - initialize a config object
 *
 * @confp - pointer to an uninitialized config object
 *
 * After a successful call, an initialized config object is allocated on
 * the heap and its address is returned via @confp. The caller is
 * responsible for calling puavo_conf_free() on the config object
 * afterwards.
 *
 * On error, all resources allocated by puavo_conf_init() are freed
 * automatically.
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_init(puavo_conf_t **confp);

/**
 * puavo_conf_free() - free an initialized config object
 *
 * @conf - initialized config object
 *
 * Calling puavo_conf_free() multiple times on the same object is a
 * programming error and leads to undefined behavior.
 */
void puavo_conf_free(puavo_conf_t *conf);

/**
 * puavo_conf_open_db() - open a database
 *
 * @conf        - initialized config object
 *
 * @db_filepath - database filepath string
 *
 * If the database does not exist, it will be created. If @db_filepath
 * is NULL, PUAVO_CONF_DEFAULT_DB_FILEPATH is used instead. After a
 * successful call, the caller is responsible for closing the database
 * by calling puavo_conf_close_db().
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_open_db(puavo_conf_t *conf, const char *db_filepath);

/**
 * puavo_conf_close_db() - close an open database
 *
 * @conf - initialized config object
 *
 * This function must be called to ensure all database operations get
 * finished and all resources get released properly.
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_close_db(puavo_conf_t *conf);

/**
 * puavo_conf_set() - store a parameter
 *
 * @conf  - initialized config object
 *
 * @key   - NUL-terminated string constant
 *
 * @value - NUL-terminated string constant
 *
 * If @key already exists in the database, the value is overwritten.
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_set(puavo_conf_t *conf, char const *key, char const *value);

/**
 * puavo_conf_get() - get a parameter value
 *
 * @conf   - initialized config object
 *
 * @key    - NUL-terminated string constant
 *
 * @valuep - pointer to an uninitialized string
 *
 * After a successful call, @valuep points to a heap-allocated
 * NUL-terminated string value for @key. The caller is responsible for
 * calling free() on the string afterwards.
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_get(puavo_conf_t *conf, char const *key, char **valuep);

/**
 * puavo_conf_get_list() - get a list of all parameters
 *
 * @conf - initialized config object
 *
 * @list - uninitialized parameter list
 *
 * After a successful call, @list contains two heap-allocated vectors
 * of heap-allocated NUL-terminated strings. The caller is responsible
 * for calling puavo_conf_list_free() on @list afterwards.
 *
 * On error, all resources allocated by puavo_conf_list() are freed
 * automatically.
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_get_list(puavo_conf_t *conf,
			struct puavo_conf_list *list);

/**
 * puavo_conf_list_free() - free a parameter list
 *
 * @conf - initialized config object
 *
 * @list - initialized parameter list
 */
void puavo_conf_list_free(puavo_conf_t *conf,
			  struct puavo_conf_list *list);

/**
 * puavo_conf_clear_db() - remove all parameters from the database
 *
 * @conf - initialized config object
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_clear_db(puavo_conf_t *conf);

/**
 * puavo_conf_errstr() - get string describing the error of the last API call
 *
 * @conf - initialized config object
 *
 * Return a NUL-terminated string constant describing the error of the
 * last API call, or NULL if no error has been encountered.
 */
char const *puavo_conf_errstr(struct puavo_conf *conf);

#endif /* CONF_H */
