# plausible

UNOFFICIAL hybrid native + web app for Plausible

![Screenshot](data/screenshot.png)

## Developing and Building

If you want to hack on and build Plausible yourself, you'll need the following dependencies:

* libgranite-dev
* libgtk-3-dev
* libvte-2.91-dev
* libvala-dev
* libwebkit2gtk-4.0-dev
* meson
* valac 

Run `meson build` to configure the build environment and run `ninja test` to build and run automated tests

    meson build --prefix=/usr
    cd build
    ninja test

To install, use `ninja install`, then execute with `com.github.cassidyjames.plausible`

    sudo ninja install
    com.github.cassidyjames.plausible
