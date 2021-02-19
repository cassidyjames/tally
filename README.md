# Plausible

Hybrid native + web app for [Plausible Analytics](https://plausible.io). Designed for elementary OS.

![Screenshot](data/screenshot.png)

Plausible is the simple privacy-friendly alternative to Google Analytics. This app wraps the Plausible web app in a native UI, integrating better with desktop operating systems like elementary OS. Native features include:

- Icon in your Applications Menu, Dock, etc.
- Native header bar with buttons for account settings and logging out
- Save and restore current view, size, and position when closed and opened
- Two-finger swipe to go back/forward between views

Other features:

- Zoom in/out with Ctrl+Plus/Minus, and it's remembered the next time you use the app
- Slimmed down web app UI (no header or footer with external links)


## Developing and Building

Development is targeted at [elementary OS](https://elementary.io). If you want to hack on and build the app yourself, you'll need the following dependencies:

* libgranite-dev (>=5.5)
* libgtk-3-dev
* libwebkit2gtk-4.0-dev
* meson
* valac

You can install them on elementary OS with:

```shell
sudo apt install elementary-sdk libwebkit2gtk-4.0-dev
```

Run `meson build` to configure the build environment and run `ninja` to build:

```shell
meson build --prefix=/usr
cd build
ninja
```

To install, use `ninja install`, then execute with `com.cassidyjames.plausible`:

```shell
ninja install
com.cassidyjames.plausible
```

### Flatpak

Building is also possible with Flatpak. Ensure you have Flathub added as a user repo, then from the top-level of this repo:

```shell
flatpak-builder --user --force-clean --install-deps-from=flathub --install build-dir com.cassidyjames.plausible.yml
```
