/*
thumb v0.1
Image thumbnailing using GNOME's services

Copyright (C) 2017 Opinsys Oy

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

Author: Jarmo Pietiläinen <jarmo@opinsys.fi>

gcc -s -O2 -Wall -Wextra -Wpedantic -o thumb thumb.c -std=c99 $(pkg-config --cflags --libs gnome-desktop-3.0)
*/

#include <stdio.h>
#include <string.h>

#include <glib.h>
#include <glib-object.h>
#include <gio/gio.h>
#include <gdk-pixbuf/gdk-pixbuf.h>

#define GNOME_DESKTOP_USE_UNSTABLE_API
#include <libgnome-desktop/gnome-desktop-thumbnail.h>

int main(int argc, char **argv)
{
    if (argc != 2) {
        fputs("Usage: thumb <image file name>\n", stderr);
        fputs("The generated image is saved as $XDG_CACHE_HOME/thumbnails/large/<MD5>.png,\n", stderr);
        fputs("the MD5 checksum is returned; use it to move the file elsewhere. Exit code\n", stderr);
        fputs("is 0 on success, 1 on failure.\n", stderr);
        return 1;
    }

    // always use large thumbnails
    GnomeDesktopThumbnailFactory *factory =
        gnome_desktop_thumbnail_factory_new(GNOME_DESKTOP_THUMBNAIL_SIZE_LARGE);

    GFile *f = g_file_new_for_commandline_arg(argv[1]);

    if (!f) {
        fputs("g_file_new_for_commandline_arg() failed\n", stderr);
        g_clear_object(&factory);
        return 1;
    }

    // the fileinfo object is needed for determining the file mtime and mime type
    GError *error = NULL;
    GFileInfo *fi = g_file_query_info(f,
        "standard::content-type,time::modified",
        G_FILE_QUERY_INFO_NONE, NULL, &error);

    if (!fi) {
        fprintf(stderr, "g_file_query_info() failed: %s\n", error->message);
        g_error_free(error);
        g_object_unref(f);
        g_clear_object(&factory);
        return 1;
    }

    gchar *uri = g_file_get_uri(f),
          *mime = g_content_type_get_mime_type(g_file_info_get_content_type(fi));

    GTimeVal mtime;

    g_file_info_get_modification_time(fi, &mtime);

    // of course this check cannot be done earlier
    if (!gnome_desktop_thumbnail_factory_can_thumbnail(factory, uri, mime, mtime.tv_sec)) {
        fputs("This file cannot be thumbnailed\n", stderr);
        g_free(uri);
        g_free(mime);
        g_object_unref(fi);
        g_object_unref(f);
        g_clear_object(&factory);
        return 1;
    }

    GdkPixbuf *thumb = gnome_desktop_thumbnail_factory_generate_thumbnail(factory, uri, mime);

    if (!thumb) {
        fputs("gnome_desktop_thumbnail_factory_generate_thumbnail() failed\n", stderr);
        g_free(uri);
        g_free(mime);
        g_object_unref(fi);
        g_object_unref(f);
        g_clear_object(&factory);
        return 1;
    }

    gnome_desktop_thumbnail_factory_save_thumbnail(factory, thumb, uri, mtime.tv_sec);

    // if you just could specify the actual output directory, that'd be great
    GChecksum *checksum = g_checksum_new(G_CHECKSUM_MD5);

    g_checksum_update(checksum, (const guchar *)uri, strlen(uri));
    printf("%s", g_checksum_get_string(checksum));
    g_checksum_free (checksum);

    g_object_unref(thumb);
    g_free(uri);
    g_free(mime);
    g_object_unref(fi);
    g_object_unref(f);
    g_clear_object(&factory);

    return 0;
}
