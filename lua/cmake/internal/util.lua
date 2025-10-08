
local M = {}

function M.resolve(opt)
    if type(opt) == "function" then
        return opt()
    else
        return opt
    end
end

function M.is_executable(path)
    if path == nil or path == "" then
        return false
    end
    return vim.fn.executable(path) == 1
end

function M.execute_command(command, opts)
    opts = opts or {}

    if opts.dry_run then
        print(string.format("[dry run] %s", command))
        return
    end

    vim.cmd("botright split | terminal echo executing: " .. command .. "; " .. command)
end

function M.read_file(path)
    local f = assert(io.open(path, "r"))
    local data = f:read("*a")
    f:close()
    return data
end

function M.trim_quotes(text)
    if (text:sub(1, 1) == "\"" and text:sub(-1) == "\"") or (text:sub(1, 1) == "\'" and text:sub(-1) == "\'") then
        text = text:sub(2, #text - 1)
    end

    return text
end

function M.escape_regex_string(str)
    return str:gsub("[%W%?%+%-%.%*%^%$%[%]%(%)]", "%%%1")
end

return M

