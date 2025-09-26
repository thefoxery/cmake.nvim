
local util = require("cmake.internal.util")

local M = {}

M.CMAKELISTS_FILE_NAME = "CMakeLists.txt"
M.PLUGIN_NAME = "cmake.nvim"

function M.create_cmake_command(cmake_executable_path, args)
    local command = cmake_executable_path
    if args and #args > 0 then
        command = string.format("%s %s", command, util.args_to_string(args))
    end
    return command
end

---
--- cmake [options] <source-dir> <build_options> | <existing build dir>
---

function M.create_configure_command(cmake_executable_path, source_dir, build_dir, build_type, args)
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

    local all_args = {
        string.format("-S %s", source_dir),
        string.format("-B %s", build_dir),
        string.format("-DCMAKE_BUILD_TYPE=%s", build_type),
    }

    for _, arg in ipairs(args) do
        table.insert(all_args, arg)
    end

    return M.create_cmake_command(cmake_executable_path, all_args)
end

---
--- cmake --build <build-dir> <args>
---

function M.create_build_command(cmake_executable_path, build_dir, build_type, args)
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

    local all_args = {
        string.format("--build %s", build_dir),
        string.format("--config %s", build_type),
    }

    for _, arg in ipairs(args) do
        table.insert(all_args, arg)
    end

    return M.create_cmake_command(cmake_executable_path, all_args)
end

function M.get_subdirectories(buffer)
    local blocks = {}
    for block in buffer:gmatch("add_subdirectory%((.-)%)") do
        table.insert(blocks, vim.trim(block))
    end
    return blocks
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

function M.get_cmakelists_files(root_directory, cmakelists_files)
    if root_directory == nil or root_directory == "" then
        return
    end

    if cmakelists_files == nil then
        return
    end

    local path = string.format("%s/%s", root_directory, M.CMAKELISTS_FILE_NAME)
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

function M.get_project(file)
    local data = util.read_file(file)

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

function M.get_build_targets_data()
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

return M

