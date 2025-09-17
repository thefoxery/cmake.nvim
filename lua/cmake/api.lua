
local internal = require("cmake.internal")
local state = require("cmake.state")

local M = {}

local default_opts = {
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

    state.build_dir = internal._resolve(user_opts.build_dir) or default_opts.build_dir
    state.source_dir = internal._resolve(user_opts.source_dir) or default_opts.source_dir
    state.build_types = internal._resolve(user_opts.build_types) or default_opts.build_types
    state.build_type = internal._resolve(user_opts.default_build_type) or default_opts.build_type
    state.build_target = internal._resolve(user_opts.build_target) or default_opts.build_target

    state.user_args = state.user_args or {}
    state.user_args.configuration = internal._resolve(user_opts.user_args.configuration) or default_opts.user_args.configuration
    state.user_args.build = internal._resolve(user_opts.user_args.build) or default_opts.user_args.build

    vim.api.nvim_create_user_command("CMakeConfigure", function()
        M.configure_project()
    end, {})

    vim.api.nvim_create_user_command("CMakeBuild", function()
        M.build_project()
    end, {})

    state.is_setup = true
end

function M.is_setup()
    return state.is_setup
end

function M.is_project_directory()
    return vim.fn.glob(internal._CMAKELISTS_FILE_NAME) ~= ""
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
    local build_targets = vim.fn.systemlist(string.format("cmake --build %s --target help", M.get_build_dir()))

    local build_target_names = {}
    for i=2, #build_targets do
        table.insert(build_target_names, vim.split(vim.trim(build_targets[i]), " ")[2])
    end
    return build_target_names
end

function M.get_build_target()
    return state.build_target
end

function M.set_build_target(build_target)
    state.build_target = build_target
end

function M.configure_project()
    local user_args = ""
    for i, arg in ipairs(state.user_args.configuration) do
        print(i)
        user_args = string.format("%s %s", user_args, arg)
    end

    local command = internal._create_configure_command(
        M.get_source_dir(),
        M.get_build_dir(),
        string.format("-DCMAKE_BUILD_TYPE=%s %s", state.build_type, user_args)
    )
    internal._execute_command(command)
end

function M.build_project()
    local user_args = ""
    for _, arg in ipairs(state.user_args.build) do
        user_args = string.format("%s %s", user_args, arg)
    end

    local command = internal._create_build_command(
        M.get_build_dir(),
        M.get_build_type(),
        user_args
    )
    internal._execute_command(command)
end

function M.get_target_binary_relative_path(build_target_name)
    if build_target_name == nil or build_target_name == "" then
        return ""
    end

    local platform = vim.loop.os_uname().sysname

    local build_targets = internal._get_build_targets_data()
    if build_targets == nil then
        return ""
    end

    local build_target = build_targets[build_target_name]
    if build_target == nil then
        return ""
    end

    local binary_name = build_target_name
    local extension = ".a" -- default to static library for Linux/MacOS

    if build_target.type == "executable" then
        if platform == "Linux" or platform == "Darwin" then
            extension = ""
        elseif platform == "Windows" then
            extension = ".exe"
        end
    elseif build_target.type == "static_library" or "shared_library" then
        if platform == "Linux" or platform == "Darwin" then
            binary_name = "lib" .. binary_name
        end

        if build_target.type == "static_library" then
            if platform == "Windows" then
                extension = ".lib"
            end
        elseif build_target.type == "shared_library" then
            if platform == "Linux" then
                extension = ".so"
            elseif platform == "Darwin" then
                extension = ".dylib"
            elseif platform == "Windows" then
                extension = ".dll"
            end
        end
    end

    return string.format("%s/%s%s", build_target.path, binary_name, extension)
end

function M.get_target_binary_path(build_target)
    if build_target == "" then
        vim.notify(string.format("Can't run build target: '%s'", build_target), vim.log.levels.ERROR)
        return ""
    end

    local binary_relative_path = M.get_target_binary_relative_path(build_target)
    print("binary_relative_path: " .. binary_relative_path)
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
    internal._execute_command(path)
end

return M

