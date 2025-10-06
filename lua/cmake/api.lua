
local state = require("cmake.internal.state")
local util = require("cmake.internal.util")
local cmake = require("cmake.internal.cmake")

local M = {}

M.PLUGIN_NAME = "cmake.nvim"

local default_opts = {
    cmake_executable_path = "cmake",
    build_dir = "build",
    source_dir = ".",
    build_types = { "MinSizeRel", "Debug", "Release", "RelWithDebInfo" },
    build_type = "Debug",
    build_target = "",
    user_args = {
        configuration = {},
        build = {},
    },
}

function M.setup(user_opts)
    user_opts = user_opts or {}
    user_opts.user_args = user_opts.user_args or {}

    state.cmake_executable_path = util.resolve(user_opts.cmake_executable_path) or default_opts.cmake_executable_path
    state.build_dir = util.resolve(user_opts.build_dir) or default_opts.build_dir
    state.source_dir = util.resolve(user_opts.source_dir) or default_opts.source_dir
    state.build_types = util.resolve(user_opts.build_types) or default_opts.build_types
    state.build_type = util.resolve(user_opts.default_build_type) or default_opts.build_type
    state.build_target = default_opts.build_target

    state.user_args = state.user_args or {}
    state.user_args.configuration = util.resolve(user_opts.user_args.configuration) or default_opts.user_args.configuration
    state.user_args.build = util.resolve(user_opts.user_args.build) or default_opts.user_args.build

    vim.api.nvim_create_user_command("CMakeConfigure", function()
        M.configure_project()
    end, { desc = "CMake: Configure" })

    vim.api.nvim_create_user_command("CMakeBuild", function()
        M.build_project()
    end, {})

    state.is_setup = true
end

function M.is_setup()
    return state.is_setup
end

function M.is_project_directory()
    return cmake.is_project_directory()
end

function M.get_build_system_type()
    return "CMake"
end

function M.get_build_dir()
    return state.build_dir
end

function M.get_source_dir()
    return state.source_dir
end

function M.get_build_types()
    return state.build_types
end

function M.get_build_type()
    return state.build_type
end

function M.set_build_type(build_type)
    state.build_type = build_type
end

function M.get_build_targets()
    return cmake.get_active_build_targets(M.get_build_dir())
end

function M.get_build_target()
    return state.build_target
end

function M.set_build_target(build_target)
    state.build_target = build_target
end

function M.configure(
    cmake_executable_path,
    source_dir,
    build_dir,
    build_type,
    args)

    local base_error = "Failed creating CMake configuration command"

    if not util.is_executable(cmake_executable_path) then
        vim.notify(string.format("[%s] %s: CMake executable '%s' is not an executable", M.PLUGIN_NAME, base_error, cmake_executable_path), vim.log.levels.ERROR)
        return
    end

    local cmake_file = vim.fn.globpath(source_dir, "CMakeLists.txt")
    if #cmake_file == 0 then
        vim.notify(string.format("[%s] %s: Parameter 'source_dir' (%s) has no %s file", M.PLUGIN_NAME, base_error, source_dir, M.CMAKELISTS_FILE_NAME), vim.log.levels.ERROR)
        return
    end

    if build_dir == nil or build_dir == "" then
        vim.notify(string.format("[%s] %s: Parameter 'build_dir' has invalid value of '%s'", M.PLUGIN_NAME, base_error, build_dir), vim.log.levels.ERROR)
        return
    end

    if build_type == nil or build_type == "" then
        vim.notify(string.format("[%s] %s: Parameter 'build_type' has invalid valued of '%s'", M.PLUGIN_NAME, base_error, build_type), vim.log.levels.ERROR)
        return
    end

    local command = cmake.create_configure_command(
        cmake_executable_path,
        source_dir,
        build_dir,
        build_type,
        args
    )

    util.execute_command(command)
end

function M.configure_project()
    M.configure(
        state.cmake_executable_path,
        M.get_source_dir(),
        M.get_build_dir(),
        M.get_build_type(),
        state.user_args.configuration
    )
end

function M.build(
    cmake_executable_path,
    build_dir,
    build_type,
    args)

    local base_error = "Failed creating CMake build command"

    if not util.is_executable(cmake_executable_path) then
        vim.notfy(string.format("[%s] %s: CMake executable '%s' is not an executable", M.PLUGIN_NAME, base_error, cmake_executable_path), vim.log.levels.ERROR)
        return ""
    end

    if build_dir == nil or build_dir == "" then
        vim.notify(string.format("[%s] %s: Parameter 'build_dir' has invalid value of '%s'", M.PLUGIN_NAME, base_error, build_dir), vim.log.levels.ERROR)
        return
    end

    if build_type == nil or build_type == "" then
        vim.notify(string.format("[%s] %s: Parameter 'build_type' has invalid valued of '%s'", M.PLUGIN_NAME, base_error, build_type), vim.log.levels.ERROR)
        return
    end

    local command = cmake.create_build_command(
        cmake_executable_path,
        build_dir,
        build_type,
        args
    )

    util.execute_command(command)
end

function M.run_script(cmake_executable_path, vars, script_file)
    local base_error = "Failed running CMake script"

    if not util.is_executable(cmake_executable_path) then
        vim.notfy(string.format("[%s] %s: CMake executable '%s' is not an executable", M.PLUGIN_NAME, base_error, cmake_executable_path), vim.log.levels.ERROR)
        return ""
    end

    if vim.fn.filereadable(script_file) == 0 then
        vim.notfy(string.format("[%s] %s: CMake script '%s' is not a file", M.PLUGIN_NAME, base_error, script_file), vim.log.levels.ERROR)
        return ""
    end

    local command = cmake.create_run_script_command(
        cmake_executable_path,
        vars,
        script_file
    )
    util.execute_command(command)
end

function M.build_project()
    local user_args = ""
    for _, arg in ipairs(state.user_args.build) do
        user_args = string.format("%s %s", user_args, arg)
    end

    M.build(
        state.cmake_executable_path,
        M.get_build_dir(),
        M.get_build_type(),
        state.user_args.build
    )
end

function M.get_target_binary_relative_path(build_target_name)
    return cmake.get_target_binary_relative_path(
        state.cmake_executable_path,
        M.get_source_dir(),
        M.get_build_dir(),
        M.get_build_type(),
        state.user_args.configuration,
        build_target_name)
end

function M.get_target_binary_path(build_target)
    if build_target == "" then
        vim.notify(string.format("Can't run build target: '%s'", build_target), vim.log.levels.ERROR)
        return ""
    end

    local binary_relative_path = M.get_target_binary_relative_path(build_target)
    if binary_relative_path == nil or binary_relative_path == "" then
        return ""
    end

    local build_dir = state.build_dir
    local path = string.format("%s/%s/%s", vim.fn.getcwd(), build_dir, binary_relative_path)
    if vim.fn.filereadable(path) == 0 then
        vim.notify(string.format("binary not found: %s", path), vim.log.levels.ERROR)
        return ""
    end

    return path
end

function M.run_build_target()
    local build_target = state.build_target
    local path = M.get_target_binary_path(build_target)
    if vim.fn.filereadable(path) == 0 then
        vim.notify(string.format("binary not found: %s", path), vim.log.levels.ERROR)
        return
    end
    util.execute_command(path)
end

return M

