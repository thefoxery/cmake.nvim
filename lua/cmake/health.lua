
local api = require("cmake.api")

local M = {}

function M.check()
    local health = vim.health or require("health")

    health.start(
        string.format("%s health check", api.PLUGIN_NAME)
    )

    if not api.is_setup() then
        health.error(
            string.format("%s is not set up. Please configuration to run require(\"cmake\").setup() to configure the plugin.", api.PLUGIN_NAME)
        )
        return
    else
        health.ok(" - Plugin is configured")
    end
end

return M

