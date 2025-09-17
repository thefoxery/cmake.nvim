
# cmake.nvim 

## goal

To get up and running as fast as possible with CMake in neovim
- install -> setup (with sensible defaults) -> custom setup (optional) -> start working

## overview

In very early development. Public API may be subject to change etc. You know the drill!

As soon as the plugin gets into a state where it may be more useful for the public, tags will
be introduced to lock down certain stability.

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
    default_build_type = "Debug", -- assume this if you dont know
    build_types = { "MinSizeRel", "Debug", "Release", "RelWithDebInfo" }
})
```

## dap configuration

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
- variable expansion is currently limited to ${PROJECT_NAME} so only paths to build targets with a fixed name or ${PROJECT_NAME} will be found
Parameters
- user_args: not yet passed on to CMake

## thanks / inspiration

Shoutout to the projects that got me started on this journey!

cmake4vim
- https://github.com/ilyachur/cmake4vim
cmake-tools
- https://github.com/Civitasv/cmake-tools.nvim

