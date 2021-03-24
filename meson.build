project(
    'com.cassidyjames.plausible',
    'vala', 'c',
    version: '1.2.2'
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
        dependency('granite', version: '>= 6.0'),
        dependency('gtk+-3.0', version: '>= 3.24'),
        dependency('libhandy-1', version: '>= 1.0.0'),
        dependency('webkit2gtk-4.0', version: '>= 2.30'),
    ],
    install: true
)

subdir('data')

meson.add_install_script(join_paths('meson', 'post_install.py'))
