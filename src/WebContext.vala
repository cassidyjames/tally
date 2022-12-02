/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2019–2022 Cassidy James Blaede <c@ssidyjam.es>
 */

public class Plausible.WebContext : WebKit.WebContext {
    public WebContext () {
        Object (
            // This causes a known visual regression with navigation gestures.
            // See: https://bugs.webkit.org/show_bug.cgi?id=205651
            process_swap_on_cross_site_navigation_enabled: true
        );

        var cookie_manager = get_cookie_manager ();
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

        set_process_model (WebKit.ProcessModel.MULTIPLE_SECONDARY_PROCESSES);
        set_sandbox_enabled (true);
    }
}
