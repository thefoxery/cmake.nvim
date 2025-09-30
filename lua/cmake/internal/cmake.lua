
local util = require("cmake.internal.util")

local M = {}

M.CMAKELISTS_FILE_NAME = "CMakeLists.txt"

function M.is_project_directory()
    return vim.fn.glob(M.CMAKELISTS_FILE_NAME) ~= ""
end

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

function M.create_configure_command_trace(cmake_executable_path, source_dir, build_dir, build_type, args)
    local command = M.create_configure_command(
        cmake_executable_path,
        source_dir,
        build_dir,
        build_type,
        args
    )
    return string.format("%s --trace-expand 2>&1", command)
end

---
--- cmake --build <build-dir> <args>
---
function M.create_build_command(cmake_executable_path, build_dir, build_type, args)
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

local function parse_trace_line(line)
    local path, line_nr, command, raw_args = line:match("^(.-)%((%d+)%)%:%s+(.-)%((.-)%)$")

    if path then
        local args_parts = vim.split(vim.trim(raw_args), " ")

        local args = {}
        for _, args_part in ipairs(args_parts) do
            table.insert(args, vim.trim(args_part))
        end

        return {
            path = vim.trim(path),
            line_number = vim.trim(line_nr),
            command = vim.trim(command),
            args = args,
        }
    end
    return nil
end

function M.get_cmake_data(
    cmake_executable_path,
    source_dir,
    build_dir,
    build_type,
    args)

    local command = M.create_configure_command_trace(
        cmake_executable_path,
        source_dir,
        build_dir,
        build_type,
        args
    )

    local trace = {}

    local result = vim.fn.systemlist(command)
    if #result == 0 then
        return trace
    end

    local projects = {}

    local project = nil
    for _, line in ipairs(result) do
        local cmd = parse_trace_line(line)

        if cmd ~= nil then
            if cmd.command == "project" then
                if project ~= nil then
                    table.insert(projects, project)
                end

                local project_path = vim.fn.fnamemodify(cmd.path, ":.")
                project_path = vim.fn.fnamemodify(project_path, ":h")

                project = {
                    name = cmd.args[1],
                    build_targets = {
                        executables = {},
                        libraries = {},
                    },
                    path = project_path,
                }
            elseif cmd.command == "add_executable" then
                if project == nil then
                    return projects
                end

                local name = cmd.args[1]
                project.build_targets.executables[name] = {}
            elseif cmd.command == "add_library" then
                if project == nil then
                    return projects
                end

                local name = cmd.args[1]
                local library = {
                    type = "static",
                }

                if string.lower(cmd.args[2]) == "shared" then
                    library.type = "shared"
                end

                project.build_targets.libraries[name] = library
            end
        end

    end

    if project ~= nil then
        table.insert(projects, project)
    end

    return projects
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

function M.get_active_build_targets(build_dir)
    local build_targets = {}

    local result = vim.fn.systemlist(string.format("cmake --build %s --target help", build_dir))

    for i=2, #result do
        table.insert(build_targets, vim.split(vim.trim(result[i]), " ")[2])
    end
    return build_targets
end

function M.get_target_binary_relative_path(
    cmake_executable_path,
    source_dir,
    build_dir,
    build_type,
    args,
    build_target)

    local projects = M.get_cmake_data(
        cmake_executable_path,
        source_dir,
        build_dir,
        build_type,
        args
    )

    local platform = vim.loop.os_uname().sysname

    for _, project in ipairs(projects) do
        for name, _ in pairs(project.build_targets.executables) do
            if name == build_target then
                local binary_name = name
                local extension = ""
                if platform == "Linux" or platform == "Darwin" then
                    extension = ""
                elseif platform == "Windows" then
                    extension = ".exe"
                end

                return string.format("%s/%s%s", project.path, binary_name, extension)
            end
        end

        for name, library in pairs(project.build_targets.libraries) do
            if name == build_target then
                local binary_name = name
                local extension = ".a" -- default to static library for linux/darwin

                if library.type == "static" or "shared" then
                    if platform == "Linux" or platform == "Darwin" then
                        binary_name = "lib" .. binary_name
                    end

                    if library.type == "static" then
                        if platform == "Windows" then
                            extension = ".lib"
                        end
                    elseif library.type == "shared" then
                        if platform == "Linux" then
                            extension = ".so"
                        elseif platform == "Darwin" then
                            extension = ".dylib"
                        elseif platform == "Windows" then
                            extension = ".dll"
                        end
                    end
                else
                    return ""
                end

                return string.format("%s/%s%s", project.path, binary_name, extension)
            end
        end
    end

    return ""
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

