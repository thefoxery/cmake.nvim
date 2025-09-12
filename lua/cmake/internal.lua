
local M = {}

function M._create_configure_command(source_dir, build_dir, defines)
    return string.format("cmake -S %s -B %s %s", source_dir, build_dir, defines)
end

function M._create_build_command(build_dir, config)
    return string.format("cmake --build %s --config %s", build_dir, config)
end

function M._execute_command(command)
    vim.cmd("botright split | terminal echo executing: " .. command .. "; " .. command)
end

return M

