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

#ifndef COMMON_H
#define COMMON_H

#include <db.h>
#include <dbus/dbus.h>

#include "conf.h"

struct puavo_conf_ops {
        int (*add)       (struct puavo_conf *, char const *,
                          char const *, struct puavo_conf_err *);
        int (*clear)     (struct puavo_conf *, struct puavo_conf_err *);
        int (*close)     (struct puavo_conf *, struct puavo_conf_err *);
        int (*get)       (struct puavo_conf *, char const *, char **,
                          struct puavo_conf_err *);
        int (*get_all)   (struct puavo_conf *, struct puavo_conf_list *,
                          struct puavo_conf_err *);
        int (*has_key)   (struct puavo_conf *, char const *, bool *,
                          struct puavo_conf_err *);
        int (*open)      (struct puavo_conf *, struct puavo_conf_err *);
        int (*overwrite) (struct puavo_conf *, char const *,
                          char const *, struct puavo_conf_err *);
        int (*set)       (struct puavo_conf *, char const *,
                          char const *, struct puavo_conf_err *);
};

struct puavo_conf {
        DB *db;
        DBusConnection *dbus_conn;
        int lock_fd;
        struct puavo_conf_ops const *ops;
};


void puavo_conf_err_set(struct puavo_conf_err *errp, int errnum, int db_error, 
                        char const *fmt, ...);

#endif /* COMMON_H */
