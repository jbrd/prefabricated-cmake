[![CMake on multiple platforms](https://github.com/jbrd/prefabricated-cmake/actions/workflows/cmake-multi-platform.yml/badge.svg)](https://github.com/jbrd/prefabricated-cmake/actions/workflows/cmake-multi-platform.yml)

# prefabricated-cmake

A CMake build system for component-based C++ projects.

**Current Release:** 1.0.0 (**[Full Changelog](CHANGELOG.md)**)


## What and Why?

CMake is great, but often has a high setup cost for new projects. Setting up a new project that supports modular components, unit testing, memory checking, code formatting, documentation, installation, etc can be time consuming.

The primary goal of this project is to reduce the overhead by providing a CMake-based build system with prefabricated support for these things.


### Inspiration

This build system is inspired by Unreal Engine's build system, which allows a large and complicated piece of software to be assembled from many smaller components. New components are easy to add with little scripting required.

The goal of this project is to provide a similar philosophy for standalone C++ projects.


## Features

* Prefabricated CMake scripts for component-based C++ projects
  * Add new components with a tiny amount of CMake
  * Each component can have its own public sources, private sources, documentation, and tests
  * C++17 by default (can be overridden by overriding `CMAKE_CXX_STANDARD` variable)
  * Strict C/C++ compilation by default (can be overridden via the `STRICT` variable)
  * Clang compilation by default (Linux, MacOS, and Windows)
  * Convenience compiler definitions (PROJECT_VERSION, PUBLIC_API for public symbols)
  * Automatic source groups to ensure that IDEs like Visual Studio have a project / filter structure that matches the file system
* Entire cross-platform toolchain (Linux, MacOS, Windows)
* Prefabricated [Clang-Format](https://webkit.org/code-style-guidelines/) Support
  * A `format` target for automatically formatting source code with Clang-Format
  * A `format-check` target for validating that source code is correctly Clang-Formatted
  * Optionally place a `.clang-format` file in the root of your project to override the defaults
* Prefabricated support for unit test executables
  * All tests are run standalone and then through Valgrind on MacOS and Linux for additional memory validation
* Prefabricated Sphinx documentation project
  * Supports both project-level and component-level documentation
  * Out-the-box support for Breathe and Doxygen (for automatically generating
    C++ documentation and referencing it in Sphinx docs)
  * Uses the Sphinx ReadTheDocs theme for visually pleasing documentation


## Getting Started

The repository contains an example project - the quickest way to get started is to first take a look
at the structure of the `example` project, and then adapt the examples to suit your own requirements.

This repository is designed to be referenced via a git submodule by the projects that wish to use it.


### Building The Example Locally

* Ensure the toolchain requirements are installed (see below)
* On Linux open a bash shell, on Windows open the x64 Native Tools Command Prompt
* cd into the example directory (e.g. `cd example`)
* Make a build directory and cd into that (e.g. `mkdir build ; cd build`)
* Generate project files with: `cmake ../`
* Build the project with: `cmake --build ./`
* Build the documentation with: `cmake --build ./ --target docs`
  * View the documentation by opening: `docs\sphinx\build\html\index.html`
* Run the tests with: `ctest -C Debug ./`
* Validate source code formatting with: `cmake --build ./ --target format-check`
* Automatically format source code with: `cmake --build ./ --target format`


### Installing The Example to a Local Deployment

* Specify your deployment directory when generating project files: `cmake -DCMAKE_INSTALL_PREFIX=./deploy ../`
* Build the project in Release mode with: `cmake --build ./ --config Release`
* Build the documentation: `cmake --build ./ --target docs`
* Install to a local deployment `cmake --build ./ --target install`


## Other Example Projects

Another great way to learn how to use prefabricated-cmake is to take a look at other projects that are using it.

The following public projects use prefabricated-cmake:

* Coming soon!

If you are using it in your project, and want to be included in this list, please submit a pull request!


## Toolchain Requirements

### Linux and MacOS

* Git
* CMake
* Clang
* Clang-format
* Valgrind
* Doxygen
* Python 3
* Sphinx (`pip3 install sphinx`)
* Breathe (`pip3 install breathe`)
* ReadTheDocs Theme for Sphinx (`pip3 install sphinx-rtd-theme`)

### Windows

* Visual Studio 2022 with the following components:
  * C++ Clang Compiler for Windows (17.0.0 or above)
  * MSBuild support for LLVM (clang-cl) toolset
  * C++ CMake tools for Windows
* Git for Windows
* Chocolatey and the following packages:
  * Doxygen (`choco install doxygen.install`)
  * Python 3 (`choco install python3`)
  * Sphinx (`pip3 install sphinx`)
  * Breathe (`pip3 install breathe`)
  * ReadTheDocs Theme for Sphinx (`pip3 install sphinx-rtd-theme`)


## Project Structure

### Overview

All source code for a project is placed in the `src` directory and follows a **component** based pattern.

### Top-Level `CMakeLists.txt`

Using these build scripts should be as simple as including `main.cmake` and then calling `build_components()`.

For example, here is the example project's CMake file:

```
cmake_minimum_required(VERSION 3.12)
include(../main.cmake)
project(
	"example_project"
	VERSION "1.0.0"
)
set(PROJECT_AUTHOR "Author Name")
build_components()
```

Use the `PROJECT_AUTHOR` variable to specify the author name for your project.

You can also define the following function in your top-level `CMakeLists.txt` file which will be automatically called by the build system for every target in the project. Use this to apply project-wide dependencies and settings to targets:

```
# Applies target properties that are common to all targets in this repository.
function(apply_common_target_properties TARGET)
	# Enable C++20
	set_target_properties(${TARGET} PROPERTIES CXX_STANDARD 20 CXX_STANDARD_REQUIRED true)
endfunction()
```


### Components

A **component** is a directory whose structure follows the following convention:

* `./CMakeLists.txt` - a file containing a minimal amount of CMake required to declare the component to the build system
* `./Public/` - a directory containing publically visible source code (accessible beyond the component itself)
* `./Private/` - a directory containing source code only accessible to the component itself
* `./Tests/` - a directory whose contents will be compiled into a test executable and added to the test suite automatically
* `./Docs` - a directory whose contents will be compiled into the documentation for the project automatically


### Component CMakeLists.txt

The build system has been designed to ensure that only a minimal amount of CMake is required per component.

A typical component will contain just two CMake calls:

* A call to one of the `add_component_` functions, which defines the type of component being compiled
* An optional call to `set_component_dependencies` which allows the component to reference other components / system libraries


#### The `add_component_program` Function

Use this when the current directory represents an executable program component.
Programs are assumed to be public and are therefore included in the install target
for the project.


#### The `add_component_public_library` Function

Use this when the current directory represents a public library. Public libraries
are included in the install target for the project, as are the corresponding header
files. Both static and shared library variants are created to allow the consumer of
the library to choose static or dynamic linking according to their requirements.


#### The `add_component_static_library` Function

Use this when the current directory represents a private static library. Static
libraries are not deployed as part of the install target for the project and
are only available for static linking at build time.


#### The `add_component_runtime_library` Function

Use this when the current directory represents a private runtime library. Runtime
libraries are deployed to the binary directory as part of the install target for
the project. Runtime libraries are only available for dynamic linking at build time
and may also be dynamically loaded at runtime (via `dlopen`, `LoadModule`, etc).
Runtime libraries are considered private to the project, so header files are not
included as part of the install target for this project and the library itself
may be deployed to a directory not available for linking outside the project (e.g.
`bin` instead of `lib` on Unix).


#### The `add_component_test` Function

Use this when the current directory represents a test executable. Test executables
are considered private to the project and are therefore ignored by the install
target. Test executables are automatically added to the test target for the
project.


#### The `set_component_dependencies` Function

Sets dependencies for the component in the current directory.

This function expects a list of arguments, for example:

```cmake
set_component_dependencies(
	SHARED arg1 arg2 ...
	STATIC arg3 arg4 ...
	SYSTEM arg5 arg6 ...
)
```

where:

* SHARED specifies to dynamically link against the following components
* STATIC specifies to statically link against the following components
* SYSTEM specifies to link against the following system libraries

### Project-Level Documentation

If a project has a root-level `docs` directory, any `.rst` files inside this directory will be included
as project-level documentation when the `docs` target is built.


## Contributors

* James Bird (@jbrd)
