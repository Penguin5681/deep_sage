#include <filesystem>
using namespace std;
using namespace std::filesystem;


#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Add this function to your application to debug icon loading issues

void debug_asset_paths(const char* iconFilename) {
    g_print("\n--- DEBUG: Icon Path Information ---\n");

    try {
        std::filesystem::path execPath = std::filesystem::read_symlink("/proc/self/exe");
        g_print("Executable path: %s\n", execPath.c_str());

        std::filesystem::path execDir = execPath.parent_path();
        g_print("Executable directory: %s\n", execDir.c_str());

        std::filesystem::path expectedIconPath = execDir / "data/flutter_assets" / iconFilename;
        g_print("Expected icon path: %s\n", expectedIconPath.c_str());
        g_print("Icon exists: %s\n", std::filesystem::exists(expectedIconPath) ? "YES" : "NO");

        std::filesystem::path assetsDir = execDir / "data/flutter_assets";
        if (std::filesystem::exists(assetsDir) && std::filesystem::is_directory(assetsDir)) {
            g_print("Contents of %s:\n", assetsDir.c_str());
            for (const auto& entry : std::filesystem::directory_iterator(assetsDir)) {
                g_print("  %s\n", entry.path().filename().c_str());
            }

            std::filesystem::path iconDir = assetsDir / "assets/app_icon";
            if (std::filesystem::exists(iconDir) && std::filesystem::is_directory(iconDir)) {
                g_print("Contents of %s:\n", iconDir.c_str());
                for (const auto& entry : std::filesystem::directory_iterator(iconDir)) {
                    g_print("  %s\n", entry.path().filename().c_str());
                }
            } else {
                g_print("Icon directory %s does not exist or is not a directory\n", iconDir.c_str());
            }
        } else {
            g_print("Assets directory %s does not exist or is not a directory\n", assetsDir.c_str());
        }
    } catch (const std::filesystem::filesystem_error& e) {
        g_print("Filesystem error: %s\n", e.what());
    }

    g_print("--- End Debug Info ---\n\n");
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  debug_asset_paths("assets/app_icon/ap_1.png");

  GError* error = NULL;
  std::filesystem::path execDir;
  try {
    execDir = std::filesystem::canonical(std::filesystem::read_symlink("/proc/self/exe")).parent_path();
    std::filesystem::path iconPath = execDir / "data/flutter_assets/assets/app_icon/ap_1.png";

    g_print("Attempting to load icon from: %s\n", iconPath.c_str());

    if (std::filesystem::exists(iconPath)) {
      if (gtk_window_set_icon_from_file(window, iconPath.c_str(), &error)) {
        g_print("Successfully set icon!\n");
      } else {
        g_warning("Failed to set icon: %s", error ? error->message : "unknown error");
        g_clear_error(&error);

        // Try loading with GdkPixbuf as alternative method
        GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(iconPath.c_str(), &error);
        if (pixbuf) {
          gtk_window_set_icon(window, pixbuf);
          g_object_unref(pixbuf);
          g_print("Set icon using GdkPixbuf alternative method\n");
        } else {
          g_warning("GdkPixbuf also failed to load icon: %s",
                   error ? error->message : "unknown error");
          g_clear_error(&error);
        }
      }
    } else {
      g_warning("Icon file does not exist at expected path");
    }
  } catch (const std::filesystem::filesystem_error& e) {
    g_warning("Failed to determine executable path: %s", e.what());
  }

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
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
    gtk_header_bar_set_title(header_bar, "Deep Sage");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Deep Sage");
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
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

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
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
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
