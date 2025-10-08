
package.path = "./tests/vendor/?.lua;./lua/?.lua;./lua/?/init.lua;" .. package.path

local luaunit = require("luaunit")

require("tests.test_internal_util")
require("tests.test_telescope_build_interface")
require("tests.test_lualine_build_interface")

os.exit(luaunit.LuaUnit.run())

