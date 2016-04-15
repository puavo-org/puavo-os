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

#define _GNU_SOURCE /* asprintf(), secure_getenv() */

#include <features.h>

/* Function __secure_getenv() was renamed to secure_getenv() in glibc
   version 2.17. Define to support compiling also on older systems. */
#if ! __GLIBC_PREREQ(2, 17)
#define secure_getenv __secure_getenv
#endif

#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/un.h>

#include "common.h"

/* TODO: 1MiB should be enough for 1+ key/value pairs, if not, please
 * implement dynamic buffer reallocation on when DB->get() returns
 * DB_BUFFER_SMALL. */
static const size_t PUAVO_CONF_DEFAULT_DB_BATCH_SIZE = 1048576;
static const char *const PUAVO_CONF_DEFAULT_DB_FILEPATH = "/run/puavo-conf.db";

static int puavo_conf_init(struct puavo_conf **const confp,
                           struct puavo_conf_err *const errp)
{
        struct puavo_conf *conf;

        conf = (struct puavo_conf *) malloc(sizeof(struct puavo_conf));
        if (!conf) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to allocate memory for "
                                   "a config object");
                return -1;
        }
        memset(conf, 0, sizeof(struct puavo_conf));

        conf->lock_fd = -1;

        *confp = conf;

        return 0;
}


static int puavo_conf_db_open(struct puavo_conf *const conf,
                              struct puavo_conf_err *const errp)
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

static int puavo_conf_dbus_open(struct puavo_conf *const conf,
                                struct puavo_conf_err *const errp)
{
        DBusConnection* dbus_conn;
        DBusError dbus_err;
        int retval;

        retval = -1;
        dbus_error_init(&dbus_err);

        dbus_conn = dbus_bus_get(DBUS_BUS_SYSTEM, &dbus_err);
        if (!dbus_conn) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Failed to connect to system bus: %s",
                                   dbus_err.message);
                goto out;
        }
        conf->dbus_conn = dbus_conn;

        retval = 0;
out:
        dbus_error_free(&dbus_err);

        return retval;
}

static const struct puavo_conf_ops PUAVO_CONF_OPS_DB;
static const struct puavo_conf_ops PUAVO_CONF_OPS_DBUS;

int puavo_conf_open(struct puavo_conf **const confp,
                    struct puavo_conf_err *const errp)
{
        int retval;
        struct puavo_conf_err err;
        struct puavo_conf *conf;

        retval = -1;

        if (puavo_conf_init(confp, errp))
                return -1;

        conf = (*confp);

        /* Prioritize direct DB access ... */
        conf->ops = &PUAVO_CONF_OPS_DB;
        if (conf->ops->open(conf, &err) == -1) {
                if (errp)
                        memcpy(errp, &err, sizeof(err));

                if (err.sys_errno == EWOULDBLOCK) {
                        /* ... but fall back to DBus access if the
                         * database is already locked. It is most
                         * probably locked by our DBus-capable daemon
                         * summoned to help us. */
                        conf->ops = &PUAVO_CONF_OPS_DBUS;
                        retval = conf->ops->open(conf, errp);
                }

                goto out;
        }

        retval = 0;
out:
        if (retval) {
                free(*confp);
                *confp = NULL;
        }

        return retval;
}

static int puavo_conf_db_close(struct puavo_conf *const conf,
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

static int puavo_conf_dbus_close(struct puavo_conf *const conf,
                                 struct puavo_conf_err *const errp  __attribute__ ((unused)))
{
        dbus_connection_unref(conf->dbus_conn);
        conf->dbus_conn = NULL;

        return 0;
}

int puavo_conf_close(struct puavo_conf *const conf,
                     struct puavo_conf_err *const errp)
{
        int ret;

        ret = conf->ops->close(conf, errp);
        free(conf);

        return ret;
}

static int puavo_conf_db_get(struct puavo_conf *const conf,
                             char const *const key, char **const valuep,
                             struct puavo_conf_err *const errp)
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
                                   "Failed to get a value from the db for "
                                   "a key '%s'",
                                   key);
                goto out;
        }

        if (db_value.size == 0) {
                value = calloc(1, sizeof(char));
                if (!value) {
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                           "Failed to allocate memory for "
                                           "the value of parameter '%s'", key);
                        goto out;
                }
        } else {
                value = strndup(db_value.data, db_value.size);
                if (!value) {
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                           "Failed to allocate memory for "
                                           "the value of parameter '%s'", key);
                        goto out;
                }
        }
        ret = 0;
out:
        free(db_key.data);
        free(db_value.data);

        if (!ret && valuep)
                *valuep = value;

        return ret;
}

static int puavo_conf_dbus_get(struct puavo_conf *const conf,
                               char const *const key, char **const valuep,
                               struct puavo_conf_err *const errp)
{
        DBusError        dbus_err;
        DBusMessage     *dbus_msg_call        = NULL;
        DBusMessageIter  dbus_msg_call_args;
        DBusMessage     *dbus_msg_reply       = NULL;
        DBusMessageIter  dbus_msg_reply_args;
        int              retval               = -1;

        dbus_error_init(&dbus_err);

        dbus_msg_call = dbus_message_new_method_call("org.puavo.Conf1",
                                                     "/org/puavo/Conf1",
                                                     "org.puavo.Conf1",
                                                     "Get");
        if (!dbus_msg_call) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Failed to create a method call message");
                goto out;
        }

        dbus_message_iter_init_append(dbus_msg_call, &dbus_msg_call_args);
        if (!dbus_message_iter_append_basic(&dbus_msg_call_args,
                                            DBUS_TYPE_STRING,
                                            &key)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Failed to add a parameter to a method "
                                   "call message due to lack of memory");
                goto out;
        }

        dbus_msg_reply = dbus_connection_send_with_reply_and_block(
                conf->dbus_conn,
                dbus_msg_call,
                DBUS_TIMEOUT_USE_DEFAULT,
                &dbus_err);
        if (!dbus_msg_reply) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Failed to call a method: %s",
                                   dbus_err.message);
                goto out;
        }
        dbus_message_unref(dbus_msg_call);
        dbus_msg_call = NULL;

        if (!dbus_message_iter_init(dbus_msg_reply, &dbus_msg_reply_args)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with no arguments");
                goto out;
        }

        if (dbus_message_iter_get_arg_type(&dbus_msg_reply_args) != DBUS_TYPE_STRING) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with wrong type");
                goto out;
        }
        dbus_message_iter_get_basic(&dbus_msg_reply_args, valuep);

        if (dbus_message_iter_next(&dbus_msg_reply_args)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with too many arguments");
                goto out;
        }

        retval = 0;
out:
        if (dbus_msg_reply)
                dbus_message_unref(dbus_msg_reply);

        if (dbus_msg_call)
                dbus_message_unref(dbus_msg_call);

        return retval;
}

int puavo_conf_get(struct puavo_conf *const conf,
                   char const *const key, char **const valuep,
                   struct puavo_conf_err *const errp)
{
        return conf->ops->get(conf, key, valuep, errp);
}

static int puavo_conf_db_set(struct puavo_conf *const conf,
                             char const *const key, char const *const value,
                             struct puavo_conf_err *const errp)
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

int puavo_conf_set(struct puavo_conf *const conf,
                   char const *const key, char const *const value,
                   struct puavo_conf_err *const errp)
{
        return conf->ops->set(conf, key, value, errp);
}

static int puavo_conf_db_overwrite(struct puavo_conf *const conf,
                                   char const *const key, char const *const value,
                                   struct puavo_conf_err *const errp)
{
        bool haskey;

        if (puavo_conf_has_key(conf, key, &haskey, errp) == -1)
                return -1;

        if (!haskey) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_KEYNOTFOUND, 0,
                                   "Failed to overwrite parameter");
                return -1;
        }

        return puavo_conf_set(conf, key, value, errp);
}

int puavo_conf_overwrite(struct puavo_conf *const conf,
                         char const *const key, char const *const value,
                         struct puavo_conf_err *const errp)
{
        return conf->ops->overwrite(conf, key, value, errp);
}

static int puavo_conf_db_add(struct puavo_conf *const conf,
                             char const *const key, char const *const value,
                             struct puavo_conf_err *const errp)
{
        bool haskey;

        if (puavo_conf_has_key(conf, key, &haskey, errp) == -1)
                return -1;

        if (haskey) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_KEYFOUND, 0,
                                   "Failed to add parameter");
                return -1;
        }

        return puavo_conf_set(conf, key, value, errp);
}

int puavo_conf_add(struct puavo_conf *const conf,
                   char const *const key, char const *const value,
                   struct puavo_conf_err *const errp)
{
        return conf->ops->add(conf, key, value, errp);
}

static int puavo_conf_db_has_key(struct puavo_conf *const conf, char const *const key,
                                 bool *const haskey, struct puavo_conf_err *const errp)
{
        struct puavo_conf_err err;

        if (!puavo_conf_get(conf, key, NULL, &err)) {
                *haskey = true;
                return 0;
        }

        if (err.errnum == PUAVO_CONF_ERRNUM_DB && err.db_error == DB_NOTFOUND) {
                *haskey = false;
                return 0;
        }

        if (errp)
                memcpy(errp, &err, sizeof(struct puavo_conf_err));

        return -1;
}

int puavo_conf_has_key(struct puavo_conf *const conf, char const *const key,
                       bool *const haskey, struct puavo_conf_err *const errp)
{
        return conf->ops->has_key(conf, key, haskey, errp);
}

static int puavo_conf_db_get_all(struct puavo_conf *const conf,
                                 struct puavo_conf_list *const list,
                                 struct puavo_conf_err *const errp)
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
                                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS,
                                                   0, "Failed to get all "
                                                   "parameters");
                                goto out;
                        }
                        keys = new_keys;

                        new_values = realloc(values,
                                             sizeof(char *) * (length + 1));
                        if (!new_values) {
                                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS,
                                                   0, "Failed to get all "
                                                   "parameters");
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

int puavo_conf_get_all(struct puavo_conf *const conf,
                       struct puavo_conf_list *const list,
                       struct puavo_conf_err *const errp)
{
        return conf->ops->get_all(conf, list, errp);
}

static int puavo_conf_db_clear(struct puavo_conf *const conf,
                               struct puavo_conf_err *const errp)
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

int puavo_conf_clear(struct puavo_conf *const conf,
                     struct puavo_conf_err *const errp)
{
        return conf->ops->clear(conf, errp);
}

int puavo_conf_check_type(char const *const value,
                          enum puavo_conf_type const type,
                          struct puavo_conf_err *const errp)
{
        switch (type) {
        case PUAVO_CONF_TYPE_ANY:
                break;
        case PUAVO_CONF_TYPE_BOOL:
                if (strcmp(value, "true") && strcmp(value, "false")) {
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_TYPE, 0,
                                           "Expected boolean value, got '%s'",
                                           value);
                        return -1;
                }
                break;
        default:
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_TYPE, 0,
                                   "Unknown type code %d", type);
                return -1;
        }

        return 0;
}

enum puavo_conf_conn puavo_conf_get_conn(puavo_conf_t const *const conf)
{
        if (conf->db)
                return PUAVO_CONF_CONN_DB;

        return PUAVO_CONF_CONN_DBUS;
}

static const struct puavo_conf_ops PUAVO_CONF_OPS_DB = {
        .add       = puavo_conf_db_add,
        .clear     = puavo_conf_db_clear,
        .close     = puavo_conf_db_close,
        .get       = puavo_conf_db_get,
        .get_all   = puavo_conf_db_get_all,
        .has_key   = puavo_conf_db_has_key,
        .open      = puavo_conf_db_open,
        .overwrite = puavo_conf_db_overwrite,
        .set       = puavo_conf_db_set,
};

static const struct puavo_conf_ops PUAVO_CONF_OPS_DBUS = {
        .close     = puavo_conf_dbus_close,
        .get       = puavo_conf_dbus_get,
        .open      = puavo_conf_dbus_open,
};
