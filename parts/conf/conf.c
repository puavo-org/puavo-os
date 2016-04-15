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
#include <string.h>

#include "common.h"
#include "db.h"
#include "dbus.h"

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

int puavo_conf_close(struct puavo_conf *const conf,
                     struct puavo_conf_err *const errp)
{
        int ret;

        ret = conf->ops->close(conf, errp);
        free(conf);

        return ret;
}

int puavo_conf_get(struct puavo_conf *const conf,
                   char const *const key,
                   char **const valuep,
                   struct puavo_conf_err *const errp)
{
        return conf->ops->get(conf, key, valuep, errp);
}

int puavo_conf_set(struct puavo_conf *const conf,
                   char const *const key,
                   char const *const value,
                   struct puavo_conf_err *const errp)
{
        return conf->ops->set(conf, key, value, errp);
}

int puavo_conf_overwrite(struct puavo_conf *const conf,
                         char const *const key,
                         char const *const value,
                         struct puavo_conf_err *const errp)
{
        return conf->ops->overwrite(conf, key, value, errp);
}

int puavo_conf_add(struct puavo_conf *const conf,
                   char const *const key,
                   char const *const value,
                   struct puavo_conf_err *const errp)
{
        return conf->ops->add(conf, key, value, errp);
}

int puavo_conf_has_key(struct puavo_conf *const conf,
                       char const *const key,
                       bool *const haskey,
                       struct puavo_conf_err *const errp)
{
        return conf->ops->has_key(conf, key, haskey, errp);
}

int puavo_conf_get_all(struct puavo_conf *const conf,
                       struct puavo_conf_list *const list,
                       struct puavo_conf_err *const errp)
{
        return conf->ops->get_all(conf, list, errp);
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
