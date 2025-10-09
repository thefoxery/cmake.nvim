
local util = require("cmake.internal.util")

local M = {}

M.CMAKELISTS_FILE_NAME = "CMakeLists.txt"

function M.is_project_directory()
    return vim.fn.glob(M.CMAKELISTS_FILE_NAME) ~= ""
end

function M.create_command(cmake_executable_path, args)
    local command = cmake_executable_path
    if args and #args > 0 then
        command = string.format("%s %s", command, table.concat(args, " "))
    end
    return command
end

function M.create_configure_command(cmake_executable_path, source_dir, build_dir, build_type, args)
    local all_args = {
        string.format("-S %s", source_dir),
        string.format("-B %s", build_dir),
        string.format("-DCMAKE_BUILD_TYPE=%s", build_type),
    }

    for _, arg in ipairs(args) do
        table.insert(all_args, arg)
    end

    return M.create_command(cmake_executable_path, all_args)
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

function M.create_build_command(cmake_executable_path, build_dir, build_type, args)
    local all_args = {
        string.format("--build %s", build_dir),
        string.format("--config %s", build_type),
    }

    for _, arg in ipairs(args) do
        table.insert(all_args, arg)
    end

    return M.create_command(cmake_executable_path, all_args)
end

function M.create_install_command(cmake_executable_path, install_dir, options)
    local all_args = {
        string.format("--install %s", install_dir)
    }

    options = options or {}
    for _, option in ipairs(options) do
        table.insert(all_args, option)
    end

    print(vim.inspect(all_args))

    return M.create_command(cmake_executable_path, all_args)
end

function M.create_uninstall_command(build_dir)
    return string.format("xargs rm -v < %s/install_manifest.txt", build_dir)
end

function M.create_run_script_command(cmake_executable_path, vars, script_file)
    vars = vars or {}

    local args = {}
    for var, value in pairs(vars) do
        table.insert(args, string.format("-D %s=%s", var, value))
    end

    table.insert(args, string.format("-P %s", script_file))

    return M.create_command(cmake_executable_path, args)
end

function M.create_run_cmdline_tool_command(cmake_executable_path, command, options)
    local args = {
        string.format("-E %s", command)
    }

    options = options or {}
    for _, option in ipairs(options) do
        table.insert(args, option)
    end

    return M.create_command(cmake_executable_path, args)
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

function M.get_active_build_targets(build_dir)
    local build_targets = {}

    local result = vim.fn.systemlist(string.format("cmake --build %s --target help", build_dir))

    for i=2, #result do
        table.insert(build_targets, vim.split(vim.trim(result[i]), " ")[2])
    end
    return build_targets
end

function M.get_capabilities(cmake_executable_path)
    local handle = io.popen(string.format("%s -E capabilities 2>/dev/null", cmake_executable_path)) -- available from CMake 3.19
    if not handle then return {} end

    local output = handle:read("*a")
    handle:close()

    local ok, data = pcall(vim.json.decode, output)
    if not ok or type(data) ~= "table" then
        vim.notify("[cmake.nvim] Failed to parse CMake capabilities output", vim.log.levels.ERROR)
        return {}
    end

    return data
end

function M.get_generators(cmake_executable_path)
    local handle = io.popen(string.format("%s -E capabilities 2>/dev/null", cmake_executable_path)) -- available from CMake 3.19
    if not handle then return {} end

    local output = handle:read("*a")
    handle:close()

    local ok, data = pcall(vim.json.decode, output)
    if not ok or type(data) ~= "table" then
        return {}
    end

    if data.generators then
        return data.generators
    end

    return {}
end

function M.get_generators_legacy(cmake_executable_path)
    ---
    --- Keep this for now, in case we want to support older CMake versions
    ---
    local handle = io.popen(string.format("LANG=C %s --help", cmake_executable_path))
    if not handle then return {} end

    local result = handle:read("*a")
    handle:close()

    result = result:match("Generators(.-)$")
    if not result then return {} end

    local raw_lines = vim.split(result, "\n")

    local generators = {}
    for _, line in ipairs(raw_lines) do
        if line ~= "" then
            local is_default, generator, desc = line:match("^([%*]*)(.+)=(.+)")
            if generator and desc then
                table.insert(generators, {
                    is_default = is_default == "*",
                    generator = vim.trim(generator),
                    desc = vim.trim(desc),
                })
            end
        end
    end

    return generators
end

function M.get_presets(cmake_executable_path, type)
    local presets = {}

    local result = vim.fn.systemlist(string.format("%s --list-presets=%s", cmake_executable_path, type))
    for i=3, #result do
        local line = result[i]
        local name, desc = line:match("(.+)%-(.+)")
        if name and desc then
            table.insert(presets, {
                name = util.trim_quotes(vim.trim(name)),
                desc = vim.trim(desc)
            })
        end
    end

    return presets
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

