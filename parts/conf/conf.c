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

#include <errno.h>
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
        int err;
        int sys_err;
};

enum PUAVO_CONF_ERR {
        PUAVO_CONF_ERR_DB = 1,
        PUAVO_CONF_ERR_SYS,
        PUAVO_CONF_ERRCOUNT
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

        conf->err = 0;

        if (conf->db)
                return 0;

        conf->db_err = db_create(&db, NULL, 0);
        if (conf->db_err) {
                conf->err = PUAVO_CONF_ERR_DB;
                return -conf->err;
        }

        conf->db_err = db->open(db, NULL,
                                db_filepath ? db_filepath : PUAVO_CONF_DEFAULT_DB_FILEPATH,
                                NULL, DB_BTREE, DB_CREATE, 0600);
        if (conf->db_err) {
                conf->err = PUAVO_CONF_ERR_DB;
                db->close(db, 0);
                return -conf->err;
        }

        conf->db = db;
        return 0;
}

int puavo_conf_close_db(struct puavo_conf *const conf)
{
        conf->err = 0;

        if (conf->db) {
                conf->db_err = conf->db->close(conf->db, 0);
                if (conf->db_err)
                        conf->err = PUAVO_CONF_ERR_DB;
                conf->db = NULL;
        }

        return -conf->err;
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
        char *value;

        conf->err = 0;

        memset(&db_key, 0, sizeof(DBT));
        memset(&db_value, 0, sizeof(DBT));

        db_key.data = key;
        db_key.size = strlen(key) + 1;

        db_value.flags = DB_DBT_MALLOC;

        conf->db_err = conf->db->get(conf->db, NULL, &db_key, &db_value, 0);
        if (conf->db_err) {
                conf->err = PUAVO_CONF_ERR_DB;
                return -conf->err;
        }

        if (db_value.size == 0) {
                value = calloc(1, sizeof(char));
                if (!value) {
                        conf->sys_err = errno;
                        conf->err = PUAVO_CONF_ERR_SYS;
                        free(db_value.data);
                        return -conf->err;
                }
        } else {
                value = strndup(db_value.data, db_value.size);
                if (!value) {
                        conf->sys_err = errno;
                        conf->err = PUAVO_CONF_ERR_SYS;
                        free(db_value.data);
                        return -conf->err;
                }
        }

        *valuep = value;

        return 0;
}

int puavo_conf_set(struct puavo_conf *const conf,
                   char const *const key, char const *const value)
{
        DBT db_key;
        DBT db_value;

        conf->err = 0;

        memset(&db_key, 0, sizeof(DBT));
        memset(&db_value, 0, sizeof(DBT));

        db_key.size = strlen(key) + 1;
        db_key.data = strdup(key);
        if (!db_key.data) {
                conf->sys_err = errno;
                conf->err = PUAVO_CONF_ERR_SYS;
                goto out;
        }

        db_value.size = strlen(value) + 1;
        db_value.data = strdup(value);
        if (!db_value.data) {
                conf->sys_err = errno;
                conf->err = PUAVO_CONF_ERR_SYS;
                goto out;
        }

        conf->db_err = conf->db->put(conf->db, NULL, &db_key, &db_value, 0);
        if (conf->db_err)
                conf->err = PUAVO_CONF_ERR_DB;

out:
        free(db_key.data);
        free(db_value.data);

        return -conf->err;
}

int puavo_conf_list(puavo_conf_t *const conf,
                    struct puavo_conf_param **const paramsp, size_t *const lenp)
{
        DBC *db_cursor = NULL;
        DBT db_null;
        DBT db_batch;
        struct puavo_conf_param *params = NULL;
        size_t len = 0;

        conf->err = 0;

        memset(&db_null, 0, sizeof(DBT));
        memset(&db_batch, 0, sizeof(DBT));

        db_batch.flags = DB_DBT_USERMEM;
        db_batch.ulen  = PUAVO_CONF_DEFAULT_DB_BATCH_SIZE;
        db_batch.data  = malloc(db_batch.ulen);
        if (!db_batch.data) {
                conf->sys_err = errno;
                conf->err = PUAVO_CONF_ERR_SYS;
                goto out;
        }

        conf->db_err = conf->db->cursor(conf->db, NULL, &db_cursor, 0);
        if (conf->db_err) {
                db_cursor = NULL;
                conf->err = PUAVO_CONF_ERR_DB;
                goto out;
        }

	/* Iterate key/value pairs in batches until all are found. */
        while (1) {
                void *batch_iterator;

                /* Get the next batch of key-value pairs. */
                conf->db_err = db_cursor->get(db_cursor, &db_null, &db_batch,
                                              DB_MULTIPLE_KEY | DB_NEXT);
                switch (conf->db_err) {
                case 0:
                        break;
                case DB_NOTFOUND:
                        goto out;
                default:
                        conf->err = PUAVO_CONF_ERR_DB;
                        goto out;
                }

		/* Iterate the batch. */
                DB_MULTIPLE_INIT(batch_iterator, &db_batch);
                while (1) {
                        char *key;
                        char *val;
                        size_t key_size;
                        size_t val_size;
                        struct puavo_conf_param *new_params;

                        DB_MULTIPLE_KEY_NEXT(batch_iterator, &db_batch,
                                             key, key_size, val, val_size);
                        if (!batch_iterator)
                                break; /* The batch is empty. */

                        new_params = realloc(params,
                                             sizeof(struct puavo_conf_param)
                                             * (len + 1));
                        if (!new_params) {
                                conf->sys_err = errno;
                                conf->err = PUAVO_CONF_ERR_SYS;
                                goto out;
                        }
                        params = new_params;
                        ++len;

                        params[len - 1].key = strndup(key, key_size);
                        params[len - 1].val = strndup(val, val_size);
                }
        }
out:
        if (db_cursor) {
                int db_err = db_cursor->close(db_cursor);
                /* Obey exit-on-first-error policy: Do not shadow any
                 * existing error, record close error only if we are
                 * cleaning up without any earlier errors. */
                if (!conf->err && db_err) {
                        conf->db_err = db_err;
                        conf->err = PUAVO_CONF_ERR_DB;
                }
        }

        if (conf->err) {
                size_t i;

                for (i = 0; i < len; ++i) {
                        free(params[i].key);
                        free(params[i].val);
                }
                free(params);
        } else {
                /* Return parameter buffer and its length only on success. */
                *paramsp = params;
                *lenp    = len;
        }

        free(db_batch.data);

        return -conf->err;
}

int puavo_conf_clear_db(struct puavo_conf *const conf)
{
	unsigned int count;

        conf->err = 0;

	conf->db_err = conf->db->truncate(conf->db, NULL, &count, 0);
	if (conf->db_err) {
                conf->sys_err = errno;
		conf->err = PUAVO_CONF_ERR_DB;
        }

	return -conf->err;
}

char const *puavo_conf_errstr(struct puavo_conf *const conf)
{
        static char const *const errstrs[PUAVO_CONF_ERRCOUNT] = {
                NULL,
                "database error",
                "system call error",
        };

        if (conf->err < 0 || conf->err >= PUAVO_CONF_ERRCOUNT) {
                return "unknown error";
        }

        return errstrs[conf->err];
}
