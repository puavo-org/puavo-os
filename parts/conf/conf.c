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
#include <sys/socket.h>
#include <sys/un.h>

#include <db.h>

#include "conf.h"
#include "db.h"

/* TODO: 1MiB should be enough for 1+ key/value pairs, if not, please
 * implement dynamic buffer reallocation on when DB->get() returns
 * DB_BUFFER_SMALL. */
static const size_t PUAVO_CONF_DEFAULT_DB_BATCH_SIZE = 1048576;

struct puavo_conf {
        DB *db;
        int db_err;
        int err;
        int sys_err;
        int confd_socket;
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
                return -1;
        memset(conf, 0, sizeof(struct puavo_conf));

        conf->confd_socket = -1;

        *confp = conf;

        return 0;
}

static int puavo_conf_open_socket(struct puavo_conf *const conf)
{
        int ret;
        int confd_socket;
        struct sockaddr_un sockaddr;

        if (conf->confd_socket >= 0)
                return 0;

        ret = -1;

        confd_socket = socket(AF_UNIX, SOCK_STREAM, 0);
        if (confd_socket < 0) {
                conf->sys_err = errno;
                conf->err = PUAVO_CONF_ERR_SYS;
                goto out;
        }

        memset(&sockaddr, 0, sizeof(struct sockaddr_un));
        sockaddr.sun_family = AF_UNIX;
        (void) strncpy(sockaddr.sun_path, "/tmp/puavo-conf.sock",
                       sizeof(sockaddr.sun_path));

        if (connect(confd_socket, (struct sockaddr *) &sockaddr,
                    sizeof(struct sockaddr_un))) {
                conf->sys_err = errno;
                conf->err = PUAVO_CONF_ERR_SYS;
                goto out;
        }

        ret = 0;
out:
        if (ret) {
                /* Errors ignored, because we have already failed. */
                (void) close(confd_socket);
        } else {
                /* Set return values only on success. */
                conf->confd_socket = confd_socket;
        }

        return ret;
}

int puavo_conf_open_db(struct puavo_conf *const conf,
                       const char *const db_filepath)
{
        DB *db;

        if (conf->db)
                return 0;

        conf->db_err = db_create(&db, NULL, 0);
        if (conf->db_err) {
                conf->err = PUAVO_CONF_ERR_DB;
                return -1;
        }

        conf->db_err = db->open(db, NULL,
                                db_filepath ? db_filepath : PUAVO_CONF_DEFAULT_DB_FILEPATH,
                                NULL, DB_BTREE, DB_CREATE, 0600);
        if (conf->db_err) {
                conf->err = PUAVO_CONF_ERR_DB;
                db->close(db, 0);
                return -1;
        }

        conf->db = db;
        return 0;
}

int puavo_conf_open(struct puavo_conf *const conf)
{
        if (conf->confd_socket >= 0 || conf->db)
                return 0;

        if (!puavo_conf_open_socket(conf))
                return 0;

        if (conf->err == PUAVO_CONF_ERR_SYS && conf->sys_err == ECONNREFUSED)
                return puavo_conf_open_db(conf, NULL);

        return -1;
}

int puavo_conf_close_db(struct puavo_conf *const conf)
{
        if (conf->db) {
                conf->db_err = conf->db->close(conf->db, 0);
                conf->db = NULL;
                if (conf->db_err) {
                        conf->err = PUAVO_CONF_ERR_DB;
                        return -1;
                }
        }

        return 0;
}

static int puavo_conf_close_socket(struct puavo_conf *const conf)
{
        if (conf->confd_socket >= 0 && close(conf->confd_socket)) {
                conf->sys_err = errno;
                conf->err = PUAVO_CONF_ERR_SYS;
                conf->confd_socket = -1;
                return -1;
        }

        return 0;
}

int puavo_conf_close(struct puavo_conf *const conf)
{
        if (conf->db)
                return puavo_conf_close_db(conf);

        if (conf->confd_socket >= 0)
                return puavo_conf_close_socket(conf);

        return 0;
}

void puavo_conf_free(struct puavo_conf *conf)
{
        free(conf);
}

int puavo_conf_get(struct puavo_conf *const conf,
                   char const *const key, char **const valuep)
{
        DBT db_key;
        DBT db_value;
        char *value;
        int ret = -1;

        memset(&db_key, 0, sizeof(DBT));
        memset(&db_value, 0, sizeof(DBT));

        db_key.size = strlen(key) + 1;
        db_key.data = strdup(key);
        if (!db_key.data) {
                conf->sys_err = errno;
                conf->err = PUAVO_CONF_ERR_SYS;
                goto out;
        }

        db_value.flags = DB_DBT_MALLOC;

        conf->db_err = conf->db->get(conf->db, NULL, &db_key, &db_value, 0);
        if (conf->db_err) {
                conf->err = PUAVO_CONF_ERR_DB;
                goto out;
        }

        if (db_value.size == 0) {
                value = calloc(1, sizeof(char));
                if (!value) {
                        conf->sys_err = errno;
                        conf->err = PUAVO_CONF_ERR_SYS;
                        goto out;
                }
        } else {
                value = strndup(db_value.data, db_value.size);
                if (!value) {
                        conf->sys_err = errno;
                        conf->err = PUAVO_CONF_ERR_SYS;
                        goto out;
                }
        }
        ret = 0;
out:
        free(db_key.data);
        free(db_value.data);

        if (!ret)
                *valuep = value;

        return ret;
}

int puavo_conf_set(struct puavo_conf *const conf,
                   char const *const key, char const *const value)
{
        DBT db_key;
        DBT db_value;
        int ret = -1;

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
        if (conf->db_err) {
                conf->err = PUAVO_CONF_ERR_DB;
                goto out;
        }

        ret = 0;
out:
        free(db_key.data);
        free(db_value.data);

        return ret;
}

int puavo_conf_get_list(struct puavo_conf *const conf,
                        struct puavo_conf_list *const list)
{
        DBC *db_cursor = NULL;
        DBT db_null;
        DBT db_batch;
        size_t length = 0;
        char **keys = NULL;
        char **values = NULL;
        int ret = -1;

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
                        ret = 0;
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
                        char **new_keys;
                        char **new_values;

                        DB_MULTIPLE_KEY_NEXT(batch_iterator, &db_batch,
                                             key, key_size, val, val_size);
                        if (!batch_iterator)
                                break; /* The batch is empty. */

                        new_keys = realloc(keys,
                                           sizeof(char *) * (length + 1));
                        if (!new_keys) {
                                conf->sys_err = errno;
                                conf->err = PUAVO_CONF_ERR_SYS;
                                goto out;
                        }
                        keys = new_keys;

                        new_values = realloc(values,
                                           sizeof(char *) * (length + 1));
                        if (!new_values) {
                                conf->sys_err = errno;
                                conf->err = PUAVO_CONF_ERR_SYS;
                                goto out;
                        }
                        values = new_values;

                        ++length;

                        keys[length - 1] = strndup(key, key_size);
                        values[length - 1] = strndup(val, val_size);
                }
        }
        ret = 0;
out:
        if (db_cursor) {
                int db_err = db_cursor->close(db_cursor);
                /* Obey exit-on-first-error policy: Do not shadow any
                 * existing error, record close error only if we are
                 * cleaning up without any earlier errors. */
                if (!ret && db_err) {
                        ret = -1;
                        conf->db_err = db_err;
                        conf->err = PUAVO_CONF_ERR_DB;
                }
        }

        if (ret) {
                size_t i;

                for (i = 0; i < length; ++i) {
                        free(keys[i]);
                        free(values[i]);
                }
                free(keys);
                free(values);
        } else {
                list->keys = keys;
                list->values = values;
                list->length = length;
        }

        free(db_batch.data);

        return ret;
}

int puavo_conf_clear_db(struct puavo_conf *const conf)
{
        unsigned int count;

        conf->db_err = conf->db->truncate(conf->db, NULL, &count, 0);
        if (conf->db_err) {
                conf->sys_err = errno;
                conf->err = PUAVO_CONF_ERR_DB;
                return -1;
        }

        return 0;
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

void puavo_conf_list_free(struct puavo_conf *const conf __attribute__((unused)),
                          struct puavo_conf_list *const list)
{
        size_t i;

        for (i = 0; i < list->length; ++i) {
                free(list->keys[i]);
                free(list->values[i]);
        }
        free(list->keys);
        free(list->values);

        list->keys = NULL;
        list->values = NULL;
        list->length = 0;
}
