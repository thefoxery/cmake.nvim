
local luaunit = require("luaunit")

local util = require("cmake.internal.util")

TestInternalUtil = {}

function TestInternalUtil:test_trim_single_quotes()
    local bare_text = "hello"
    local quoted_text = string.format("'%s'", bare_text)

    luaunit.assertEquals(util.trim_quotes(quoted_text), bare_text)
end

function TestInternalUtil:test_trim_double_quotes()
    local bare_text = "hello"
    local quoted_text = string.format("\"%s\"", bare_text)

    luaunit.assertEquals(util.trim_quotes(quoted_text), bare_text)
end

function TestInternalUtil:test_trim_unquoted()
    local bare_text = "hello"
    luaunit.assertEquals(util.trim_quotes(bare_text), bare_text)
end

function TestInternalUtil:test_trim_partially_quoted()
    local bare_text = "hello"
    local left_quoted_text = string.format("%s\"", bare_text)
    local right_quoted_text = string.format("\"%s", bare_text)

    luaunit.assertEquals(util.trim_quotes(left_quoted_text), left_quoted_text)
    luaunit.assertEquals(util.trim_quotes(right_quoted_text), right_quoted_text)
end

return TestInternalUtil

