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

#include <stdio.h>
#include <stdlib.h>

#include "conf.h"

int main(int argc, char *argv[])
{
        puavo_conf_t *conf;
        char *returned_value;
        int ret;

        if (puavo_conf_init(&conf)) {
                (void) fprintf(stderr, "could not init puavo-conf\n");
                return 1;
        }

        if (puavo_conf_open_db(conf, NULL)) {
                (void) fprintf(stderr, "could not open puavo-conf database\n");
                puavo_conf_free(conf);
                return 1;
        }

        if (argc == 2) {
                if (puavo_conf_get(conf, argv[1], &returned_value)) {
                        (void) fprintf(stderr,
                                       "error retrieving '%s'\n",
                                       argv[1]);
                        (void) puavo_conf_close_db(conf);
                        puavo_conf_free(conf);
                        return 1;
                }
                ret = printf("%s\n", returned_value);
                free(returned_value);
                if (ret < 0)
                        return 1;
        } else if (argc == 3) {
                if (puavo_conf_set(conf, argv[1], argv[2]) == -1) {
                        (void) fprintf(stderr,
                                       "error setting '%s' to '%s'\n",
                                       argv[1],
                                       argv[2]);
                        (void) puavo_conf_close_db(conf);
                        puavo_conf_free(conf);
                        return 1;
                }
        } else {
                (void) fprintf(stderr, "usage: puavo-conf key [value]\n");
                return 1;
        }

        if (puavo_conf_close_db(conf) == -1)
                (void) fprintf(stderr, "error closing puavo-conf database\n");

        puavo_conf_free(conf);

        return 0;
}
