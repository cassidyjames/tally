/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020–2022 Cassidy James Blaede <c@ssidyjam.es>
 */

public class Plausible.WebView : WebKit.WebView {
    public WebView () {
        Object (
            hexpand: true,
            vexpand: true,
            user_content_manager: new WebKit.UserContentManager ()
        );
    }

    construct {
        var webkit_settings = new WebKit.Settings () {
            default_font_family = Gtk.Settings.get_default ().gtk_font_name,
            enable_accelerated_2d_canvas = true,
            enable_back_forward_navigation_gestures = true,
            // TODO: only enable when running from Terminal
            // https://github.com/cassidyjames/plausible/issues/11
            // enable_developer_extras = true,
            enable_dns_prefetching = true,
            enable_html5_database = true,
            enable_html5_local_storage = true,
            enable_smooth_scrolling = true,
            enable_webgl = true,
            hardware_acceleration_policy = WebKit.HardwareAccelerationPolicy.ALWAYS
        };

        // NOTE: Show only the main UI and login form; could be handled better
        // if the Plausible web app used a semantic footer instead of a div
        var custom_css = new WebKit.UserStyleSheet (
            """
            body > :not(main):not(form) {
              display: none;
            }

            main {
              margin-top: -2em;
            }
            """,
            WebKit.UserContentInjectedFrames.TOP_FRAME,
            WebKit.UserStyleLevel.AUTHOR,
            null,
            null
        );
        user_content_manager.add_style_sheet (custom_css);

        settings = webkit_settings;
        web_context = new Plausible.WebContext ();

        context_menu.connect (on_context_menu);

        // button_release_event.connect ((event) => {
        //     if (event.button == 8) {
        //         go_back ();
        //         return true;
        //     } else if (event.button == 9) {
        //         go_forward ();
        //         return true;
        //     }

        //     return false;
        // });
    }

    private bool on_context_menu (
        WebKit.ContextMenu context_menu,
        Gdk.Event event,
        WebKit.HitTestResult hit_test_result
    ) {
        // Disable context menu
        // TODO: only disable when not running from Terminal
        // https://github.com/cassidyjames/plausible/issues/11
        return true;
        // return false;
    }
}
