
---
--- Tests to ensure compatibility with thefoxery/lualine-build.nvim plugin
---

local luaunit = require("luaunit")

local cmake = require("cmake")

TestLualineBuildInterface = {}

function TestLualineBuildInterface:test_get_build_system_type()
    luaunit.assertIsFunction(cmake.get_build_system_type)
end

function TestLualineBuildInterface:test_get_build_type()
    luaunit.assertIsFunction(cmake.get_build_type)
end

function TestLualineBuildInterface:test_get_build_target()
    luaunit.assertIsFunction(cmake.get_build_target)
end

return TestLualineBuildInterface

