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

#define _GNU_SOURCE /* asprintf() */

#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/un.h>

#include <db.h>

#include "conf.h"

/* TODO: 1MiB should be enough for 1+ key/value pairs, if not, please
 * implement dynamic buffer reallocation on when DB->get() returns
 * DB_BUFFER_SMALL. */
static const size_t PUAVO_CONF_DEFAULT_DB_BATCH_SIZE = 1048576;
static const char *const PUAVO_CONF_DEFAULT_DB_FILEPATH = DEFAULT_DB_FILEPATH;

struct puavo_conf {
        DB *db;
        int confd_socket;
        int lock_fd;
};

enum PUAVO_CONF_ERRNUM {
        PUAVO_CONF_ERRNUM_DB = 1,
        PUAVO_CONF_ERRNUM_SYS,
        PUAVO_CONF_ERRNUMCOUNT
};

static void puavo_conf_err_set(struct puavo_conf_err *const errp,
                              int const errnum,
                              int const db_error,
                              char const *const fmt,
                              ...)
{
        char *msg;
        va_list ap;

        if (!errp)
                return;

        errp->errnum = errnum;
        errp->db_error = db_error;
        errp->sys_errno = errnum == PUAVO_CONF_ERRNUM_SYS ? errno : 0;

        va_start(ap, fmt);
        if (vasprintf(&msg, fmt, ap) == -1)
                msg = NULL;
        va_end(ap);

        switch (errp->errnum) {
        case 0:
                snprintf(errp->msg, sizeof(errp->msg),
                         "This ain't error: %s", msg ? msg : "");
                break;
        case PUAVO_CONF_ERRNUM_SYS:
                snprintf(errp->msg, sizeof(errp->msg),
                         "%s: %s", msg ? msg : "",
                         strerror(errp->sys_errno));
                break;
        case PUAVO_CONF_ERRNUM_DB:
                snprintf(errp->msg, sizeof(errp->msg),
                         "%s: %s", msg ? msg : "",
                         db_strerror(errp->db_error));
                break;
        default:
                snprintf(errp->msg, sizeof(errp->msg),
                         "Unknown error %d: %s",
                         errp->errnum, msg ? msg : "");
                break;
        }

        free(msg);
}

static int puavo_conf_init(struct puavo_conf **const confp,
                           struct puavo_conf_err *errp)
{
        struct puavo_conf *conf;

        conf = (struct puavo_conf *) malloc(sizeof(struct puavo_conf));
        if (!conf) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to allocate memory for a config object");
                return -1;
        }
        memset(conf, 0, sizeof(struct puavo_conf));

        conf->confd_socket = -1;
        conf->lock_fd = -1;

        *confp = conf;

        return 0;
}

static int puavo_conf_open_socket(struct puavo_conf *const conf,
                                  struct puavo_conf_err *errp)
{
        int confd_socket;
        struct sockaddr_un sockaddr;

        confd_socket = socket(AF_UNIX, SOCK_STREAM, 0);
        if (confd_socket < 0) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to create a local socket");
                goto err;
        }

        memset(&sockaddr, 0, sizeof(struct sockaddr_un));
        sockaddr.sun_family = AF_UNIX;
        (void) strncpy(sockaddr.sun_path, "/tmp/puavo-conf.sock",
                       sizeof(sockaddr.sun_path));

        if (connect(confd_socket, (struct sockaddr *) &sockaddr,
                    sizeof(struct sockaddr_un))) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to connect the socket to %s",
                                   sockaddr.sun_path);
                goto err;
        }

        conf->confd_socket = confd_socket;
        return 0;
err:
        /* Errors ignored, because we have already failed. */
        (void) close(confd_socket);

        return -1;
}

static int puavo_conf_open_db(struct puavo_conf *const conf,
                              struct puavo_conf_err *errp)
{
        DB *db = NULL;
        char const *db_filepath;
        char *lock_filepath = NULL;
        int lock_fd = -1;
        int db_error;

        db_filepath = secure_getenv("PUAVO_CONF_DB_FILEPATH");
        if (!db_filepath)
                db_filepath = PUAVO_CONF_DEFAULT_DB_FILEPATH;

        if (asprintf(&lock_filepath, "%s.lock", db_filepath) == -1) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to allocate memory for a db lock "
                                   "file path string");
                lock_filepath = NULL;
                goto err;
        }

        lock_fd = open(lock_filepath, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
        if (lock_fd == -1) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to open the db lock file '%s'",
                                   lock_filepath);
                goto err;
        }

        free(lock_filepath);
        lock_filepath = NULL;

        if (flock(lock_fd, LOCK_EX | LOCK_NB) == -1) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to lock the db lock file '%s'",
                                   lock_filepath);
                goto err;
        }

        db_error = db_create(&db, NULL, 0);
        if (db_error) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DB, db_error,
                                   "Failed to create a db object");
                db = NULL;
                goto err;
        }


        db_error = db->open(db, NULL, db_filepath,
                          NULL, DB_BTREE, DB_CREATE, 0600);
        if (db_error) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DB, db_error,
                                   "Failed to open the db file '%s'",
                                   db_filepath);
                goto err;
        }

        conf->lock_fd = lock_fd;
        conf->db = db;
        return 0;
err:
        free(lock_filepath);

        if (lock_fd >= 0)
                close(lock_fd);

        if (db)
                db->close(db, 0);

        return -1;
}

int puavo_conf_open(struct puavo_conf **const confp,
                    struct puavo_conf_err *errp)
{
        if (puavo_conf_init(confp, errp))
                return -1;
        /* if (!puavo_conf_open_socket(*confp, errp)) */
        /*         return 0; */

        return puavo_conf_open_db(*confp, errp);
}

static int puavo_conf_close_db(struct puavo_conf *const conf,
                               struct puavo_conf_err *errp)
{
        int ret = 0;
        int db_error;

        db_error = conf->db->close(conf->db, 0);
        conf->db = NULL;
        if (db_error) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DB, db_error,
                                   "Failed to close the db");
                ret = -1;
        }
        if (close(conf->lock_fd) == -1 && !ret) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to close the db lock file");
                ret = -1;
        }
        conf->lock_fd = -1;

        return ret;
}

static int puavo_conf_close_socket(struct puavo_conf *const conf,
                                   struct puavo_conf_err *errp)
{
        int ret = 0;

        if (close(conf->confd_socket)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to close a socket");
                ret = -1;
        }

        conf->confd_socket = -1;

        return ret;
}

int puavo_conf_close(struct puavo_conf *const conf,
                     struct puavo_conf_err *errp)
{
        int ret = 0;

        if (conf->db)
                ret = puavo_conf_close_db(conf, errp);
        else
                ret = puavo_conf_close_socket(conf, errp);

        free(conf);

        return ret;
}

int puavo_conf_get(struct puavo_conf *const conf,
                   char const *const key, char **const valuep,
                   struct puavo_conf_err *errp)
{
        DBT db_key;
        DBT db_value;
        char *value;
        int ret = -1;
        int db_error;

        memset(&db_key, 0, sizeof(DBT));
        memset(&db_value, 0, sizeof(DBT));

        db_key.size = strlen(key) + 1;
        db_key.data = strdup(key);
        if (!db_key.data) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to allocate memory for a db key '%s'",
                                   key);
                goto out;
        }

        db_value.flags = DB_DBT_MALLOC;

        db_error = conf->db->get(conf->db, NULL, &db_key, &db_value, 0);
        if (db_error) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DB, db_error,
                                   "Failed to get a value from the db for a key '%s'",
                                   key);
                goto out;
        }

        if (db_value.size == 0) {
                value = calloc(1, sizeof(char));
                if (!value) {
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                           "Failed to allocate memory for the value of parameter '%s'", key);
                        goto out;
                }
        } else {
                value = strndup(db_value.data, db_value.size);
                if (!value) {
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                           "Failed to allocate memory for the value of parameter '%s'", key);
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
                   char const *const key, char const *const value,
                   struct puavo_conf_err *errp)
{
        DBT db_key;
        DBT db_value;
        int ret = -1;
        int db_error;

        memset(&db_key, 0, sizeof(DBT));
        memset(&db_value, 0, sizeof(DBT));

        db_key.size = strlen(key) + 1;
        db_key.data = strdup(key);
        if (!db_key.data) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to set parameter");
                goto out;
        }

        db_value.size = strlen(value) + 1;
        db_value.data = strdup(value);
        if (!db_value.data) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to set parameter");
                goto out;
        }

        db_error = conf->db->put(conf->db, NULL, &db_key, &db_value, 0);
        if (db_error) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DB, db_error,
                                   "Failed to set parameter");
                goto out;
        }

        ret = 0;
out:
        free(db_key.data);
        free(db_value.data);

        return ret;
}

int puavo_conf_get_all(struct puavo_conf *const conf,
                       struct puavo_conf_list *const list,
                       struct puavo_conf_err *errp)
{
        DBC *db_cursor = NULL;
        DBT db_null;
        DBT db_batch;
        size_t length = 0;
        char **keys = NULL;
        char **values = NULL;
        int ret = -1;
        int db_error;

        memset(&db_null, 0, sizeof(DBT));
        memset(&db_batch, 0, sizeof(DBT));

        db_batch.flags = DB_DBT_USERMEM;
        db_batch.ulen  = PUAVO_CONF_DEFAULT_DB_BATCH_SIZE;
        db_batch.data  = malloc(db_batch.ulen);
        if (!db_batch.data) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to get all parameters");
                goto out;
        }

        db_error = conf->db->cursor(conf->db, NULL, &db_cursor, 0);
        if (db_error) {
                db_cursor = NULL;
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DB, db_error,
                                   "Failed to get all parameters");
                goto out;
        }

        /* Iterate key/value pairs in batches until all are found. */
        while (1) {
                void *batch_iterator;

                /* Get the next batch of key-value pairs. */
                db_error = db_cursor->get(db_cursor, &db_null, &db_batch,
                                        DB_MULTIPLE_KEY | DB_NEXT);
                switch (db_error) {
                case 0:
                        break;
                case DB_NOTFOUND:
                        ret = 0;
                        goto out;
                default:
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DB, db_error,
                                           "Failed to get all parameters");
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
                                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                                   "Failed to get all parameters");
                                goto out;
                        }
                        keys = new_keys;

                        new_values = realloc(values,
                                           sizeof(char *) * (length + 1));
                        if (!new_values) {
                                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                                   "Failed to get all parameters");
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
                db_error = db_cursor->close(db_cursor);
                /* Obey exit-on-first-error policy: Do not shadow any
                 * existing error, record close error only if we are
                 * cleaning up without any earlier errors. */
                if (!ret && db_error) {
                        ret = -1;
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DB, db_error,
                                           "Failed to get all parameters");
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

int puavo_conf_clear(struct puavo_conf *const conf,
                     struct puavo_conf_err *errp)
{
        int db_error;
        unsigned int count;

        db_error = conf->db->truncate(conf->db, NULL, &count, 0);
        if (db_error) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DB, db_error,
                                   "Failed to clear parameters");
                return -1;
        }

        return 0;
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
