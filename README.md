
# CMake

## purpose

- to make life easier working with CMake projects in neovim.
- to learn about neovim plugin development

## goal

To get up and running as fast as possible with CMake in neovim
- install -> setup (with sensible defaults) -> custom setup (optional) -> start working

## overview

In very early development. Public API may be subject to change etc. You know the drill!

As soon as the plugin gets into a state where it may be more useful for the public, tags will
be introduced to lock down certain aspects of stability.

## requirements

- Early commits had a dependency on Telescope which is now moved to a separate plugin (thefoxery/telescope-cmake.nvim)

## limitations

- variables does not support function statements
- variable expansion is currently limited to ${PROJECT_NAME}

## install

```
# lazy

{
    'thefoxery/cmake.nvim",
    dependencies = {
        'nvim-telescope/telescope.nvim'
    },
}

```

## setup

```
require("cmake").setup({
    build_dir = "build",
    default_build_type = "Debug",
    user_args = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" }
})
```

## thanks / inspiration

cmake4vim
- https://github.com/ilyachur/cmake4vim
cmake-tools
- https://github.com/Civitasv/cmake-tools.nvim

