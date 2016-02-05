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

#ifndef DB_H
#define DB_H

static const char *const PUAVO_CONF_DEFAULT_DB_FILEPATH = DEFAULT_DB_FILEPATH;

/**
 * puavo_conf_clear_db() - remove all parameters from the database
 *
 * @conf - initialized config object
 *
 * Return 0 on success and -1 on error.
 */
int puavo_conf_clear_db(puavo_conf_t *conf);

/**
 * puavo_conf_close_db() - close an open database
 *
 * @conf - initialized config object
 *
 * This function must be called to ensure all database operations get
 * finished and all resources get released properly.
 *
 * Return 0 on success and -1 on error.
 */
int puavo_conf_close_db(puavo_conf_t *conf);

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
 * Return 0 on success and -1 on error.
 */
int puavo_conf_open_db(puavo_conf_t *conf, const char *db_filepath);

#endif /* DB_H */
