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

#include <errno.h>
#include <string.h>

#include "common.h"

void puavo_conf_err_set(struct puavo_conf_err *const errp,
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
        case PUAVO_CONF_ERRNUM_SUCCESS:
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
        case PUAVO_CONF_ERRNUM_KEYFOUND:
                snprintf(errp->msg, sizeof(errp->msg),
                         "%s: Key already exists", msg ? msg : "");
                break;
        case PUAVO_CONF_ERRNUM_KEYNOTFOUND:
                snprintf(errp->msg, sizeof(errp->msg),
                         "%s: Key does not exist", msg ? msg : "");
                break;
        case PUAVO_CONF_ERRNUM_TYPE:
                snprintf(errp->msg, sizeof(errp->msg),
                         "%s: Invalid type", msg ? msg : "");
                break;
        case PUAVO_CONF_ERRNUM_DBUS:
                snprintf(errp->msg, sizeof(errp->msg),
                         "DBus error: %s", msg ? msg : "");
                break;
        default:
                snprintf(errp->msg, sizeof(errp->msg),
                         "Unknown error %d: %s",
                         errp->errnum, msg ? msg : "");
                break;
        }

        free(msg);
}
