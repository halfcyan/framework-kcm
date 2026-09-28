# C++ Template

Maintained by Cypress Reed ([cypress@fyralabs.com](mailto:cypress@fyralabs.com))

A small, reusable C++23 project template using [Meson](https://mesonbuild.com/) and Ninja.
It includes a static library, an example executable, and a dependency-free test executable.

## Requirements

- A C++23 compiler (GCC, Clang, or MSVC)
- Meson 1.2 or newer
- Ninja

### Fedora setup

```sh
sudo dnf install gcc-c++ meson ninja-build clang-tools-extra
```

## Configure and build

```sh
meson setup build
meson compile -C build
```

Meson exports `build/compile_commands.json`, and the root-level `compile_commands.json`
symlink points to it so editors such as Zed and clangd can discover the compile flags.
The symlink is valid after configuring the project with `meson setup build`.

Run the example:

```sh
./build/cpp-template-example
```

Run the tests:

```sh
meson test -C build --print-errorlogs
```

A release-style build can be configured with:

```sh
meson setup build-release --buildtype=release
meson compile -C build-release
```

The example can be omitted when configuring a build:

```sh
meson setup build -Denable_examples=false
```

## Project layout

- `src/` — library headers and implementation
- `tests/` — test executables registered with Meson
- `meson.build` — project, targets, install rules, and tests
- `meson_options.txt` — user-configurable Meson options

To use this as a template, replace `cpp-template` in `meson.build`, rename the library
and executable targets, and update the namespace and source files.
