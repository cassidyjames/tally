project(
    'com.cassidyjames.plausible',
    'vala', 'c',
    version: '1.1.0'
)

gnome = import('gnome')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')

asresources = gnome.compile_resources(
    'as-resources',
    join_paths('data', 'gresource.xml'),
    source_dir: 'data'
)

executable(
    meson.project_name(),
    join_paths('src', 'App.vala'),
    join_paths('src', 'MainWindow.vala'),
    join_paths('src', 'WebContext.vala'),
    join_paths('src', 'Widgets', 'WebView.vala'),
    asresources,
    dependencies: [
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('webkit2gtk-4.0'),
    ],
    install: true
)

subdir('data')

meson.add_install_script(join_paths('meson', 'post_install.py'))
