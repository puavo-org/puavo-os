#include <err.h>
#include <stdlib.h>

#define GNOME_DESKTOP_USE_UNSTABLE_API
#include <libgnome-desktop/gnome-rr.h>
#include <libgnome-desktop/gnome-rr-config.h>

/*
 * The idea here is partially copied from
 * unity-control-center/panels/display/cc-display-panel.c
 * (ensure_current_configuration_is_saved()).
 */

int
main(void)
{
  GnomeRRScreen *rr_screen;
  GnomeRRConfig *rr_config;
  GdkDisplay *gdk_display;
  GdkScreen *gdk_screen;
  char *default_display;

  default_display = getenv("DISPLAY");
  if (!default_display)
    errx(1, "Could not get the DISPLAY environment variable");

  gdk_display = gdk_display_open(default_display);
  if (!gdk_display)
    errx(1, "Could not get the gdk display");

  gdk_screen = gdk_display_get_default_screen(gdk_display);
  if (!gdk_screen)
    errx(1, "Could not get the gdk screen");

  rr_screen = gnome_rr_screen_new(gdk_screen, NULL); /* NULL-GError */
  if (!rr_screen)
    errx(1, "Could not create gnome screen object");

  rr_config = gnome_rr_config_new_current(rr_screen, NULL);
  gnome_rr_config_ensure_primary(rr_config);
  if (!gnome_rr_config_save(rr_config, NULL)) /* NULL-GError */
    errx(1, "Could not save monitors.xml");

  g_object_unref(rr_config);
  g_object_unref(rr_screen);

  return 0;
}
