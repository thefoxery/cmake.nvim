
local M = {}

function M.resolve(opt)
    if type(opt) == "function" then
        return opt()
    else
        return opt
    end
end

function M.args_to_string(args)
    local s = ""
    for i, arg in ipairs(args) do
        if i > 0 then
            s = s .. " "
        end
        s = s .. vim.trim(arg)
    end
    return s
end

function M.is_executable(path)
    if path == nil or path == "" then
        return false
    end
    return true -- TODO: implement
end

function M.execute_command(command)
    vim.cmd("botright split | terminal echo executing: " .. command .. "; " .. command)
end

function M.read_file(path)
    local f = assert(io.open(path, "r"))
    local data = f:read("*a")
    f:close()
    return data
end

function M.trim_quotes(text)
    if text:sub(1, 1) == "\"" and text:sub(-1) == "\"" then
        text = text:sub(2, #text - 1)
    end

    return text
end

function M.escape_regex_string(str)
    return str:gsub("[%W%?%+%-%.%*%^%$%[%]%(%)]", "%%%1")
end

return M

