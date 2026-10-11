-- Test entry point. From the plugin folder:
--   lua tests/run.lua

local function scriptDir()
    local info = debug.getinfo(1, "S")
    local path = info.source:match("^@(.*)$") or ""
    return path:match("(.*[/\\])") or "./"
end

local testsDir = scriptDir()
local rootDir = testsDir .. "../"

package.path = rootDir .. "?.lua;"
    .. testsDir .. "?.lua;"
    .. rootDir .. "../LibNodeGraph/tests/?.lua;"
    .. package.path

local luaunit = require("luaunit")

require("fakes").install()
require("main")
require("test_restricted")

os.exit(luaunit.LuaUnit.run())
