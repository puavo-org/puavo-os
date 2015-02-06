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

/* Standard libarary includes. */
#include <stdio.h>
#include <string.h>

/* Local includes. */
#include "orgjson.h"

int main(const int argc, const char *const *const argv)
{
        orgjson_t *orgjson;
        struct orgjson_error error;
        int retval;

        if (argc != 2) {
                fprintf(stderr, "ERROR: invalid number of arguments, "
                        "expetected 1, got %d\n", argc - 1);
                return 1;
        }

        orgjson = orgjson_load(&error);
        if (!orgjson) {
                fprintf(stderr, "ERROR: failed to load puavoadmin database: %s\n",
                        error.text);
                return 1;
        }

        for (size_t i = 0; i < orgjson_get_owner_count(orgjson); ++i) {
                struct orgjson_owner owner;

                if (!orgjson_get_owner(orgjson, i, &owner, &error)) {
                        fprintf(stderr, "ERROR: failed to get entry from "
                                "puavoadmin database by id %zd: %s\n",
                                i, error.text);
                        retval = 1;
                        goto out;
                }

                if (!strcmp(owner.username, argv[1])) {
                        if (owner.ssh_public_key)
                                printf("%s\n", owner.ssh_public_key);
                        retval = 0;
                        goto out;
                }
        }

        fprintf(stderr, "ERROR: Puavo administrator '%s' not found\n", argv[1]);
        retval = 1;

out:

        orgjson_free(orgjson);
        orgjson = NULL;

        return retval;
}
