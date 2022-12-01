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

public class Plausible.MainWindow : Hdy.Window {
    private Plausible.WebView web_view;
    private Gtk.Revealer account_revealer;
    private Gtk.Stack account_stack;
    private Gtk.Revealer sites_revealer;
    private uint configure_id;

    private const string PURPLE = "#5850ec";

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            border_width: 0,
            icon_name: App.instance.application_id,
            resizable: true,
            title: "Plausible",
            window_position: Gtk.WindowPosition.CENTER
        );
    }

    construct {
        Hdy.init ();

        Gdk.RGBA rgba_purple = { 0, 0, 0, 1 };
        rgba_purple.parse (PURPLE);

        Granite.Widgets.Utils.set_color_primary (this, rgba_purple);

        var sites_button = new Gtk.Button.with_label ("Sites") {
            valign = Gtk.Align.CENTER
        };
        sites_button.get_style_context ().add_class ("back-button");

        sites_revealer = new Gtk.Revealer () {
            transition_duration = Granite.TRANSITION_DURATION_CLOSE,
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT
        };
        sites_revealer.add (sites_button);

        var account_button = new Gtk.Button.from_icon_name ("avatar-default", Gtk.IconSize.LARGE_TOOLBAR) {
            tooltip_text = "Account Settings"
        };

        var logout_button = new Gtk.Button.from_icon_name ("system-log-out", Gtk.IconSize.LARGE_TOOLBAR) {
            tooltip_text = "Log Out"
        };

        account_stack = new Gtk.Stack () {
            transition_duration = Granite.TRANSITION_DURATION_CLOSE,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        account_stack.add_named (account_button, "account");
        account_stack.add_named (logout_button, "logout");

        account_revealer = new Gtk.Revealer () {
            transition_duration = Granite.TRANSITION_DURATION_CLOSE,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };
        account_revealer.add (account_stack);

        var header = new Hdy.HeaderBar () {
            has_subtitle = false,
            show_close_button = true,
            title = "Plausible"
        };
        header.pack_start (sites_revealer);
        header.pack_end (account_revealer);

        web_view = new Plausible.WebView ();

        string domain = App.settings.get_string ("domain");
        string current_url = App.settings.get_string ("current-url");
        if (current_url != "") {
            web_view.load_uri (current_url);
        } else {
            web_view.load_uri ("https://" + domain + "/sites");
        }

        var logo = new Gtk.Image.from_resource ("/com/cassidyjames/plausible/logo-dark.png") {
            expand = true,
            margin_bottom = 48
        };

        var stack = new Gtk.Stack () {
            // Half speed since it's such a huge distance
            transition_duration = Granite.TRANSITION_DURATION_CLOSE * 2,
            transition_type = Gtk.StackTransitionType.UNDER_UP
        };
        stack.get_style_context ().add_class ("loading");
        stack.add_named (logo, "loading");
        stack.add_named (web_view, "web");

        var grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        grid.add (header);
        grid.add (stack);

        add (grid);

        int window_x, window_y;
        int window_width, window_height;
        App.settings.get ("window-position", "(ii)", out window_x, out window_y);
        App.settings.get ("window-size", "(ii)", out window_width, out window_height);

        if (window_x != -1 || window_y != -1) {
            move (window_x, window_y);
        }

        resize (window_width, window_height);

        if (App.settings.get_boolean ("window-maximized")) {
            maximize ();
        }

        web_view.load_changed.connect ((load_event) => {
            if (load_event == WebKit.LoadEvent.FINISHED) {
                stack.visible_child_name = "web";
            }
        });

        sites_button.clicked.connect (() => {
            web_view.load_uri ("https://" + domain + "/sites");
        });

        account_button.clicked.connect (() => {
            web_view.load_uri ("https://" + domain + "/settings");
        });

        logout_button.clicked.connect (() => {
            // NOTE: Plausible expects a POST not just loading the URL
            // https://github.com/plausible/analytics/issues/730
            // web_view.load_uri ("https://" + domain + "/logout");

            web_view.get_website_data_manager ().clear.begin (
                WebKit.WebsiteDataTypes.COOKIES,
                0,
                null,
                () => {
                    debug ("Cleared cookies; going home.");
                    web_view.load_uri ("https://" + domain + "/sites");
                }
            );
        });

        web_view.load_changed.connect (on_loading);
        web_view.notify["uri"].connect (on_loading);
        web_view.notify["estimated-load-progress"].connect (on_loading);
        web_view.notify["is-loading"].connect (on_loading);

        App.settings.bind ("zoom", web_view, "zoom-level", SettingsBindFlags.DEFAULT);

        var accel_group = new Gtk.AccelGroup ();

        accel_group.connect (
            Gdk.Key.plus,
            Gdk.ModifierType.CONTROL_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                zoom_in ();
                return true;
            }
        );

        accel_group.connect (
            Gdk.Key.equal,
            Gdk.ModifierType.CONTROL_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                zoom_in ();
                return true;
            }
        );

        accel_group.connect (
            Gdk.Key.minus,
            Gdk.ModifierType.CONTROL_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                zoom_out ();
                return true;
            }
        );

        accel_group.connect (
            Gdk.Key.@0,
            Gdk.ModifierType.CONTROL_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                zoom_default ();
                return true;
            }
        );

        add_accel_group (accel_group);
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id == 0) {
            /* Avoid spamming the settings */
            configure_id = Timeout.add (200, () => {
                configure_id = 0;

                if (is_maximized) {
                    App.settings.set_boolean ("window-maximized", true);
                } else {
                    App.settings.set_boolean ("window-maximized", false);

                    int width, height;
                    get_size (out width, out height);
                    App.settings.set ("window-size", "(ii)", width, height);

                    int root_x, root_y;
                    get_position (out root_x, out root_y);
                    App.settings.set ("window-position", "(ii)", root_x, root_y);
                }

                return GLib.Source.REMOVE;
            });
        }

        return base.configure_event (event);
    }

    private void on_loading () {
        // Only do anything once we're done loading
        if (! web_view.is_loading) {
            string domain = App.settings.get_string ("domain");
            sites_revealer.reveal_child = (
                web_view.uri != "https://" + domain + "/login" &&
                web_view.uri != "https://" + domain + "/register" &&
                web_view.uri != "https://" + domain + "/password/request-reset" &&
                web_view.uri != "https://" + domain + "/sites"
            );

            account_revealer.reveal_child = (
                web_view.uri != "https://" + domain + "/login" &&
                web_view.uri != "https://" + domain + "/register" &&
                web_view.uri != "https://" + domain + "/password/request-reset"
            );

            if (web_view.uri == "https://" + domain + "/settings") {
                account_stack.visible_child_name = "logout";
            } else {
                account_stack.visible_child_name = "account";
            }

            App.settings.set_string ("current-url", web_view.uri);
        }
    }

    private void zoom_in () {
        if (web_view.zoom_level < 5.0) {
            web_view.zoom_level = web_view.zoom_level + 0.1;
        } else {
            Gdk.beep ();
        }

        return;
    }

    private void zoom_out () {
        if (web_view.zoom_level > 0.2) {
            web_view.zoom_level = web_view.zoom_level - 0.1;
        } else {
            Gdk.beep ();
        }

        return;
    }

    private void zoom_default () {
        if (web_view.zoom_level != 1.0) {
            web_view.zoom_level = 1.0;
        } else {
            Gdk.beep ();
        }

        return;
    }
}
