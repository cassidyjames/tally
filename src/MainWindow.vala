/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020–2022 Cassidy James Blaede <c@ssidyjam.es>
 */

public class Plausible.MainWindow : Adw.ApplicationWindow {
    private const GLib.ActionEntry[] ACTION_ENTRIES = {
        { "domain", on_domain_activate },
        { "about", on_about_activate },
    };

    private Plausible.WebView web_view;
    private Gtk.Revealer account_revealer;
    private Gtk.Stack account_stack;
    private Gtk.Revealer sites_revealer;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            icon_name: App.instance.application_id,
            resizable: true,
            title: "Plausible",
            width_request: 360
        );
        add_action_entries (ACTION_ENTRIES, this);
    }

    construct {
        var sites_button = new Gtk.Button.with_label ("Sites") {
            valign = Gtk.Align.CENTER
        };
        sites_button.get_style_context ().add_class ("back-button");

        sites_revealer = new Gtk.Revealer () {
            transition_duration = 200,
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT
        };
        sites_revealer.child = sites_button;

        var account_button = new Gtk.Button.from_icon_name ("avatar-default") {
            tooltip_text = "Account Settings"
        };

        var logout_button = new Gtk.Button.from_icon_name ("system-log-out") {
            tooltip_text = "Log Out"
        };

        account_stack = new Gtk.Stack () {
            transition_duration = 200,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        account_stack.add_named (account_button, "account");
        account_stack.add_named (logout_button, "logout");

        account_revealer = new Gtk.Revealer () {
            transition_duration = 200,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };
        account_revealer.child = account_stack;

        var menu = new Menu ();
        // TODO: Move the above buttons to the menu model and nuke the revealer
        // menu.append ("Account Settings", "account_settings");
        // menu.append ("Log Out", "log_out");
        menu.append (_("Custom Domain…"), "win.domain");
        menu.append (_("About"), "win.about");

        var menu_button = new Gtk.MenuButton () {
            icon_name = "open-menu-symbolic",
            menu_model = menu,
            tooltip_text = _("Menu"),
        };

        var header = new Adw.HeaderBar ();
        header.pack_start (sites_revealer);
        header.pack_end (menu_button);
        header.pack_end (account_revealer);

        web_view = new Plausible.WebView ();

        string domain = App.settings.get_string ("domain");
        string current_url = App.settings.get_string ("current-url");
        if (current_url != "") {
            web_view.load_uri (current_url);
        } else {
            web_view.load_uri ("https://" + domain + "/sites");
        }

        var status_page = new Adw.StatusPage () {
            title = "Plausible",
            /// TRANSLATORS: the string is the domain name, e.g. plausible.io
            description = _("Loading the <b>%s</b> dashboard…").printf (domain),
            icon_name = "icon"
        };

        var stack = new Gtk.Stack () {
            // Half speed since it's such a huge distance
            transition_duration = 400,
            transition_type = Gtk.StackTransitionType.UNDER_UP
        };
        stack.get_style_context ().add_class ("loading");
        stack.add_named (status_page, "loading");
        stack.add_named (web_view, "web");

        var grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        grid.attach (header, 0, 0);
        grid.attach (stack, 0, 1);

        set_content (grid);

        int window_width, window_height;
        App.settings.get ("window-size", "(ii)", out window_width, out window_height);

        set_default_size (window_width, window_height);

        if (App.settings.get_boolean ("window-maximized")) {
            maximize ();
        }

        close_request.connect (() => {
            save_window_state ();
            return Gdk.EVENT_PROPAGATE;
        });
        notify["maximized"].connect (save_window_state);

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
    }

    private void save_window_state () {
        if (maximized) {
            App.settings.set_boolean ("window-maximized", true);
        } else {
            App.settings.set_boolean ("window-maximized", false);
            App.settings.set (
                "window-size", "(ii)",
                get_size (Gtk.Orientation.HORIZONTAL),
                get_size (Gtk.Orientation.VERTICAL)
            );
        }
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

    public void zoom_in () {
        if (web_view.zoom_level < 5.0) {
            web_view.zoom_level = web_view.zoom_level + 0.1;
        } else {
            Gdk.Display.get_default ().beep ();
            warning ("Zoom already max");
        }

        return;
    }

    public void zoom_out () {
        if (web_view.zoom_level > 0.2) {
            web_view.zoom_level = web_view.zoom_level - 0.1;
        } else {
            Gdk.Display.get_default ().beep ();
            warning ("Zoom already min");
        }

        return;
    }

    public void zoom_default () {
        if (web_view.zoom_level != 1.0) {
            web_view.zoom_level = 1.0;
        } else {
            Gdk.Display.get_default ().beep ();
            warning ("Zoom already default");
        }

        return;
    }

    private void on_domain_activate () {
        var domain_label = new Gtk.Label ("https://");
        domain_label.add_css_class ("dim-label");

        var domain_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = "plausible.io"
        };

        var domain_grid = new Gtk.Grid ();
        domain_grid.attach (domain_label, 0, 0);
        domain_grid.attach (domain_entry, 1, 0);

        var domain_dialog = new Adw.MessageDialog (
            this,
            "Set a Custom Domain",
            "If you’re self-hosting Plausible or using an instance other than <b>plausible.io</b>, set the domain name here."
        ) {
            body_use_markup = true,
            default_response = "save",
            extra_child = domain_grid,
        };
        domain_dialog.add_response ("close", "Cancel");
        domain_dialog.add_response ("save", _("Set Domain"));
        domain_dialog.set_response_appearance ("save", Adw.ResponseAppearance.SUGGESTED);

        domain_dialog.present ();
    }

    private void on_about_activate () {
        var about = new Adw.AboutWindow () {
            transient_for = this,
            application_name = "Plausible",
            application_icon = "com.cassidyjames.plausible",
            developer_name = "Cassidy James Blaede",
            version = "2.1.0",
            copyright = "2020–2022 Cassidy James Blaede",
            developers = {"Cassidy James Blaede"},
            issue_url = "https://github.com/cassidyjames/plausible/issues",
            license_type = Gtk.License.GPL_3_0,
        };

        about.present ();
    }
}
