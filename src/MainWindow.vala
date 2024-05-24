/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020–2024 Cassidy James Blaede <c@ssidyjam.es>
 */

public class Plausible.MainWindow : Adw.ApplicationWindow {
    private const GLib.ActionEntry[] ACTION_ENTRIES = {
        { "account_settings", on_account_settings_activate },
        { "custom_domain", on_custom_domain_activate },
        { "log_out", on_log_out_activate },
        { "about", on_about_activate },
    };

    private Plausible.WebView web_view;
    private Gtk.Revealer sites_revealer;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            height_request: 180,
            icon_name: APP_ID,
            resizable: true,
            title: App.NAME,
            width_request: 360
        );
        add_action_entries (ACTION_ENTRIES, this);
    }

    construct {
        var sites_button = new Gtk.Button.with_label (_("Sites")) {
            valign = Gtk.Align.CENTER
        };
        sites_button.add_css_class ("back-button");

        sites_revealer = new Gtk.Revealer () {
            transition_duration = 200,
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT
        };
        sites_revealer.child = sites_button;

        var site_menu = new Menu ();
        site_menu.append (_("Account _Settings"), "win.account_settings");
        site_menu.append (_("_Log Out…"), "win.log_out");

        var app_menu = new Menu ();
        app_menu.append (_("_Custom Domain…"), "win.custom_domain");
        /// TRANSLATORS: %s is the app name
        app_menu.append (_("_About %s").printf (App.NAME), "win.about");

        var menu = new Menu ();
        menu.append_section (null, site_menu);
        menu.append_section (null, app_menu);

        var menu_button = new Gtk.MenuButton () {
            icon_name = "open-menu-symbolic",
            menu_model = menu,
            tooltip_text = _("Main Menu"),
        };

        var header = new Adw.HeaderBar ();
        header.pack_start (sites_revealer);
        header.pack_end (menu_button);

        web_view = new Plausible.WebView ();

        string domain = App.settings.get_string ("domain");
        string current_url = App.settings.get_string ("current-url");
        if (current_url != "") {
            web_view.load_uri (current_url);
        } else {
            web_view.load_uri ("https://" + domain + "/sites");
        }

        var status_page = new Adw.StatusPage () {
            /// TRANSLATORS: %s is the app name
            title = _("%s for Plausible").printf (App.NAME),
            /// TRANSLATORS: %s is the Plausible instance's domain name
            description = _("Loading the <b>%s</b> dashboard…").printf (domain),
            icon_name = APP_ID
        };

        var stack = new Gtk.Stack () {
            // Half speed since it's such a huge distance
            transition_duration = 400,
            transition_type = Gtk.StackTransitionType.UNDER_UP
        };
        stack.add_css_class ("loading");
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
            web_view.load_uri ("https://" + App.settings.get_string ("domain") + "/sites");
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
        if (web_view.is_loading) {
            // TODO: Add a loading progress bar or spinner somewhere?
        } else {
            string domain = App.settings.get_string ("domain");

            sites_revealer.reveal_child = (
                web_view.uri != "https://" + domain + "/login" &&
                web_view.uri != "https://" + domain + "/register" &&
                web_view.uri != "https://" + domain + "/password/request-reset" &&
                web_view.uri != "https://" + domain + "/sites"
            );

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

    private void on_account_settings_activate () {
        web_view.load_uri ("https://" + App.settings.get_string ("domain") + "/settings");
    }

    private void on_custom_domain_activate () {
        string domain = App.settings.get_string ("domain");
        string default_domain = App.settings.get_default_value ("domain").get_string ();

        var domain_label = new Gtk.Label ("https://");
        domain_label.add_css_class ("dim-label");

        var domain_entry = new Gtk.Entry.with_buffer (new Gtk.EntryBuffer ((uint8[]) domain)) {
            activates_default = true,
            hexpand = true,
            placeholder_text = default_domain
        };

        var domain_grid = new Gtk.Grid ();
        domain_grid.attach (domain_label, 0, 0);
        domain_grid.attach (domain_entry, 1, 0);

        var domain_dialog = new Adw.AlertDialog (
            _("Set a Custom Domain"),
            /// TRANSLATORS: %s is the Plausible instance's domain name
            _("If you’re self-hosting Plausible or using an instance other than <b>%s</b>, set the domain name.").printf (domain)
        ) {
            body_use_markup = true,
            default_response = "save",
            extra_child = domain_grid,
        };
        domain_dialog.add_response ("close", _("_Cancel"));
        domain_dialog.add_response ("save", _("_Set Domain"));
        domain_dialog.set_response_appearance ("save", Adw.ResponseAppearance.SUGGESTED);

        domain_dialog.present (this);

        domain_dialog.response.connect ((response_id) => {
            if (response_id == "save") {
                string new_domain = domain_entry.buffer.text;

                if (new_domain == "") {
                    new_domain = default_domain;
                }

                // FIXME: There's currently no validation of the domain; maybe
                // try to load the domain/sites, and if it succeeds, enable the
                // save button?

                App.settings.set_string ("domain", new_domain);
                web_view.load_uri ("https://" + new_domain + "/sites");
            }
        });
    }

    private void on_log_out_activate () {
        string domain = App.settings.get_string ("domain");

        var log_out_dialog = new Adw.AlertDialog (
            _("Log out of Plausible?"),
            /// TRANSLATORS: %s is the Plausible instance's domain name
            _("You will need to re-enter your email and password for <b>%s</b> to log back in.").printf (domain)
        ) {
            body_use_markup = true,
            default_response = "log_out"
        };
        log_out_dialog.add_response ("close", _("_Stay Logged In"));
        log_out_dialog.add_response ("log_out", _("_Log Out"));
        log_out_dialog.set_response_appearance ("log_out", Adw.ResponseAppearance.DESTRUCTIVE);

        log_out_dialog.present (this);

        log_out_dialog.response.connect ((response_id) => {
            if (response_id == "log_out") {
                // NOTE: Since https://github.com/plausible/analytics/issues/730 was
                // resolved, you would think loading /logout would be sufficient;
                // however, that redirects you to the home page which feels weird.
                // Instead, we clear cookies then load /sites, which will prompt for
                // login before showing the dashboard once again.

                web_view.network_session.get_website_data_manager ().clear.begin (
                    WebKit.WebsiteDataTypes.COOKIES, 0, null, () => {
                        debug ("Cleared cookies; going home.");
                        web_view.load_uri ("https://" + domain + "/sites");
                    }
                );
            }
        });
    }

    private void on_about_activate () {
        var about_dialog = new Adw.AboutDialog.from_appdata (
            "/com/cassidyjames/plausible/metainfo.xml", VERSION
        ) {
            /// TRANSLATORS: %s is the app name
            application_name = _("%s for Plausible").printf (App.NAME),
            comments = _("Tally is a hybrid native + web app for Plausible Analytics, the lightweight and open-source website analytics tool."),

            /// TRANSLATORS: Translator credits; please translate this with your name(s)!
            translator_credits = _("translator-credits"),
            artists = {
                "Micah Ilbery https://ilbery.family/@micah",
            },
        };
        about_dialog.copyright = "© 2020–%i %s".printf (
            new DateTime.now_local ().get_year (),
            about_dialog.developer_name
        );

        about_dialog.add_link (_("About Plausible Analytics"), "https://plausible.io/about");
        about_dialog.add_link (_("Plausible Analytics Privacy Policy"), "https://plausible.io/privacy");
        about_dialog.add_legal_section ("Plausible Analytics", null, Gtk.License.CUSTOM,
"""Plausible Analytics is a product of:

Plausible Insights OÜ
Västriku tn 2, 50403, Tartu, Estonia
Registration number 14709274

Represented by Uku Täht
Email: hello@plausible.io
"""
        );

        about_dialog.present (this);
    }
}
