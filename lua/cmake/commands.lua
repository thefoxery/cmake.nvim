
local api = require("cmake.api")
local config = require("cmake.config")

vim.api.nvim_create_user_command("CMakeGenerate", function()
    api.generate(config)
end, { desc = "CMake: Configure" })

vim.api.nvim_create_user_command("CMakeBuild", function()
    api.build(config)
end, { desc = "CMake: Build" })

vim.api.nvim_create_user_command("CMakeInstall", function()
    api.install(config)
end, { desc = "CMake: Install" })

vim.api.nvim_create_user_command("CMakeUninstall", function()
    api.uninstall(config)
end, { desc = "CMake: Uninstall" })

