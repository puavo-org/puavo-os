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

        if (argc != 2) {
                fprintf(stderr, "ERROR: invalid number of arguments, "
                        "expetected 1, got %d\n", argc - 1);
                return 1;
        }

        orgjson = orgjson_load2(argv[1], &error);
        if (!orgjson) {
                fprintf(stderr, "ERROR: invalid orgjson %s: %s\n",
                        argv[1], error.text);
                return 1;
        }

        orgjson_free(orgjson);
        orgjson = NULL;

        return 0;
}
