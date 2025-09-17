
# cmake.nvim 

Provides a basic API for CMake functionality

- Configure
- Build
- Get build target binary path (helps to set up run/debug)

Suggested companion plugins

- [telescope-build](https://github.com/thefoxery/telescope-build.nvim)
    - Select build type/target using telescope picker
    - Configurable for any build system
- [lualine-build](https://github.com/thefoxery/lualine-build.nvim)
    - Displays build configuration in lualine
    - Configurable for any build system

If you are looking for something similar for Make
- [make.nvim](https://github.com/thefoxery/make.nvim)

## goal

To get up and running as fast as possible with CMake in neovim
- install -> setup (with sensible defaults) -> custom setup (optional) -> start working

## project status

In very early development. Public API may be subject to change etc. You know the drill!

As soon as the plugin gets into a state where it may be more useful for the public, tags will
be introduced to lock down stability.

## install

```
# lazy

{
    'thefoxery/cmake.nvim",
}
```

## setup

```
# plugin setup

# default configuration
require("cmake").setup({
    build_dir = "build",
    source_dir = ".",
    default_build_type = "Debug", -- assume this if build system reports ""
    build_types = { "MinSizeRel", "Debug", "Release", "RelWithDebInfo" }
})
```

## example dap configuration

```
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

## limitations / known issues

Parsing CMakeLists.txt files
- variable expansion is currently limited to ${PROJECT_NAME} so only paths to build target binaries with a fixed name or ${PROJECT_NAME} will be found

## TODO

Brain dump of what is probably on the roadmap

- Improved CMakeLists.txt parsing
    - Variable expansion (at least one level)

- Parameters
    - user_args = { configure = "", build = "" }

## thanks / inspiration

Shoutout to the projects that got me started on this journey!

cmake4vim
- [cmake4vim](https://github.com/ilyachur/cmake4vim)
- [telescope-cmake4vim](https://github.com/SantinoKeupp/telescope-cmake4vim.nvim)
- [lualine-cmake4vim](https://github.com/SantinoKeupp/lualine-cmake4vim.nvim)
- [cmake-tools](https://github.com/Civitasv/cmake-tools.nvim)

