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
