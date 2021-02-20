/*
* Copyright © 2020–2021 Cassidy James Blaede (https://cassidyjames.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Cassidy James Blaede <c@ssidyjam.es>
*/

public class Plausible.App : Gtk.Application {
    public string domain = "plausible.io";
    public static GLib.Settings settings;

    public App () {
        Object (
            application_id: "com.cassidyjames.plausible"
        );
    }

    public static App _instance = null;
    public static App instance {
        get {
            if (_instance == null) {
                _instance = new App ();
            }
            return _instance;
        }
    }

    static construct {
        settings = new Settings (App.instance.application_id);
    }

    protected override void activate () {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/cassidyjames/plausible/App.css");
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        var app_window = new MainWindow (this);
        app_window.show_all ();

        var quit_action = new SimpleAction ("quit", null);
        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Ctrl>Q"});

        Gtk.Settings.get_default().set_property("gtk-icon-theme-name", "elementary");
        Gtk.Settings.get_default().set_property("gtk-theme-name", "elementary");

        quit_action.activate.connect (() => {
            quit ();
        });
    }

    public static int main (string[] args) {
        var app = new App ();
        return app.run (args);
    }
}
