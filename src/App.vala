/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020–2022 Cassidy James Blaede <c@ssidyjam.es>
 */

public class Plausible.App : Adw.Application {
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
        var app_window = new MainWindow (this);
        app_window.show ();

        var quit_action = new SimpleAction ("quit", null);
        var zoom_in_action = new SimpleAction ("zoom-in", null);
        var zoom_out_action = new SimpleAction ("zoom-out", null);
        var zoom_default_action = new SimpleAction ("zoom-default", null);

        add_action (quit_action);
        add_action (zoom_in_action);
        add_action (zoom_out_action);
        add_action (zoom_default_action);

        set_accels_for_action ("app.quit", {"<Ctrl>Q"});
        set_accels_for_action ("app.zoom-in", {"<Ctrl>plus", "<Ctrl>equal"});
        set_accels_for_action ("app.zoom-out", {"<Ctrl>minus"});
        set_accels_for_action ("app.zoom-default", {"<Ctrl>0"});

        quit_action.activate.connect (() => {
            quit ();
        });
        zoom_in_action.activate.connect (app_window.zoom_in);
        zoom_out_action.activate.connect (app_window.zoom_out);
        zoom_default_action.activate.connect (app_window.zoom_default);
    }

    public static int main (string[] args) {
        var app = new App ();
        return app.run (args);
    }
}
