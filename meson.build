project(
  'com.cassidyjames.plausible',
  'vala', 'c',
  version: '3.2.1',
  meson_version: '>= 0.62',
)

i18n = import('i18n')
gnome = import('gnome')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')

asresources = gnome.compile_resources(
  'as-resources',
  'data' / 'gresource.xml',
  source_dir: 'data',
  c_name: 'as',
)

config_data = configuration_data()

config_data.set_quoted('APP_ID', meson.project_name())
config_data.set_quoted('VERSION', meson.project_version())

config_file = configure_file(
  input: 'src/Config.vala.in',
  output: '@BASENAME@',
  configuration: config_data,
)

executable(
  meson.project_name(),
  'src' / 'App.vala',
  'src' / 'MainWindow.vala',
  'src' / 'Widgets' / 'WebView.vala',
  asresources,
  config_file,
  dependencies: [
    dependency('glib-2.0'),
    dependency('gtk4'),
    dependency('libadwaita-1', version: '>=1.5'),
    dependency('webkitgtk-6.0'),
    meson.get_compiler('vala').find_library('posix'),
  ],
  install: true,
)

subdir('data')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
