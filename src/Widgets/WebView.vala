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

        // NOTE: Show only the main UI and login form, plus tweak some browser
        // default behaviors to feel more app-like.
        var custom_css = new WebKit.UserStyleSheet (
            """
            html {
              -webkit-user-select: none;
              cursor: default;
            }

            nav,
            main + * {
              display: none;
            }

            main {
              margin-top: -1.5em;
            }

            button,
            [role=button],
            .button,
            select,
            .cursor-pointer,
            .cursor-pointer:hover,
            a:not([href^="http"]) {
              cursor: default!important;
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

        var back_click_gesture = new Gtk.GestureClick () {
            button = 8
        };
        back_click_gesture.pressed.connect (go_back);
        add_controller (back_click_gesture);

        var forward_click_gesture = new Gtk.GestureClick () {
            button = 9
        };
        forward_click_gesture.pressed.connect (go_forward);
        add_controller (forward_click_gesture);
    }

    private bool on_context_menu (
        WebKit.ContextMenu context_menu,
        Gdk.Event event,
        WebKit.HitTestResult hit_test_result
    ) {
        // Only when launched from console/TTY/terminal
        if (Posix.isatty (Posix.STDIN_FILENO)) {
            return Gdk.EVENT_PROPAGATE;
        }

        return !Gdk.EVENT_PROPAGATE;
    }
}
