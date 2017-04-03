/*
shutdown_question v0.1
(c) Opinsys Oy 2017

compile with gcc -s -Wall $(pkg-config --cflags --libs gtk+-3.0) -o shutdown-question shutdown-question.c -std=c99
*/

#include <stdio.h>
#include <string.h>
#include <gtk/gtk.h>
//#include <cairo.h>

// The icon displayed on the left side
#define ICON_FILE_NAME  "/usr/share/icons/Faenza/actions/64/gnome-log-out.png"

// The message text. See Pango markup for formatting details.
#define QUESTION_TEXT   "<markup>\n\n<big><big><big><b>Sammutus</b></big></big></big>\n\nValitse mitä haluat tehdä.\n\n</markup>"

// Return values. If these are modified, you must also modify the ask_shutdown_question script.
enum {
    RETURN_VALUE_CANCEL = 0,
    RETURN_VALUE_LOGOUT = 1,
    RETURN_VALUE_POWEROFF = 2,
    RETURN_VALUE_NONE = 255,
};

// -------------------------------------------------------------------------------------------------

static int ret = RETURN_VALUE_NONE;

static void cancel_button(GtkWidget *widget, gpointer data)
{
    ret = RETURN_VALUE_CANCEL;
    gtk_main_quit();
}

static void logout_button(GtkWidget *widget, gpointer data)
{
    ret = RETURN_VALUE_LOGOUT;
    gtk_main_quit();
}

static void shutdown_button(GtkWidget *widget, gpointer data)
{
    ret = RETURN_VALUE_POWEROFF;
    gtk_main_quit();
}

/*
gboolean draw(GtkWidget *widget,
               cairo_t *cr,
               gpointer      user_data)
{
    cairo_set_source_rgb(cr, 255, 255, 255);
    cairo_paint (cr);
    return TRUE;
}
*/

int main(int argc, char *argv[])
{
    if (argc != 2) {
        printf("Usage: shutdown-question <dialog UI filename>\n");
        return -1;
    }

    gtk_init(&argc, &argv);

    GtkBuilder *builder = gtk_builder_new_from_file(argv[1]);

    GObject *window = gtk_builder_get_object(builder, "window");
    gtk_window_set_resizable(GTK_WINDOW(window), FALSE);
    g_signal_connect(window, "destroy", G_CALLBACK (gtk_main_quit), NULL);

    // kill the dialog if focus is lost
    g_signal_connect(window, "focus-out-event", G_CALLBACK (gtk_main_quit), NULL);

    GObject *icon = gtk_builder_get_object(builder, "icon");
    gtk_image_set_from_file(GTK_IMAGE(icon), ICON_FILE_NAME);

    GObject *button;

    button = gtk_builder_get_object(builder, "button1");
    gtk_button_set_label(GTK_BUTTON(button), "Peruuta");
    g_signal_connect(button, "clicked", G_CALLBACK(cancel_button), NULL);
    gtk_widget_show(GTK_WIDGET(button));

    button = gtk_builder_get_object(builder, "button2");
    gtk_button_set_label(GTK_BUTTON(button), "Kirjaudu ulos");
    g_signal_connect(button, "clicked", G_CALLBACK(logout_button), NULL);
    gtk_widget_show(GTK_WIDGET(button));

    button = gtk_builder_get_object(builder, "button3");
    gtk_button_set_label(GTK_BUTTON(button), "Sammuta");
    g_signal_connect(button, "clicked", G_CALLBACK(shutdown_button), NULL);
    //g_signal_connect(window, "draw", G_CALLBACK(draw), NULL);
    gtk_widget_show(GTK_WIDGET(button));

    //GtkStyleContext *ctx = gtk_style_context_new();
    //GtkStyleContext *ctx = gtk_widget_get_style_context(button);

    GObject *msg = gtk_builder_get_object(builder, "message");
    gtk_label_set_markup(GTK_LABEL(msg), QUESTION_TEXT);

    gtk_main();

    return ret;
}
