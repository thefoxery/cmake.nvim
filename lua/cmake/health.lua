
local api = require("cmake.api")
local config = require("cmake.config")

local M = {}

function M.check()
    local health = vim.health or require("health")

    health.start(
        string.format("%s health check", api.PLUGIN_NAME)
    )

    if not api.is_setup() then
        health.error(
            string.format(" - %s is not set up. Make sure to run require(\"cmake\").setup() to configure the plugin.", api.PLUGIN_NAME)
        )
        return
    else
        health.ok(" - Plugin is configured")
    end

    if config.cmake_executable_path == nil or config.cmake_executable_path == "" then
        health.error(" - CMake executable path is not set. Please set cmake_executable_path in the configuration.")
    else
        local handle = io.popen(string.format('"%s" --version', config.cmake_executable_path))
        if not handle then
            health.error(string.format(" - CMake executable not found at '%s'. Make sure the path is correct.", config.cmake_executable_path))
        else
            local result = handle:read("*a")
            handle:close()
            if result and result:match("cmake version") then
                health.ok(string.format(" - Found CMake executable at '%s'", config.cmake_executable_path))
            end
        end
    end
end

return M

