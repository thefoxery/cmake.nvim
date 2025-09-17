
local M = {}

M._CMAKELISTS_FILE_NAME = "CMakeLists.txt"

function M._resolve(opt)
    if type(opt) == "function" then
        return opt()
    else
        return opt
    end
end

function M._create_configure_command(source_dir, build_dir, defines)
    return string.format("cmake -S %s -B %s %s", source_dir, build_dir, defines)
end

function M._create_build_command(build_dir, config, user_args)
    return string.format("cmake --build %s --config %s %s", build_dir, config, user_args)
end

function M._execute_command(command)
    vim.cmd("botright split | terminal echo executing: " .. command .. "; " .. command)
end

function M._read_file(path)
    local f = assert(io.open(path, "r"))
    local data = f:read("*a")
    f:close()
    return data
end

function M._get_build_targets_data()
    local cmakelists_files = {}
    M._get_cmakelists_files(vim.fn.getcwd(), cmakelists_files)

    if #cmakelists_files == 0 then
        return
    end

    local build_targets = {}
    for _, file in ipairs(cmakelists_files) do
        local project = M._get_project(file)
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

function M._get_subdirectories(buffer)
    local blocks = {}
    for block in buffer:gmatch("add_subdirectory%((.-)%)") do
        table.insert(blocks, vim.trim(block))
    end
    return blocks
end

function M._get_cmakelists_files(root_directory, cmakelists_files)
    if root_directory == nil or root_directory == "" then
        return
    end

    if cmakelists_files == nil then
        return
    end

    local path = string.format("%s/%s", root_directory, M._CMAKELISTS_FILE_NAME)
    if vim.fn.filereadable(path) == 0 then
        return
    end

    table.insert(cmakelists_files, path)

    local buffer = M._read_cmakelists_file(path)
    local subdirectories = M._get_subdirectories(buffer)

    for _, relative_dir in ipairs(subdirectories) do
        local full_dir = string.format("%s/%s", root_directory, relative_dir)
        M._get_cmakelists_files(full_dir, cmakelists_files)
    end
end

function M._get_project(file)
    local data = M._read_file(file)

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

function M._read_cmakelists_file(path)
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

return M

