
# cmake.nvim

# Purpose

Provide a basic API for CMake functionality
- configure(opts)
    - configures the project. If called without arguments it will default to the configuration passed in to setup()
- build(opts)
    - build the project. If called without arguments it will default to the configuration passed in to setup()
- get_build_system_type()
- set_build_type(build_type)
- set_build_target(build_target)
- get_target_binary_path(build_target)

Suggested companion plugins
- [telescope-build](https://github.com/thefoxery/telescope-build.nvim)
    - Telescope powered pickers for build type/target
    - Configurable for any build system
- [lualine-build](https://github.com/thefoxery/lualine-build.nvim)
    - Displays build configuration in lualine
    - Configurable for any build system

If you are looking for a similar plugin for Make, then check out: [make.nvim](https://github.com/thefoxery/make.nvim)

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
# plugin setup

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

## Example DAP configuration

```lua
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

## Limitations / Known issues

- Support for project specific args not yet implemented

## Thanks / Inspiration

Shoutout to the projects that got me started on this journey!

- [cmake4vim](https://github.com/ilyachur/cmake4vim)
- [telescope-cmake4vim](https://github.com/SantinoKeupp/telescope-cmake4vim.nvim)
- [lualine-cmake4vim](https://github.com/SantinoKeupp/lualine-cmake4vim.nvim)
- [cmake-tools](https://github.com/Civitasv/cmake-tools.nvim)

