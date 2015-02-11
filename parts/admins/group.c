/* puavoadmins
 * Copyright (C) 2014, 2015 Opinsys
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

/* Standard library includes. */
#include <errno.h>
#include <string.h>
#include <nss.h>
#include <pwd.h>
#include <grp.h>
#include <sys/types.h>

/* Local includes. */
#include "common.h"
#include "orgjson.h"

static int g_ent_index;

enum nss_status _nss_puavoadmins_setgrent(void)
{
        g_ent_index = 0;

        return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_puavoadmins_endgrent(void)
{
        /* There is not any global resources to be freed. We always
         * return just one group, so everything is allocated and freed
         * locally in _nss_puavoadmins_getgrent_r(). */

        return NSS_STATUS_SUCCESS;
}

static enum nss_status fill_group_members(const orgjson_t *const orgjson,
                                          struct group *const gr,
                                          char *const buf,
                                          const size_t bufsize,
                                          int *const errnop)
{
        char **members;
        char *member;
        size_t member_count;

        /* Here we treat the given buffer as a storage for members, so
         * it is going to be used as a string array. Strings will be
         * copied to the tail of the buffer and string pointers to the
         * head of the buffer. The anatomy of string arrays. */
        memset(buf, 0, bufsize);
        member_count = orgjson_get_owner_count(orgjson);
        members = (char **) buf;
        member = buf + sizeof(char *) * (member_count + 1);

        for (size_t i = 0; i < member_count; ++i) {
                struct orgjson_owner owner;
                struct orgjson_error error;
                size_t member_size;

                if (!orgjson_get_owner(orgjson, i, &owner, &error)) {
                        log(LOG_ERR, "failed to get puavoadmins group entry "
                            "by index %zd: %s", i, error.text);
                        *errnop = EINVAL;
                        return NSS_STATUS_UNAVAIL;
                }

                member_size = strlen(owner.username) + 1;
                if (member + member_size > buf + bufsize) {
                        /* Too small buffer to hold the member. The
                         * caller must provide bigger one. */
                        *errnop = ERANGE;
                        return NSS_STATUS_TRYAGAIN;
                }
                members[i] = strcpy(member, owner.username);
                member += member_size;
        }

        gr->gr_mem = members;

        return NSS_STATUS_SUCCESS;
}

static enum nss_status fill_group(struct group *const gr,
                                  char *const buf,
                                  const size_t bufsize,
                                  int *const errnop)
{
        enum nss_status retval;
        orgjson_t *orgjson;
        struct orgjson_error error;

        gr->gr_name = PUAVOADMINS_GRNAM;
        gr->gr_passwd = "x";
        gr->gr_gid = PUAVOADMINS_GRGID;

        /* If the orgjson does not exist, puavoadmins is empty. */
        if (!orgjson_exists()) {
                memset(buf, 0, bufsize);
                gr->gr_mem = (char **) buf;
                return NSS_STATUS_SUCCESS;
        }

        orgjson = orgjson_load(&error);
        if (!orgjson) {
                log(LOG_ERR, "failed to load puavoadmins group database: %s",
                    error.text);
                *errnop = errno;
                return NSS_STATUS_UNAVAIL;
        }

        retval = fill_group_members(orgjson, gr, buf, bufsize, errnop);

        orgjson_free(orgjson);
        orgjson = NULL;

        return retval;
}

enum nss_status _nss_puavoadmins_getgrent_r(struct group *const gr,
                                            char *const buf,
                                            const size_t bufsize,
                                            int *const errnop)
{
        enum nss_status retval;

        if (g_ent_index > 0) {
                /* Currenly, there is only one puavoadmins group. */
                *errnop = ENOENT;
                return NSS_STATUS_NOTFOUND;
        }

        retval = fill_group(gr, buf, bufsize, errnop);
        if (retval == NSS_STATUS_SUCCESS)
                ++g_ent_index;

        return retval;
}

enum nss_status _nss_puavoadmins_getgrnam_r(const char *const name,
                                            struct group *const gr,
                                            char *const buf,
                                            const size_t bufsize,
                                            int *const errnop)
{
        if (strcmp(name, PUAVOADMINS_GRNAM)) {
                *errnop = ENOENT;
                return NSS_STATUS_NOTFOUND;
        }

        return fill_group(gr, buf, bufsize, errnop);
}

enum nss_status _nss_puavoadmins_getgrgid_r(const gid_t gid,
                                            struct group *const gr,
                                            char *const buf,
                                            const size_t bufsize,
                                            int *const errnop)
{
        if (gid != PUAVOADMINS_GRGID) {
                *errnop = ENOENT;
                return NSS_STATUS_NOTFOUND;
        }

        return fill_group(gr, buf, bufsize, errnop);
}
