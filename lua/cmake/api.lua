
local internal = require("cmake.internal")
local state = require("cmake.state")

local M = {}

local CMAKELISTS_FILE_NAME = "CMakeLists.txt"

local default_build_types = { "MinSizeRel", "Debug", "Release", "RelWithDebInfo" }

local resolve = function(parameter)
    if type(parameter) == "function" then
        return parameter()
    else
        return parameter
    end
end

function M.setup(opts)
    opts = opts or {}
    state.build_dir = resolve(opts.build_dir) or "build"
    state.build_types = resolve(opts.build_types) or default_build_types
    state.build_type = resolve(opts.default_build_type) or "Debug"
    state.build_target = ""

    opts.user_args = resolve(opts.user_args) or {}
    for _, arg in ipairs(opts.user_args) do
        state.user_args = string.format("%s %s", state.user_args, arg)
    end

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

function M.is_cmake_project()
    return vim.fn.glob(CMAKELISTS_FILE_NAME) ~= ""
end

function M.get_build_dir()
    return state.build_dir
end

function M.get_source_dir()
    return "."
end

function M.set_build_type(build_type)
    state.build_type = build_type
    print(string.format("build type set to '%s'", build_type))
end

function M.get_build_type()
    return state.build_type
end

function M.get_build_types()
    return state.build_types
end

function M.set_build_target(build_target)
    state.build_target = build_target
    print(string.format("build target set to '%s'", build_target))
end

function M.get_build_target()
    return state.build_target
end

function M.configure_project()
    local command = internal._create_configure_command(
        M.get_source_dir(),
        M.get_build_dir(),
        string.format("%s -DCMAKE_BUILD_TYPE=%s", state.user_args, state.build_type)
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

function M.get_target_binary_path(build_target_name)
    if build_target_name == nil or build_target_name == "" then
        return ""
    end

    local platform = vim.loop.os_uname().sysname

    local build_targets = M.get_build_targets()
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

function M.run_build_target()
    local build_target = state.build_target
    local build_dir = state.build_dir
    if build_target == "" then
        print(string.format("Can't run build target: '%s'", build_target))
        return
    end

    local binary_relative_path = M.get_target_binary_path(build_target)
    if binary_relative_path == nil or binary_relative_path == "" then
        return
    end

    local path = string.format("%s/%s/%s", vim.fn.getcwd(), build_dir, binary_relative_path)
    if vim.fn.filereadable(path) == 0 then
        print(string.format("binary not found: %s", path))
        return
    end
    internal._execute_command(path)
end

function M.read_cmakelists_file(path)
    local lines = {}
    if vim.fn.filereadable(path) == 0 then
        return lines
    end

    for line in io.lines(path) do
        local code = line:match("^(.-)#") or line
        code = vim.trim(code)
        if code and code ~= "" then
            table.insert(lines, code)
        end
    end

    if lines == nil or #lines == 0 then
        return ""
    end

    local buffer = ""
    for _, line in ipairs(lines) do
        buffer = string.format("%s%s\n", buffer, line)
    end
    return buffer
end

function M.get_subdirectories(buffer)
    local blocks = {}
    for block in buffer:gmatch("add_subdirectory%((.-)%)") do
        table.insert(blocks, vim.trim(block))
    end
    return blocks
end

function M.get_cmakelists_files(root_directory, cmakelists_files)
    if root_directory == nil or root_directory == "" then
        return
    end

    if cmakelists_files == nil then
        return
    end

    local path = string.format("%s/%s", root_directory, CMAKELISTS_FILE_NAME)
    if vim.fn.filereadable(path) == 0 then
        return
    end

    table.insert(cmakelists_files, path)

    local buffer = M.read_cmakelists_file(path)
    local subdirectories = M.get_subdirectories(buffer)

    for _, relative_dir in ipairs(subdirectories) do
        local full_dir = string.format("%s/%s", root_directory, relative_dir)
        M.get_cmakelists_files(full_dir, cmakelists_files)
    end
end

function M.get_build_targets()
    local cmakelists_files = {}
    M.get_cmakelists_files(vim.fn.getcwd(), cmakelists_files)

    if #cmakelists_files == 0 then
        return
    end

    local build_targets = {}
    for _, file in ipairs(cmakelists_files) do
        local project = M.get_project(file)
        if project and project.build_targets and #project.build_targets > 0 then
            for _, target in ipairs(project.build_targets) do
                build_targets[target.name] = {
                    type = target.type,
                    path = project.path,
                }
            end
        end
    end

    return build_targets
end

function M.read_file(path)
    local f = assert(io.open(path, "r"))
    local data = f:read("*a")
    f:close()
    return data
end

function M.get_project(file)
    local data = M.read_file(file)

    local project = {}
    for block in data:gmatch("project%((.-)%)") do -- assumes project name is not a variable
        block = vim.trim(block)
        project = project or {}
        project.name = vim.split(block, " ")[1]
    end

    if project == nil or project.name == nil then
        print("no project info found")
        return project
    end

    project.build_targets = project.build_targets or {}

    for block in data:gmatch("add_executable%((.-)%)") do
        -- TODO: extract token replacement and make it more sophisticated
        -- TODO: just splitting on space may break in some cases, in case we want to get more information out of this
        block = block:gsub("${PROJECT_NAME}", project.name)
        block = block:gsub("\n", "")
        local parts = vim.split(block, " ")
        for _, part in ipairs(parts) do
            part = vim.trim(part)
            if part ~= "" then
                local build_target = {
                    name = part,
                    type = "executable",
                }
                table.insert(project.build_targets, build_target)
                break
            end
        end
    end

    for block in data:gmatch("add_library%((.-)%)") do
        block = block:gsub("${PROJECT_NAME}", project.name):gsub("\n", "")
        local parts = vim.split(block, " ")
        local build_target = {
            name = vim.trim(parts[1]),
        }

        local library_type = vim.trim(parts[2])
        if string.lower(library_type) == "static" then
            build_target.type = "static_library"
        elseif string.lower(library_type) == "shared" then
            build_target.type = "shared_library"
        else
            -- if not specified, cmake defaults to static
            build_target.type = "static_library"
        end
        table.insert(project.build_targets, build_target)
    end

    project.path = vim.fn.fnamemodify(file, ":.")
    project.path = vim.fn.fnamemodify(project.path, ":h")

    return project
end

function M.get_build_target_names()
    local build_targets = vim.fn.systemlist("cmake --build build --target help")

    local build_target_names = {}
    for i=2, #build_targets do
        table.insert(build_target_names, vim.split(vim.trim(build_targets[i]), " ")[2])
    end
    return build_target_names
end

return M

