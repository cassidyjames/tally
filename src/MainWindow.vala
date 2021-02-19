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

public class Plausible.MainWindow : Gtk.Window {
    private Plausible.WebView web_view;
    // private Gtk.Revealer back_revealer;
    private Gtk.Revealer account_revealer;
    private Gtk.Stack account_stack;
    private Gtk.Revealer sites_revealer;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            border_width: 0,
            icon_name: Application.instance.application_id,
            resizable: true,
            title: "Plausible",
            window_position: Gtk.WindowPosition.CENTER
        );
    }

    construct {
        default_height = 700;
        default_width = 1000;

        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
        Gdk.RGBA rgba = { 0, 0, 0, 1 };
        rgba.parse ("#5850EC");
        Granite.Widgets.Utils.set_color_primary (this, rgba);

        var sites_button = new Gtk.Button.with_label ("My Websites") {
            valign = Gtk.Align.CENTER
        };
        sites_button.get_style_context ().add_class ("back-button");

        sites_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT
        };
        sites_revealer.add (sites_button);

        var account_button = new Gtk.Button.from_icon_name ("avatar-default", Gtk.IconSize.LARGE_TOOLBAR) {
            tooltip_text = "Account Settings"
        };

        var logout_button = new Gtk.Button.from_icon_name ("system-log-out", Gtk.IconSize.LARGE_TOOLBAR) {
            tooltip_text = "Log Out"
        };

        account_stack = new Gtk.Stack (){
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        account_stack.add_named (account_button, "account");
        account_stack.add_named (logout_button, "logout");

        account_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };
        account_revealer.add (account_stack);

        var header = new Gtk.HeaderBar () {
            has_subtitle = false,
            show_close_button = true
        };
        // header.pack_start (back_revealer);
        header.pack_start (sites_revealer);
        header.pack_end (account_revealer);

        web_view = new Plausible.WebView ();
        web_view.load_uri ("https://" + Application.instance.domain + "/sites");

        var logo = new Gtk.Image.from_resource ("/com/cassidyjames/plausible/logo-dark.png") {
            expand = true,
            margin_bottom = 48
        };

        var stack = new Gtk.Stack () {
            transition_duration = 300,
            transition_type = Gtk.StackTransitionType.UNDER_UP
        };
        stack.get_style_context ().add_class ("loading");
        stack.add_named (logo, "loading");
        stack.add_named (web_view, "web");

        set_titlebar (header);
        add (stack);

        web_view.load_changed.connect ((load_event) => {
            if (load_event == WebKit.LoadEvent.FINISHED) {
                stack.visible_child_name = "web";
            }
        });

        sites_button.clicked.connect (() => {
            web_view.load_uri ("https://" + Application.instance.domain + "/sites");
        });

        account_button.clicked.connect (() => {
            web_view.load_uri ("https://" + Application.instance.domain + "/settings");
        });

        logout_button.clicked.connect (() => {
            // NOTE: Plausible expects a POST not just loading the URL
            // https://github.com/plausible/analytics/issues/730
            // web_view.load_uri ("https://" + Application.instance.domain + "/logout");

            web_view.get_website_data_manager ().clear.begin (
                WebKit.WebsiteDataTypes.COOKIES,
                0,
                null,
                () => {
                    debug ("Cleared cookies; going home.");
                    web_view.load_uri ("https://" + Application.instance.domain + "/sites");
                }
            );
        });

        web_view.load_changed.connect (on_loading);
        web_view.notify["uri"].connect (on_loading);
        web_view.notify["estimated-load-progress"].connect (on_loading);
        web_view.notify["is-loading"].connect (on_loading);
    }

    private void on_loading () {
        // Only do anything once we're done loading
        if (! web_view.is_loading) {
            sites_revealer.reveal_child = (
                web_view.uri != "https://" + Application.instance.domain + "/login" &&
                web_view.uri != "https://" + Application.instance.domain + "/register" &&
                web_view.uri != "https://" + Application.instance.domain + "/password/request-reset" &&
                web_view.uri != "https://" + Application.instance.domain + "/sites"
            );

            account_revealer.reveal_child = (
                web_view.uri != "https://" + Application.instance.domain + "/login" &&
                web_view.uri != "https://" + Application.instance.domain + "/register" &&
                web_view.uri != "https://" + Application.instance.domain + "/password/request-reset"
            );

            if (web_view.uri == "https://" + Application.instance.domain + "/settings") {
                account_stack.visible_child_name = "logout";
            } else {
                account_stack.visible_child_name = "account";
            }
        }
    }
}
