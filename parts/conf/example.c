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

#include "conf.h"

int main(void)
{
        puavo_conf_t *conf;
        char *background;
        char *tx_power;

        if (puavo_conf_init(&conf))
                return 1;

        if (puavo_conf_open_db(conf, "parameters.db")) {
                puavo_conf_free(conf);
                return 1;
        }

        if (puavo_conf_set(conf, "lightdm.background",
                           "/usr/share/backgrounds/space-03.jpg") != 0) {
                puavo_conf_close_db(conf);
                puavo_conf_free(conf);
                return 1;
        }

        if (puavo_conf_set(conf, "wlanap.tx.power", "20") != 0) {
                puavo_conf_close_db(conf);
                puavo_conf_free(conf);
                return 1;
        }

        if (puavo_conf_get(conf, "lightdm.background", &background) != 0) {
                puavo_conf_close_db(conf);
                puavo_conf_free(conf);
                return 1;
        }
        printf("lightdm.background: %s\n", background);

        if (puavo_conf_get(conf, "wlanap.tx.power", &tx_power) != 0) {
                puavo_conf_close_db(conf);
                puavo_conf_free(conf);
                return 1;
        }
        printf("wlanap.tx.power: %s\n", tx_power);

        if (puavo_conf_close_db(conf)) {
                puavo_conf_free(conf);
                return 1;
        }

        puavo_conf_free(conf);

        return 0;
}
