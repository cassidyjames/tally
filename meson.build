project(
  'com.cassidyjames.plausible',
  'vala', 'c',
  version: '3.0.1'
)

gnome = import('gnome')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')

asresources = gnome.compile_resources(
  'as-resources',
  'data' / 'gresource.xml',
  source_dir: 'data'
)

config_data = configuration_data()

config_data.set_quoted('APP_ID', meson.project_name())
config_data.set_quoted('VERSION', meson.project_version())

config_file = configure_file(
  input: 'src/Config.vala.in',
  output: '@BASENAME@',
  configuration: config_data
)

executable(
  meson.project_name(),
  'src' / 'App.vala',
  'src' / 'MainWindow.vala',
  'src' / 'WebContext.vala',
  'src' / 'Widgets' / 'WebView.vala',
  asresources,
  config_file,
  dependencies: [
    dependency('glib-2.0'),
    dependency('gtk4'),
    dependency('libadwaita-1'),
    dependency('webkit2gtk-5.0'),
    meson.get_compiler('vala').find_library('posix'),
  ],
  install: true
)

subdir('data')

meson.add_install_script('build-aux' / 'meson'/ 'post_install.py')
