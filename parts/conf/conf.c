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

#include <stdlib.h>
#include <string.h>

#include <db.h>

#include "conf.h"

/* TODO: 1MiB should be enough for 1+ key/value pairs, if not, please
 * implement dynamic buffer reallocation on when DB->get() returns
 * DB_BUFFER_SMALL. */
static const size_t PUAVO_CONF_DEFAULT_DB_BATCH_SIZE = 1048576;

struct puavo_conf {
        DB *db;
        int db_err;
};

int puavo_conf_init(struct puavo_conf **const confp)
{
        struct puavo_conf *conf;

        conf = (struct puavo_conf *) malloc(sizeof(struct puavo_conf));
        if (!conf)
                return -PUAVO_CONF_ERR_SYS;
        memset(conf, 0, sizeof(struct puavo_conf));

        *confp = conf;

        return 0;
}

int puavo_conf_open_db(struct puavo_conf *const conf,
                       const char *const db_filepath)
{
        DB *db;
        int db_err;

        if (conf->db)
                return 0;

        db_err = db_create(&db, NULL, 0);
        if (db_err) {
                conf->db_err = db_err;
                return -PUAVO_CONF_ERR_DB;
        }

        db_err = db->open(db, NULL,
                          db_filepath ? db_filepath : PUAVO_CONF_DEFAULT_DB_FILEPATH,
                          NULL, DB_BTREE, DB_CREATE, 0600);
        if (db_err) {
                conf->db_err = db_err;
                db->close(db, 0);
                return -PUAVO_CONF_ERR_DB;
        }

        conf->db = db;
        return 0;
}

int puavo_conf_close_db(struct puavo_conf *const conf)
{
        if (conf->db) {
                int db_err = conf->db->close(conf->db, 0);
                conf->db = NULL;

                if (db_err) {
                        conf->db_err = db_err;
                        return -PUAVO_CONF_ERR_DB;
                }
        }

        return 0;
}

void puavo_conf_free(struct puavo_conf *conf)
{
        free(conf);
}

int puavo_conf_get(struct puavo_conf *const conf,
                   char *const key, char **const valuep)
{
        DBT db_key;
        DBT db_value;
        int db_err;
        char *value;

        memset(&db_key, 0, sizeof(DBT));
        memset(&db_value, 0, sizeof(DBT));

        db_key.data = key;
        db_key.size = strlen(key) + 1;

        db_value.flags = DB_DBT_MALLOC;

        db_err = conf->db->get(conf->db, NULL, &db_key, &db_value, 0);
        if (db_err) {
                conf->db_err = db_err;
                return -PUAVO_CONF_ERR_DB;
        }

        if (db_value.size == 0) {
                value = NULL;
        } else {
                value = (char *) db_value.data;
                value[db_value.size - 1] = '\0';
        }

        *valuep = value;

        return 0;
}

int puavo_conf_set(struct puavo_conf *const conf,
                   char *const key, char *const value)
{
        DBT db_key;
        DBT db_value;
        int db_err;

        memset(&db_key, 0, sizeof(DBT));
        memset(&db_value, 0, sizeof(DBT));

        db_key.data = key;
        db_key.size = strlen(key) + 1;

        db_value.data = value;
        db_value.size = strlen(value) + 1;

        db_err = conf->db->put(conf->db, NULL, &db_key, &db_value, 0);
        if (db_err) {
                conf->db_err = db_err;
                return -PUAVO_CONF_ERR_DB;
        }

        return 0;
}

int puavo_conf_list(puavo_conf_t *const conf,
                    char **const keys, char **const vals, size_t *const lenp)
{
        DBC *db_cursor;
        DBT db_null;
        DBT db_batch;
        int db_err;
        size_t keys_size = 0;
        size_t vals_size = 0;

        memset(&db_null, 0, sizeof(DBT));
        memset(&db_batch, 0, sizeof(DBT));

        db_batch.flags = DB_DBT_USERMEM;
        db_batch.ulen  = PUAVO_CONF_DEFAULT_DB_BATCH_SIZE;
        db_batch.data  = malloc(db_batch.ulen);
        if (!db_batch.data)
                return -PUAVO_CONF_ERR_SYS;

        db_err = conf->db->cursor(conf->db, NULL, &db_cursor, 0);
        if (db_err) {
                conf->db_err = db_err;
                free(db_batch.data);
                return -PUAVO_CONF_ERR_DB;
        }

	/* Prime return values for the empty list case. */
        *lenp = 0;
        *vals = NULL;
        *keys = NULL;

	/* Iterate key/value pairs in batches until all are found. */
        while (1) {
                void *batch_iterator;

                /* Get the next batch of key-value pairs. */
                db_err = db_cursor->get(db_cursor, &db_null, &db_batch,
                                        DB_MULTIPLE_KEY | DB_NEXT);
                switch (db_err) {
                case 0:
                        break;
                case DB_NOTFOUND:
                        goto done;
                default:
                        conf->db_err = db_err;
                        db_cursor->close(db_cursor);
                        free(db_batch.data);
                        return -PUAVO_CONF_ERR_DB;
                }

		/* Iterate the batch. */
                DB_MULTIPLE_INIT(batch_iterator, &db_batch);
                while (1) {
                        char *key;
                        char *val;
                        char *new_keys;
                        char *new_vals;
                        size_t key_size;
                        size_t val_size;
                        size_t key_len;
                        size_t val_len;

                        DB_MULTIPLE_KEY_NEXT(batch_iterator, &db_batch,
                                             key, key_size, val, val_size);
                        if (!batch_iterator)
                                break; /* The batch is empty. */

                        key_len = strnlen(key, key_size);
                        val_len = strnlen(val, val_size);

                        keys_size += key_len + 1;
                        vals_size += val_len + 1;

                        if (!(new_keys = realloc(*keys, keys_size)) ||
                            !(new_vals = realloc(*vals, vals_size))) {
                                free(db_batch.data);
                                free(*keys);
                                free(*vals);
                                return -PUAVO_CONF_ERR_SYS;
                        }
                        *keys = new_keys;
                        *vals = new_vals;

                        /* Copy strings to the return value buffers and
                         * ensure all returned strings are always
                         * NUL-terminated. */
                        (*keys)[keys_size - 1] = '\0';
                        (*vals)[vals_size - 1] = '\0';
                        strncpy(*keys + keys_size - key_len - 1, key, key_len);
                        strncpy(*vals + vals_size - val_len - 1, val, val_len);

                        *lenp += 1;
                }
        }

done:
        db_err = db_cursor->close(db_cursor);
        if (db_err) {
                conf->db_err = db_err;
                free(db_batch.data);
                return -PUAVO_CONF_ERR_DB;
        }

        free(db_batch.data);

        return 0;
}
