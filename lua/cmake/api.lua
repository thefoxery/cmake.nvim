
local config = require("cmake.config")
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
        install = {},
    },
}

function M.setup(user_opts)
    user_opts = user_opts or {}
    user_opts.user_args = user_opts.user_args or {}

    config.cmake_executable_path = util.resolve(user_opts.cmake_executable_path) or default_opts.cmake_executable_path
    config.build_dir = util.resolve(user_opts.build_dir) or default_opts.build_dir
    config.source_dir = util.resolve(user_opts.source_dir) or default_opts.source_dir
    config.build_types = util.resolve(user_opts.build_types) or default_opts.build_types
    config.build_type = util.resolve(user_opts.default_build_type) or default_opts.build_type
    config.build_target = default_opts.build_target

    config.user_args = config.user_args or {}
    config.user_args.configuration = util.resolve(user_opts.user_args.configuration) or default_opts.user_args.configuration
    config.user_args.build = util.resolve(user_opts.user_args.build) or default_opts.user_args.build
    config.user_args.install = util.resolve(user_opts.user_args.install) or default_opts.user_args.install

    require("cmake.commands")

    config.is_setup = true
end

function M.is_setup()
    return config.is_setup
end

function M.is_project_directory()
    return cmake.is_project_directory()
end

---
--- Low level API
---
function M.create_command(user_opts)
    local opts = vim.tbl_deep_extend("keep", user_opts or {}, config)
    if not util.is_executable(opts.cmake_executable_path) then
        vim.notify(string.format("[%s] Failed creating CMake command: Parameter 'cmake_executable_path' (%s) is not an executable", M.PLUGIN_NAME, opts.cmake_executable_path), vim.log.levels.ERROR)
        return ""
    end
    return cmake.create_command(opts.cmake_executable_path, opts.args or {})
end

---
--- Getters and Setters
---

function M.get_build_system_type()
    return "CMake"
end

function M.get_build_dir()
    return config.build_dir
end

function M.get_source_dir()
    return config.source_dir
end

function M.get_build_types()
    return config.build_types
end

function M.get_build_type()
    return config.build_type
end

function M.set_build_type(build_type)
    config.build_type = build_type
end

function M.get_build_targets()
    return cmake.get_active_build_targets(M.get_build_dir())
end

function M.get_build_target()
    return config.build_target
end

function M.set_build_target(build_target)
    config.build_target = build_target
end

---
--- Generate a project build system
---     cmake [<options>] -B <build-dir> [-S <source-dir>]
---     cmake [<options>] <source-dir | build-dir>
---
function M.generate(user_opts)
    local base_error = "Failed creating CMake configuration command"
    local opts = vim.tbl_deep_extend("keep", user_opts or {}, config)

    if not util.is_executable(opts.cmake_executable_path) then
        vim.notify(string.format("[%s] %s: CMake executable '%s' is not an executable", M.PLUGIN_NAME, base_error, opts.cmake_executable_path), vim.log.levels.ERROR)
        return false
    end

    local cmake_files = vim.fn.globpath(opts.source_dir, cmake.CMAKELISTS_FILE_NAME, false, true)
    if #cmake_files == 0 then
        vim.notify(string.format("[%s] %s: Parameter 'source_dir' (%s) has no %s file", M.PLUGIN_NAME, base_error, opts.source_dir, cmake.CMAKELISTS_FILE_NAME), vim.log.levels.ERROR)
        return false
    end

    if opts.build_dir == nil or opts.build_dir == "" then
        vim.notify(string.format("[%s] %s: Parameter 'build_dir' has invalid value of '%s'", M.PLUGIN_NAME, base_error, opts.build_dir), vim.log.levels.ERROR)
        return false
    end

    if opts.build_type == nil or opts.build_type == "" then
        vim.notify(string.format("[%s] %s: Parameter 'build_type' has invalid value of '%s'", M.PLUGIN_NAME, base_error, opts.build_type), vim.log.levels.ERROR)
        return false
    end

    local command = cmake.create_configure_command(
        opts.cmake_executable_path,
        opts.source_dir,
        opts.build_dir,
        opts.build_type,
        opts.user_args.configuration
    )

    util.execute_command(command)
    return true
end

---
--- Build a project
---     cmake --build <build-dir> [<options>] [-- <build-tool-options>]
---
function M.build(user_opts)
    local opts = vim.tbl_deep_extend("keep", user_opts or {}, config)
    local base_error = "Failed creating CMake build command"

    if not util.is_executable(opts.cmake_executable_path) then
        vim.notfy(string.format("[%s] %s: CMake executable '%s' is not an executable", M.PLUGIN_NAME, base_error, opts.cmake_executable_path), vim.log.levels.ERROR)
        return false
    end

    if opts.build_dir == nil or opts.build_dir == "" then
        vim.notify(string.format("[%s] %s: Parameter 'build_dir' has invalid value of '%s'", M.PLUGIN_NAME, base_error, opts.build_dir), vim.log.levels.ERROR)
        return false
    end

    if opts.build_type == nil or opts.build_type == "" then
        vim.notify(string.format("[%s] %s: Parameter 'build_type' has invalid value of '%s'", M.PLUGIN_NAME, base_error, opts.build_type), vim.log.levels.ERROR)
        return false
    end

    local command = cmake.create_build_command(
        opts.cmake_executable_path,
        opts.build_dir,
        opts.build_type,
        opts.user_args.build
    )

    util.execute_command(command)
    return true
end

---
--- Install a project
---     cmake --install <dir> [<options>]
---
function M.install(user_opts)
    local opts = vim.tbl_deep_extend("keep", user_opts or {}, config)
    local base_error = "Failed creating CMake install command"

    if not util.is_executable(opts.cmake_executable_path) then
        vim.notfy(string.format("[%s] %s: CMake executable '%s' is not an executable", M.PLUGIN_NAME, base_error, opts.cmake_executable_path), vim.log.levels.ERROR)
        return false
    end

    if opts.build_dir == nil or opts.build_dir == "" then
        vim.notify(string.format("[%s] %s: Parameter 'build_dir' has invalid value of '%s'", M.PLUGIN_NAME, base_error, opts.build_dir), vim.log.levels.ERROR)
        return false
    end

    opts.user_args.install = opts.user_args.install or {}

    local command = cmake.create_install_command(
        opts.cmake_executable_path,
        opts.build_dir,
        opts.user_args.install
    )

    util.execute_command(command)
    return true
end

function M.uninstall(user_opts)
    local opts = vim.tbl_deep_extend("keep", user_opts or {}, config)
    local base_error = "Failed creating CMake uninstall command"

    if opts.build_dir == nil or opts.build_dir == "" then
        vim.notify(string.format("[%s] %s: Parameter 'build_dir' has invalid value of '%s'", M.PLUGIN_NAME, base_error, opts.build_dir), vim.log.levels.ERROR)
        return false
    end

    local command = cmake.create_uninstall_commmand(opts.build_dir)
    util.execute_command(command)
    return true
end

---
--- Run command line tool
---     cmake -E <command> [<options>]
---
function M.run_cmdline_tool(cmake_executable_path, command, options)
    local base_error = "Failed creating run cmdline tool command"
    if not util.is_executable(cmake_executable_path) then
        vim.notfy(string.format("[%s] %s: CMake executable '%s' is not an executable", M.PLUGIN_NAME, base_error, cmake_executable_path), vim.log.levels.ERROR)
        return false
    end

    local cmd = cmake.create_run_cmdline_tool_command(cmake_executable_path, command, options)
    util.execute_command(cmd)
    return true
end

---
--- Run a script
---     cmake [ -D <var>=<value> ]... -P <cmake-script-file> [-- <unparsed-options>...]
---
function M.run_cmake_script(cmake_executable_path, vars, cmake_script_file)
    local base_error = "Failed running CMake script"

    if not util.is_executable(cmake_executable_path) then
        vim.notfy(string.format("[%s] %s: CMake executable '%s' is not an executable", M.PLUGIN_NAME, base_error, cmake_executable_path), vim.log.levels.ERROR)
        return false
    end

    if vim.fn.filereadable(cmake_script_file) == 0 then
        vim.notfy(string.format("[%s] %s: CMake script '%s' is not a file", M.PLUGIN_NAME, base_error, cmake_script_file), vim.log.levels.ERROR)
        return false
    end

    local command = cmake.create_run_script_command(
        cmake_executable_path,
        vars,
        cmake_script_file
    )

    util.execute_command(command)
    return true
end

---
--- Presets
---

function M.configure_preset(user_opts)
    local opts = vim.tbl_deep_extend("keep", user_opts or {}, config)
    local presets = cmake.get_presets(opts.cmake_executable_path, "configure")

    for _, preset in ipairs(presets) do
        if preset.name == user_opts.preset then
            local args = {
                string.format("--preset=%s", opts.preset),
            }

            local command = cmake.create_command(
                opts.cmake_executable_path,
                args
            )

            util.execute_command(command)
            return true
        end
    end

    vim.notify(string.format("Preset '%s' is not a valid preset", user_opts.preset), vim.log.levels.ERROR)
    return false
end

function M.build_preset(user_opts)
    local opts = vim.tbl_deep_extend("keep", user_opts or {}, config)
    local presets = cmake.get_presets(opts.cmake_executable_path, "build")

    for _, preset in ipairs(presets) do
        if preset.name == user_opts.preset then
            local args = {
                "--build",
                string.format("--preset=%s", opts.preset),
            }

            local command = cmake.create_command(
                opts.cmake_executable_path,
                args
            )

            util.execute_command(command)
            return true
        end
    end

    vim.notify(string.format("Preset %s is not a valid preset", user_opts.preset), vim.log.levels.ERROR)
    return false
end

---
--- Run
---

function M.get_target_binary_relative_path(build_target_name)
    return cmake.get_target_binary_relative_path(
        config.cmake_executable_path,
        M.get_source_dir(),
        M.get_build_dir(),
        M.get_build_type(),
        config.user_args.configuration,
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

    local build_dir = config.build_dir
    local path = string.format("%s/%s/%s", vim.fn.getcwd(), build_dir, binary_relative_path)
    if vim.fn.filereadable(path) == 0 then
        vim.notify(string.format("binary not found: %s", path), vim.log.levels.ERROR)
        return ""
    end

    return path
end

function M.run_build_target()
    local build_target = config.build_target
    local path = M.get_target_binary_path(build_target)
    if vim.fn.filereadable(path) == 0 then
        vim.notify(string.format("binary not found: %s", path), vim.log.levels.ERROR)
        return
    end
    util.execute_command(path)
end

return M

