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

#ifndef PUAVO_CONF_DBUS_H
#define PUAVO_CONF_DBUS_H

#include "common.h"

int puavo_conf_dbus_add(struct puavo_conf *conf, char const *key,
                        char const *value, struct puavo_conf_err *errp);

int puavo_conf_dbus_clear(struct puavo_conf *conf, struct puavo_conf_err *errp);

int puavo_conf_dbus_close(struct puavo_conf *conf, struct puavo_conf_err *errp);

int puavo_conf_dbus_get(struct puavo_conf *conf,
                        char const *key,
                        char **valuep,
                        struct puavo_conf_err *errp);

int puavo_conf_dbus_open(struct puavo_conf *conf, struct puavo_conf_err *errp);

int puavo_conf_dbus_overwrite(struct puavo_conf *conf, char const *key,
                              char const *value, struct puavo_conf_err *errp);

int puavo_conf_dbus_set(struct puavo_conf *conf, char const *key,
                        char const *value, struct puavo_conf_err *errp);


static const struct puavo_conf_ops PUAVO_CONF_OPS_DBUS = {
        .add       = puavo_conf_dbus_add,
        .clear     = puavo_conf_dbus_clear,
        .close     = puavo_conf_dbus_close,
        .get       = puavo_conf_dbus_get,
        .open      = puavo_conf_dbus_open,
        .overwrite = puavo_conf_dbus_overwrite,
        .set       = puavo_conf_dbus_set,
};


#endif /* PUAVO_CONF_DBUS_H */
