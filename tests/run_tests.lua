
package.path = "./tests/vendor/?.lua;./lua/?.lua;./lua/?/init.lua;" .. package.path

local luaunit = require("luaunit")

require("tests.test_telescope_build_interface")

os.exit(luaunit.LuaUnit.run())

