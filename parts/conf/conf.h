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

int puavo_conf_init(puavo_conf_t **confp);
void puavo_conf_free(puavo_conf_t *conf);

int puavo_conf_open_db(puavo_conf_t *conf, const char *db_filepath);
int puavo_conf_close_db(puavo_conf_t *conf);

int puavo_conf_set(puavo_conf_t *conf, char *key, char *value);
int puavo_conf_get(puavo_conf_t *conf, char *key, char **valuep);

#endif /* CONF_H */
