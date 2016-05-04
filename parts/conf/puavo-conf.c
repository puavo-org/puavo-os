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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include <getopt.h>
#include <stdio.h>
#include <string.h>

#include "conf.h"

static int list_params(puavo_conf_t *const conf)
{
        size_t i;
        size_t keylen;
        size_t max_keylen = 0;
        int key_field_width;
        struct puavo_conf_list list;
        struct puavo_conf_err err;
        int ret = 1;

        if (puavo_conf_get_all(conf, &list, &err)) {
                (void) fprintf(stderr,
                               "Error: Failed to get parameter list: %s\n",
                               err.msg);
                return 1;
        }

        for (i = 0; i < list.length; i++) {
                keylen = strlen(list.keys[i]);
                max_keylen = (keylen > max_keylen) ? keylen : max_keylen;
        }

        key_field_width = (max_keylen > 80) ? 80 : max_keylen;

        for (i = 0; i < list.length; i++) {
                if (printf("%-*s %s\n",
                           key_field_width + 2,
                           list.keys[i],
                           list.values[i]) < 0) {
                        (void) fprintf(stderr,
                                       "Error: printf failed while listing "
                                       "parameters");
                        goto err;
                }
        }
        ret = 0;
err:
        puavo_conf_list_free(&list);

        return ret;
}

static int get_param(puavo_conf_t *const conf,
                     char const *const key,
                     enum puavo_conf_type const type,
                     char const *const exact_match)
{
        struct puavo_conf_err err;
        char *value;

        if (puavo_conf_get(conf, key, &value, &err)) {
                (void) fprintf(stderr, "Error: Failed to get '%s': %s\n",
                               key, err.msg);
                return 1;
        }

        if (puavo_conf_check_type(value, type, &err)) {
                free(value);
                (void) fprintf(stderr, "Error: Failed to get '%s': %s\n",
                               key, err.msg);
                return 1;
        }

        if (exact_match && strcmp(value, exact_match)) {
                (void) fprintf(stderr,
                               "Error: Value '%s' does not match '%s'\n",
                               value, exact_match);
                free(value);
                return 1;
        }

        if (printf("%s\n", value) < 0) {
                free(value);
                (void) fprintf(stderr,
                               "Error: printf failed while getting "
                               "a parameter");
                return 1;
        }

        free(value);

        return 0;
}

enum set_mode {
        OVERWRITE,
        ADD,
        FORCE
};

static int set_param(puavo_conf_t *const conf,
                     char const *const key,
                     char const *const value,
                     enum puavo_conf_type const type,
                     char const *const exact_match,
                     enum set_mode const set_mode)
{
        struct puavo_conf_err err;

        if (puavo_conf_check_type(value, type, &err)) {
                (void) fprintf(stderr, "Error: Failed to get '%s': %s\n",
                               key, err.msg);
                return 1;
        }

        if (exact_match && strcmp(value, exact_match)) {
                (void) fprintf(stderr,
                               "Error: Value '%s' does not match '%s'\n",
                               value, exact_match);
                return 1;
        }

        switch (set_mode) {
        case OVERWRITE:
                if (puavo_conf_overwrite(conf, key, value, &err) == -1) {
                        (void) fprintf(stderr,
                                       "Error: Failed to overwrite "
                                       "'%s' with value '%s': %s\n",
                                       key, value, err.msg);
                        return 1;
                }
                break;
        case ADD:
                if (puavo_conf_add(conf, key, value, &err) == -1) {
                        (void) fprintf(stderr, "Error: Failed to add "
                                       "'%s' with value '%s': %s\n",
                                       key, value, err.msg);
                        return 1;
                }
                break;
        case FORCE:
                if (puavo_conf_set(conf, key, value, &err) == -1) {
                        (void) fprintf(stderr, "Error: Failed to set "
                                       "'%s' to '%s': %s\n",
                                       key, value, err.msg);
                        return 1;
                }
                break;
        default:
                (void) fprintf(stderr, "Error: Invalid set mode %d\n",
                               set_mode);
                return 1;
        }

        return 0;
}

int print_help(void)
{
        int err;

        err = printf("Usage: puavo-conf [OPTIONS]... [--] [KEY [VALUE]]\n"
                     "\n"
                     "Get and set Puavo Configuration parameters.\n"
                     "\n"
                     "Options:\n"
                     "  -b, --type-bool               fail if VALUE is not boolean\n"
                     "  -h, --help                    display this help and exit\n"
                     "  -x STR, --match-exact STR     fail if value does not match STR exactly\n"
                     "  --set-mode MODE               how to set the value, see MODE below\n"
                     "\n"
                     "If both KEY and VALUE are given, set the value of\n"
                     "KEY to VALUE. If only KEY is given, display its\n"
                     "value. If no arguments are given, display all\n"
                     "parameters.\n"
                     "\n"
                     "MODE\n"
                     "  overwrite    overwrite the value but fail if KEY does not exist\n"
                     "  add          add a new parameter but fail if KEY exists\n"
                     "  force        add a new parameter or overwrite if KEY exists\n"
                     "\n"
                     "  If --set-mode is not given, --set-mode=overwrite is implied.\n"
                     "\n");

        if (err < 0)
                return EXIT_FAILURE;

        return EXIT_SUCCESS;
}

int main(int argc, char *argv[])
{
        puavo_conf_t *conf;
        struct puavo_conf_err err;
        int exitval;
        enum puavo_conf_type type = PUAVO_CONF_TYPE_ANY;
        char *exact_match = NULL;
        enum set_mode set_mode = FORCE;

        while (1) {
                int optval;
                static struct option long_options[] = {
                        {"match-exact", required_argument, 0, 'x' },
                        {"type-bool"  , no_argument      , 0, 'b' },
                        {"help"       , no_argument      , 0, 'h' },
                        {"set-mode"   , required_argument, 0, 's' },
                        {0            , 0                , 0, 0   }
                };

                optval = getopt_long(argc, argv, "bhx:", long_options, NULL);

                if (optval == -1)
                        break;

                switch (optval) {
                case 'b':
                        type = PUAVO_CONF_TYPE_BOOL;
                        break;

                case 'h':
                        return print_help();

                case 'x':
                        exact_match = optarg;
                        break;

                case 's':
                        if (!strcmp("overwrite", optarg)) {
                                set_mode = OVERWRITE;
                        } else if (!strcmp("add", optarg)) {
                                set_mode = ADD;
                        } else if (!strcmp("force", optarg)) {
                                set_mode = FORCE;
                        } else {
                                (void) fprintf(stderr,
                                               "Error: Invalid MODE '%s', "
                                               "expected 'overwrite', 'add' or "
                                               "'force'.\n", optarg);
                                return EXIT_FAILURE;
                        }
                        break;

                case '?':
                        return EXIT_FAILURE;

                default:
                        (void) fprintf(stderr,
                                       "Error: Unexpected return value from "
                                       "getopt_long(): %d\n", optval);
                        return EXIT_FAILURE;
                }
        }

        if (puavo_conf_open(&conf, &err)) {
                (void) fprintf(stderr,
                               "Error: Failed to open config backend: %s\n",
                               err.msg);
                return EXIT_FAILURE;
        }

        exitval = EXIT_FAILURE;

        switch (argc - optind) {
        case 0:
                if (list_params(conf))
                        goto err;
                break;
        case 1:
                if (get_param(conf, argv[argc - 1], type, exact_match))
                        goto err;
                break;
        case 2:
                if (set_param(conf, argv[argc - 2], argv[argc - 1], type,
                              exact_match, set_mode))
                        goto err;
                break;
        default:
                (void) fprintf(stderr,
                               "Error: Invalid number of arguments (%d)\n",
                               argc - optind);
                goto err;
        }
        exitval = EXIT_SUCCESS;
err:
        if (puavo_conf_close(conf, &err) == -1) {
                (void) fprintf(stderr,
                               "Error: Failed to close config backend: %s\n",
                               err.msg);
                exitval = EXIT_FAILURE;
        }

        return exitval;
}
