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

#include <stdlib.h>
#include <string.h>

#include <db.h>

#include "conf.h"

struct puavo_conf {
        DB *db;
        int db_err;
};

struct puavo_conf *puavo_conf_init()
{
        struct puavo_conf *conf;

        conf = (struct puavo_conf *) malloc(sizeof(struct puavo_conf));
        if (!conf)
                return NULL;
        memset(conf, 0, sizeof(struct puavo_conf));

        return conf;
}

int puavo_conf_open_db(struct puavo_conf *const conf,
                       const char *const db_filepath)
{
        DB *db;
        int db_ret;

        if (conf->db)
                return 0;

        db_ret = db_create(&db, NULL, 0);
        if (db_ret != 0) {
                conf->db_err = db_ret;
                return -1;
        }

        db_ret = db->open(db, NULL, db_filepath, NULL, DB_BTREE, DB_CREATE, 0600);
        if (db_ret != 0) {
                conf->db_err = db_ret;
                db->close(db, 0);
                return -1;
        }

        conf->db = db;
        return 0;
}

int puavo_conf_close_db(struct puavo_conf *const conf)
{
        if (conf->db) {
                int db_ret = conf->db->close(conf->db, 0);
                conf->db = NULL;

                if (db_ret != 0) {
                        conf->db_err = db_ret;
                        return -1;
                }
        }

        return 0;
}

void puavo_conf_free(struct puavo_conf *conf)
{
        free(conf);
}
