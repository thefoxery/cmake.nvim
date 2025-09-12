
# CMake

## purpose

- to make life easier working with CMake projects in neovim.
- to learn about neovim plugin development

## overview

In very early development. Expect things to break.

## requirements

TBD

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

