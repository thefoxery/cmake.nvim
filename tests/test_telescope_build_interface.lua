
---
--- Tests to ensure compatibility with thefoxery/telescope-build.nvim plugin
---

local luaunit = require("luaunit")

local cmake = require("cmake")

TestTelescopeBuildInterface = {}

function TestTelescopeBuildInterface:test_get_build_types()
    luaunit.assertIsFunction(cmake.get_build_types)
end

function TestTelescopeBuildInterface:test_get_build_type()
    luaunit.assertIsFunction(cmake.get_build_type)
end

function TestTelescopeBuildInterface:test_get_build_targets()
    luaunit.assertIsFunction(cmake.get_build_targets)
end

function TestTelescopeBuildInterface:test_get_build_target()
    luaunit.assertIsFunction(cmake.get_build_target)
end

function TestTelescopeBuildInterface:test_set_build_type()
    luaunit.assertIsFunction(cmake.set_build_type)
end

function TestTelescopeBuildInterface:test_set_build_target()
    luaunit.assertIsFunction(cmake.set_build_target)
end

return TestTelescopeBuildInterface

