
local PLUGIN_NAME = "cmake.nvim"

if vim.fn.has("nvim-0.7.0") ~= 1 then
    vim.api.nvim_echo({ {string.format("plugin '%s' requires nvim-0.7.0 or higher", PLUGIN_NAME) } }, true, { err = true })
    return
end

