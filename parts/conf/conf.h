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

static const char *const PUAVO_CONF_DEFAULT_DB_FILEPATH = DEFAULT_DB_FILEPATH;

typedef struct puavo_conf puavo_conf_t;

struct puavo_conf_param {
        char *key;
        char *val;
};

/**
 * puavo_conf_init() - allocate and initialize a config object
 *
 * @confp - a pointer to an uninitialized config object pointer
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
 * puavo_conf_free() - release resources reserved by a config object
 *
 * @conf - an initialized config object pointer
 *
 * Calling puavo_conf_free() multiple times on the same object is a
 * programmer error and leads to undefined behavior.
 */
void puavo_conf_free(puavo_conf_t *conf);

/**
 * puavo_conf_open_db() - create and/or open a database
 *
 * @conf        - an initialized config object pointer
 *
 * @db_filepath - the filepath for the database, if NULL,
 *                PUAVO_CONF_DEFAULT_DB_FILEPATH is used instead
 *
 * If the database does not exist, it will be created. After a
 * successful call, the caller is responsible for closing the database
 * by calling puavo_conf_close_db().
 *
 * On error, all resources allocated by puavo_conf_open_db() are freed
 * automatically.
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_open_db(puavo_conf_t *conf, const char *db_filepath);

/**
 * puavo_conf_close_db() - close an open database
 *
 * @conf - an initialized config object pointer
 *
 * Close the database. This must be called to ensure all database
 * operations get finished and all resources get released properly.
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_close_db(puavo_conf_t *conf);

/**
 * puavo_conf_set() - store a parameter as a key-value pair
 *
 * @conf  - an initialized config object pointer
 *
 * @key   - a nul-terminated string
 *
 * @value - a nul-terminated string
 *
 * If the key already exists in the database, the value is overwritten.
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_set(puavo_conf_t *conf, char *key, char *value);

/**
 * puavo_conf_get() - retrieve the value of a parameter
 *
 * @conf   - an initialized config object pointer
 *
 * @key    - a nul-terminated string
 *
 * @valuep - a pointer to an uninitialized string
 *
 * After a successful call, a nul-terminated string, containing the
 * value for @key, is allocated on the heap and its address is returned
 * via @valuep. The caller is responsible for calling free() on the
 * string afterwards.
 *
 * On error, all resources allocated by puavo_conf_get() are freed
 * automatically.
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_get(puavo_conf_t *conf, char *key, char **valuep);

/**
 * puavo_conf_list() - retrieve a list of all parameters as key/value pairs
 *
 * @conf    - an initialized config object pointer
 *
 * @paramsp - a pointer to an uninitialized buffer, used for returning a
 *            key/value pairs as parameter structs
 *
 * @lenp    - a pointer to a size variable, used for returning the number
 *            parameters
 *
 * After a successful call, @paramsp point to a heap-allocated buffer
 * containing parameter structs. Key and value fields of each struct are
 * heap-allocated NUL-terminated strings. The length of the buffer is
 * returned via @lenp. The caller is responsible for calling free() on
 * key and value strings of each parameter struct and on the buffer
 * itself.
 *
 * On error, all resources allocated by puavo_conf_list() are freed
 * automatically.
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_list(puavo_conf_t *conf,
                    struct puavo_conf_param **paramsp, size_t *lenp);

/**
 * puavo_conf_clear_db() - remove all entries from the database
 *
 * @conf - an initialized config object pointer
 *
 * Return 0 on success, non-zero otherwise.
 */
int puavo_conf_clear_db(puavo_conf_t *conf);

#endif /* CONF_H */
