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

#include <string.h>

#include "dbus.h"

int puavo_conf_dbus_add(struct puavo_conf *const conf,
                              char const *const key,
                              char const *const value,
                              struct puavo_conf_err *const errp)
{
        DBusError        dbus_err;
        DBusMessage     *dbus_msg_call        = NULL;
        DBusMessageIter  dbus_msg_call_args;
        DBusMessage     *dbus_msg_reply       = NULL;
        int              retval               = -1;

        dbus_error_init(&dbus_err);

        dbus_msg_call = dbus_message_new_method_call("org.puavo.Conf1",
                                                     "/org/puavo/Conf1",
                                                     "org.puavo.Conf1",
                                                     "Add");
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

        if (!dbus_message_iter_append_basic(&dbus_msg_call_args,
                                            DBUS_TYPE_STRING,
                                            &value)) {
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

        retval = 0;
out:
        if (dbus_msg_reply)
                dbus_message_unref(dbus_msg_reply);

        if (dbus_msg_call)
                dbus_message_unref(dbus_msg_call);

        return retval;
}

int puavo_conf_dbus_clear(struct puavo_conf *const conf,
                          struct puavo_conf_err *const errp)
{
        DBusError        dbus_err;
        DBusMessage     *dbus_msg_call        = NULL;
        DBusMessage     *dbus_msg_reply       = NULL;
        int              retval               = -1;

        dbus_error_init(&dbus_err);

        dbus_msg_call = dbus_message_new_method_call("org.puavo.Conf1",
                                                     "/org/puavo/Conf1",
                                                     "org.puavo.Conf1",
                                                     "Clear");
        if (!dbus_msg_call) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Failed to create a method call message");
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

        retval = 0;
out:
        if (dbus_msg_reply)
                dbus_message_unref(dbus_msg_reply);

        if (dbus_msg_call)
                dbus_message_unref(dbus_msg_call);

        return retval;
}

int puavo_conf_dbus_close(struct puavo_conf *const conf,
                          struct puavo_conf_err *const errp  __attribute__ ((unused)))
{
        dbus_connection_unref(conf->dbus_conn);
        conf->dbus_conn = NULL;

        return 0;
}

int puavo_conf_dbus_get(struct puavo_conf *const conf,
                        char const *const key,
                        char **const valuep,
                        struct puavo_conf_err *const errp)
{
        char            *value;
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

        if (DBUS_TYPE_STRING !=
            dbus_message_iter_get_arg_type(&dbus_msg_reply_args)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with wrong type");
                goto out;
        }
        dbus_message_iter_get_basic(&dbus_msg_reply_args, &value);

        if ((*valuep = strdup(value)) == NULL) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to duplicate a string");
                goto out;
        }

        if (dbus_message_iter_next(&dbus_msg_reply_args)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with too many "
                                   "arguments");
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

int puavo_conf_dbus_get_all(struct puavo_conf *const conf,
                            struct puavo_conf_list *const list,
                            struct puavo_conf_err *const errp)
{
        DBusError         dbus_err;
        DBusMessage      *dbus_msg_call        = NULL;
        DBusMessage      *dbus_msg_reply       = NULL;
        DBusMessageIter   dbus_msg_reply_args;
        DBusMessageIter   dbus_msg_iter_array;
        int               retval               = -1;
        size_t            keys_count           = 0;
        size_t            values_count         = 0;

        dbus_error_init(&dbus_err);

        dbus_msg_call = dbus_message_new_method_call("org.puavo.Conf1",
                                                     "/org/puavo/Conf1",
                                                     "org.puavo.Conf1",
                                                     "GetAll");
        if (!dbus_msg_call) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Failed to create a method call message");
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

        if (DBUS_TYPE_UINT64 !=
            dbus_message_iter_get_arg_type(&dbus_msg_reply_args)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with wrong type");
                goto out;
        }
        dbus_message_iter_get_basic(&dbus_msg_reply_args, &list->length);

        list->keys = malloc(sizeof(char *) * list->length);
        if (!list->keys) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to allocate memory");
                goto out;
        }

        list->values = malloc(sizeof(char *) * list->length);
        if (!list->values) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                   "Failed to allocate memory");
                goto out;
        }

        if (!dbus_message_iter_next(&dbus_msg_reply_args)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with missing "
                                   "arguments");
                goto out;
        }

        if (DBUS_TYPE_ARRAY !=
            dbus_message_iter_get_arg_type(&dbus_msg_reply_args)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with wrong type");
                goto out;
        }

        dbus_message_iter_recurse(&dbus_msg_reply_args, &dbus_msg_iter_array);

        while (dbus_message_iter_get_arg_type(&dbus_msg_iter_array) != DBUS_TYPE_INVALID) {
                char *key;
                if (DBUS_TYPE_STRING !=
                    dbus_message_iter_get_arg_type(&dbus_msg_iter_array)) {
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                           "Received invalid reply with wrong type");
                        goto out;
                }
                dbus_message_iter_get_basic(&dbus_msg_iter_array, &key);

                if (keys_count >= list->length) {
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                           "Received invalid reply with wrong "
                                           "number of keys");
                        goto out;
                }

                if ((list->keys[keys_count] = strdup(key)) == NULL) {
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                           "Failed to duplicate a string");
                        goto out;
                }
                ++keys_count;

                dbus_message_iter_next(&dbus_msg_iter_array);
        }

        if (!dbus_message_iter_next(&dbus_msg_reply_args)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with missing "
                                   "arguments");
                goto out;
        }

        if (DBUS_TYPE_ARRAY !=
            dbus_message_iter_get_arg_type(&dbus_msg_reply_args)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with wrong type");
                goto out;
        }

        dbus_message_iter_recurse(&dbus_msg_reply_args, &dbus_msg_iter_array);

        while (dbus_message_iter_get_arg_type(&dbus_msg_iter_array) != DBUS_TYPE_INVALID) {
                char *value;
                if (DBUS_TYPE_STRING !=
                    dbus_message_iter_get_arg_type(&dbus_msg_iter_array)) {
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                           "Received invalid reply with wrong type");
                        goto out;
                }
                dbus_message_iter_get_basic(&dbus_msg_iter_array, &value);

                if (values_count >= list->length) {
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                           "Received invalid reply with wrong "
                                           "number of values");
                        goto out;
                }

                if ((list->values[values_count] = strdup(value)) == NULL) {
                        puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_SYS, 0,
                                           "Failed to duplicate a string");
                        goto out;
                }
                ++values_count;

                dbus_message_iter_next(&dbus_msg_iter_array);
        }

        if (dbus_message_iter_next(&dbus_msg_reply_args)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with too many "
                                   "arguments");
                goto out;
        }

        retval = 0;
out:
        if (retval) {
                if (list->keys) {
                        size_t i;
                        for (i = 0; i < keys_count; ++i) {
                                free(list->keys[i]);
                        }
                        free(list->keys);
                        list->keys = NULL;
                }
                if (list->values) {
                        size_t i;
                        for (i = 0; i < values_count; ++i) {
                                free(list->values[i]);
                        }
                        free(list->values);
                        list->values = NULL;
                }
        }

        if (dbus_msg_reply)
                dbus_message_unref(dbus_msg_reply);

        if (dbus_msg_call)
                dbus_message_unref(dbus_msg_call);

        return retval;
}

int puavo_conf_dbus_has_key(struct puavo_conf *const conf,
                            char const *const key,
                            bool *const haskey,
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
                                                     "HasKey");
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

        if (DBUS_TYPE_BOOLEAN !=
            dbus_message_iter_get_arg_type(&dbus_msg_reply_args)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with wrong type");
                goto out;
        }
        dbus_message_iter_get_basic(&dbus_msg_reply_args, haskey);

        if (dbus_message_iter_next(&dbus_msg_reply_args)) {
                puavo_conf_err_set(errp, PUAVO_CONF_ERRNUM_DBUS, 0,
                                   "Received invalid reply with too many "
                                   "arguments");
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

int puavo_conf_dbus_open(struct puavo_conf *const conf,
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

int puavo_conf_dbus_overwrite(struct puavo_conf *const conf,
                              char const *const key,
                              char const *const value,
                              struct puavo_conf_err *const errp)
{
        DBusError        dbus_err;
        DBusMessage     *dbus_msg_call        = NULL;
        DBusMessageIter  dbus_msg_call_args;
        DBusMessage     *dbus_msg_reply       = NULL;
        int              retval               = -1;

        dbus_error_init(&dbus_err);

        dbus_msg_call = dbus_message_new_method_call("org.puavo.Conf1",
                                                     "/org/puavo/Conf1",
                                                     "org.puavo.Conf1",
                                                     "Overwrite");
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

        if (!dbus_message_iter_append_basic(&dbus_msg_call_args,
                                            DBUS_TYPE_STRING,
                                            &value)) {
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

        retval = 0;
out:
        if (dbus_msg_reply)
                dbus_message_unref(dbus_msg_reply);

        if (dbus_msg_call)
                dbus_message_unref(dbus_msg_call);

        return retval;
}

int puavo_conf_dbus_set(struct puavo_conf *const conf,
                        char const *const key,
                        char const *const value,
                        struct puavo_conf_err *const errp)
{
        DBusError        dbus_err;
        DBusMessage     *dbus_msg_call        = NULL;
        DBusMessageIter  dbus_msg_call_args;
        DBusMessage     *dbus_msg_reply       = NULL;
        int              retval               = -1;

        dbus_error_init(&dbus_err);

        dbus_msg_call = dbus_message_new_method_call("org.puavo.Conf1",
                                                     "/org/puavo/Conf1",
                                                     "org.puavo.Conf1",
                                                     "Set");
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

        if (!dbus_message_iter_append_basic(&dbus_msg_call_args,
                                            DBUS_TYPE_STRING,
                                            &value)) {
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

        retval = 0;
out:
        if (dbus_msg_reply)
                dbus_message_unref(dbus_msg_reply);

        if (dbus_msg_call)
                dbus_message_unref(dbus_msg_call);

        return retval;
}
