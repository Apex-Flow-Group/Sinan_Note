#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <glib.h>
#include <stdio.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

// ── Window state persistence ──────────────────────────────────────────────────

static gchar* get_state_path() {
  const gchar* config_dir = g_get_user_config_dir();
  gchar* dir = g_build_filename(config_dir, "sinan_note", nullptr);
  g_mkdir_with_parents(dir, 0755);
  gchar* path = g_build_filename(dir, "window_state.json", nullptr);
  g_free(dir);
  return path;
}

static void save_window_state(GtkWindow* window) {
  if (!window || !gtk_widget_get_realized(GTK_WIDGET(window))) return;

  gboolean maximized = gtk_window_is_maximized(window);
  gint x = 0, y = 0, w = 1280, h = 720;

  gtk_window_get_position(window, &x, &y);
  gtk_window_get_size(window, &w, &h);

  gchar* path = get_state_path();
  FILE* f = fopen(path, "w");
  if (f) {
    fprintf(f, "{\"x\":%d,\"y\":%d,\"w\":%d,\"h\":%d,\"maximized\":%s}\n",
            x, y, w, h, maximized ? "true" : "false");
    fclose(f);
  }
  g_free(path);
}

static gboolean load_window_state(gint* x, gint* y, gint* w, gint* h,
                                   gboolean* maximized) {
  *x = 10; *y = 10; *w = 1280; *h = 720; *maximized = FALSE;

  gchar* path = get_state_path();
  FILE* f = fopen(path, "r");
  g_free(path);
  if (!f) return FALSE;

  int mx = 0, my = 0, mw = 1280, mh = 720, max = 0;
  int parsed = fscanf(f,
    "{\"x\":%d,\"y\":%d,\"w\":%d,\"h\":%d,\"maximized\":%d}",
    &mx, &my, &mw, &mh, &max);
  fclose(f);

  // fscanf won't parse "true"/"false" as int — use fgets fallback
  if (parsed < 4) {
    // re-open and parse manually
    path = get_state_path();
    f = fopen(path, "r");
    g_free(path);
    if (!f) return FALSE;
    char buf[256] = {0};
    if (fgets(buf, sizeof(buf), f)) {
      sscanf(buf,
        "{\"x\":%d,\"y\":%d,\"w\":%d,\"h\":%d",
        &mx, &my, &mw, &mh);
      max = (strstr(buf, "\"maximized\":true") != nullptr) ? 1 : 0;
    }
    fclose(f);
  }

  // Clamp to sane values
  GdkDisplay* display = gdk_display_get_default();
  if (display) {
    GdkMonitor* monitor = gdk_display_get_primary_monitor(display);
    if (monitor) {
      GdkRectangle geom;
      gdk_monitor_get_geometry(monitor, &geom);
      if (mx < geom.x) mx = geom.x;
      if (my < geom.y) my = geom.y;
      if (mx > geom.x + geom.width - 100) mx = geom.x + geom.width / 2 - 640;
      if (my > geom.y + geom.height - 100) my = geom.y + geom.height / 2 - 360;
    }
  }
  if (mw < 400) mw = 400;
  if (mh < 300) mh = 300;

  *x = mx; *y = my; *w = mw; *h = mh;
  *maximized = (max == 1);
  return TRUE;
}

// Called when the window is about to be destroyed — save state
static gboolean on_delete_event(GtkWidget* widget, GdkEvent* event,
                                 gpointer user_data) {
  save_window_state(GTK_WINDOW(widget));
  return FALSE;  // allow normal close
}

// ── Application ───────────────────────────────────────────────────────────────

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Sinan Note");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Sinan Note");
  }

  // Restore saved window state
  gint x, y, w, h;
  gboolean maximized;
  if (load_window_state(&x, &y, &w, &h, &maximized)) {
    gtk_window_set_default_size(window, w, h);
    gtk_window_move(window, x, y);
  } else {
    gtk_window_set_default_size(window, 1280, 720);
  }

  // الحد الأدنى لحجم النافذة: 800x500
  GdkGeometry geometry;
  geometry.min_width = 800;
  geometry.min_height = 500;
  gtk_window_set_geometry_hints(window, nullptr, &geometry, GDK_HINT_MIN_SIZE);

  // Connect delete-event to save state on close
  g_signal_connect(window, "delete-event", G_CALLBACK(on_delete_event), nullptr);

  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));

  if (maximized) {
    gtk_window_maximize(window);
  }
}

static gboolean my_application_local_command_line(GApplication* application,
                                                    gchar*** arguments,
                                                    int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;
  return TRUE;
}

static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
