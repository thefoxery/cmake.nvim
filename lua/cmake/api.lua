
local internal = require("cmake.internal")

local M = {}

local CMAKELISTS_FILE_NAME = "CMakeLists.txt"

function M.setup(opts)
    opts = opts or {}
    -- TODO: save config in vim.g for now. We will look into persistence once we get things up and running.
    vim.g.cmake_build_dir = opts.build_dir or "build"
    vim.g.cmake_build_type = opts.default_build_type or "Debug"
    vim.g.cmake_user_args = opts.user_args or "-DCMAKE_EXPORT_COMPILE_COMMANDS=1"

    vim.api.nvim_create_user_command("CMakeConfigure", function()
        M.configure_project()
    end, {})
end

function M.is_cmake_project()
    return vim.fn.glob(CMAKELISTS_FILE_NAME) ~= ""
end

function M.get_build_dir()
    return vim.g.cmake_build_dir
end

function M.get_source_dir()
    return "."
end

function M.configure_project()
    local command = internal._create_configure_command(
        M.get_source_dir(),
        M.get_build_dir(),
        string.format("%s -DCMAKE_BUILD_TYPE=%s", vim.g.cmake_user_args, vim.g.cmake_build_type)
    )
    internal._execute_command(command)
end

function M.build_project()
    local command = internal._create_build_command(
        M.get_build_dir(),
        M.get_build_type()
    )
    internal._execute_command(command)
end

return M

