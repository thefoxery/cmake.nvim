
# cmake.nvim

## Overview

This plugin aims to provide two main things
- A "future proof" robust interface to interact with CMake
- A public api with methods for common workflows
    - Generate build system
    - Build project
    - Install project
    - Uninstall project
    - Run CMake script
    - Run CMake command line tool
    - List, configure and build CMake presets provided by CMakePresets.json/CMakeUsersPresets.json files

## Goal

To get up and running as fast as possible with CMake in neovim
- install -> setup (with sensible defaults) -> custom setup (optional) -> start working

## Project status

In very early development. Public API may be subject to change etc. You know the drill!

As soon as the plugin gets into a state where it may be more useful for the public, tags will
be introduced to lock down stability.

## Install

```lua
# lazy

{
    'thefoxery/cmake.nvim",
}
```

## Setup

```lua
# default configuration
require("cmake").setup({
    cmake_executable_path = "cmake",
    build_dir = "build",
    source_dir = ".",
    default_build_type = "Debug", -- assume this if build system reports ""
    build_types = { "MinSizeRel", "Debug", "Release", "RelWithDebInfo" }
    user_args = {
        configuration = {},
        build = {},
    },
})
```

## Public API

### Overview

The public API evolves around the following method:

```lua
require("cmake").create_command({
    cmake_executable_path = "cmake", -- passing this will override the default setting from setup()
    args = { "-B build", "-S .", "-DCMAKE_BUILD_TYPE=Debug" }
})
```

Method will try its best to verify the cmake executable.

### API

```lua
local cmake = require("cmake")
```

#### Generate

```lua
require("cmake").generate({
    cmake_executable_path = "cmake",
    source_dir = ".",
    build_dir = "build",
    build_type = "Debug",
    args = {}
})
```

#### Build

```lua
require("cmake").build({
    cmake_executable_path = "cmake",
    build_dir = "build",
    build_type = "Debug",
    args = {}
})
```

#### Install

```lua
require("cmake").install({
    cmake_executable_path = "cmake",
    build_dir = "build",
    args = {},
})
```

#### Uninstall

```lua
require("cmake").uninstall({
    build_dir = "build",
})
```

#### Run Commandline Tool

```lua
require("cmake").run_cmdline_tool({
    cmake_executable_path = "cmake",
})
```

#### Run CMake script

```lua
require("cmake").run_cmake_script({
    cmake_executable_path = "cmake",
    vars = { "-D ENABLE_FEATURE_XYZ=ON" },
    cmake_script_file = "features.cmake",
})
```

### Presets

#### Configure Preset

Configure project using a CMakePresets.json file or CMakeUserPresets.json file

```lua
require("cmake").configure_preset({
    cmake_executable_path = "cmake",
    preset = "Debug",
})
```

#### Build Preset

Build project using a CMakePresets.json file or CMakeUserPresets.json file
Can also be used to build an install target to install the project.

```lua
require("cmake").build_preset({
    cmake_executable_path = "cmake",
    preset = "Debug",
})

require("cmake").build_preset({
    cmake_executable_path = "cmake",
    preset = "install",
})
```

### Other

#### Get build system type

Will report "CMake" by default

```lua
require("cmake").get_build_system_type()
```

#### Set build type

```lua
require("cmake").set_build_type("Debug")
```

#### Set build target

```lua
require("cmake").set_build_target("my_application")
```

#### Get build target binary path

Can be used to locate the binary of a build target i.e. for the debug adapter

```lua
local cmake = require("cmake")

dap.configurations.cpp = {
{
        name = "Debug",
        type = "codelldb",
        request = "launch",
        program = function()
            if cmake.is_project_directory() then
                return cmake.get_target_binary_path(cmake.get_build_target())
            end
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        terminal = "integrated",
    },
```

## Suggested companion plugins

- [telescope-build](https://github.com/thefoxery/telescope-build.nvim)
    - Telescope powered pickers for build type/target
    - Configurable for any build system
- [lualine-build](https://github.com/thefoxery/lualine-build.nvim)
    - Displays build configuration in lualine
    - Configurable for any build system

If you are looking for a similar plugin for Make, check out: [make.nvim](https://github.com/thefoxery/make.nvim)

## Thanks / Inspiration

Shoutout to the projects that got me started on this journey!

- [cmake4vim](https://github.com/ilyachur/cmake4vim)
- [telescope-cmake4vim](https://github.com/SantinoKeupp/telescope-cmake4vim.nvim)
- [lualine-cmake4vim](https://github.com/SantinoKeupp/lualine-cmake4vim.nvim)
- [cmake-tools](https://github.com/Civitasv/cmake-tools.nvim)

