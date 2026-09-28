project(
    'cpp-template',
    'cpp',
    version: '0.1.0',
    meson_version: '>=1.2.0',
    default_options: [
        'cpp_std=c++23',
        'warning_level=3',
        'werror=true',
    ],
)


project_include = include_directories('src')

library_sources = files('src/greeting.cpp')
cpp_template_lib = static_library(
    'cpp-template',
    library_sources,
    include_directories: project_include,
    install: true,
)

cpp_template_dep = declare_dependency(
    include_directories: project_include,
    link_with: cpp_template_lib,
)

if get_option('enable_examples')
    executable(
        'cpp-template-example',
        'src/main.cpp',
        dependencies: cpp_template_dep,
        install: true,
    )
endif

test_exe = executable(
    'cpp-template-tests',
    'tests/greeting_test.cpp',
    dependencies: cpp_template_dep,
)
test('greeting', test_exe)

install_headers('src/greeting.hpp', subdir: 'cpp-template')

summary({
    'buildtype': get_option('buildtype'),
    'cpp standard': get_option('cpp_std'),
    'tests': 'enabled',
}, section: 'Configuration')
