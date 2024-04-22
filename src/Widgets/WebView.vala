/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020–2024 Cassidy James Blaede <c@ssidyjam.es>
 */

public class Plausible.WebView : WebKit.WebView {
    private bool is_terminal = false;

    public WebView () {
        Object (
            hexpand: true,
            vexpand: true,
            network_session: new WebKit.NetworkSession (null, null),
            user_content_manager: new WebKit.UserContentManager ()
        );
    }

    construct {
        is_terminal = Posix.isatty (Posix.STDIN_FILENO);

        var webkit_settings = new WebKit.Settings () {
            default_font_family = Gtk.Settings.get_default ().gtk_font_name,
            enable_back_forward_navigation_gestures = true,
            enable_developer_extras = is_terminal,
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

            body > nav {
              display: none;
            }

            body > main {
              margin-top: -1.5em;
            }

            /* Footer */
            body > main + div {
              display: none;
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

        var cookie_manager = network_session.get_cookie_manager ();
        cookie_manager.set_accept_policy (WebKit.CookieAcceptPolicy.ALWAYS);

        string config_dir = Path.build_path (
            Path.DIR_SEPARATOR_S,
            Environment.get_user_config_dir (),
            Environment.get_prgname ()
        );

        DirUtils.create_with_parents (config_dir, 0700);

        string cookies = Path.build_filename (config_dir, "cookies");
        cookie_manager.set_persistent_storage (
            cookies,
            WebKit.CookiePersistentStorage.SQLITE
        );

        context_menu.connect (() => {
            return !is_terminal;
        });

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
}
