project(
    'com.cassidyjames.plausible',
    'vala', 'c',
    version: '0.0.1'
)

gnome = import('gnome')
# i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')
# add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

asresources = gnome.compile_resources (
    'as-resources',
    join_paths ('data', 'gresource.xml'),
    source_dir: 'data'
)

executable(
    meson.project_name(),
    join_paths('src', 'Application.vala'),
    join_paths('src', 'MainWindow.vala'),
    join_paths('src', 'WebContext.vala'),
    join_paths('src', 'Widgets', 'WebView.vala'),
    asresources,
    dependencies: [
        dependency('granite'),
        dependency('gtk+-3.0'),
        # dependency('javascriptcoregtk-4.0'),
        # dependency('libsoup-2.4'),
        dependency('webkit2gtk-4.0'),
    ],
    install: true
)

subdir('data')
# subdir('po')

meson.add_install_script(join_paths('meson', 'post_install.py'))
