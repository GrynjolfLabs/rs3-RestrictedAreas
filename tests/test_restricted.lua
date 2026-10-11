local luaunit = require("luaunit")
local fakes = require("fakes")
local lists = require("areas")

local function area(label, x1, z1, level1, x2, z2, level2)
    return {
        label = label,
        corners = {
            { x = x1, z = z1, level = level1 },
            { x = x2, z = z2, level = level2 },
        },
    }
end

TestRestrictedAreas = {}

function TestRestrictedAreas:setUp()
    fakes.reset()
    lists.blacklist = {}
    lists.whitelist = {}
    self.names = {}
end

function TestRestrictedAreas:watch(name)
    local calls = {}
    local function callback(...)
        calls[#calls + 1] = { n = select("#", ...), value = select(1, ...) }
    end
    RestrictedAreas.Subscribe(name, callback)
    self.names[#self.names + 1] = name
    return calls
end

function TestRestrictedAreas:tearDown()
    for i = 1, #self.names do
        RestrictedAreas.Unsubscribe(self.names[i])
    end
    lists.blacklist = {}
    lists.whitelist = {}
end

function TestRestrictedAreas:testOverworldOutsideEveryBlacklistIsNotRestricted()
    fakes.setPlayer(10, 10, 0)
    fakes.setInstance(false, nil)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), false)
end

function TestRestrictedAreas:testOverworldBlacklistTileIsRestricted()
    lists.blacklist = { area("Blacklist yard", 10, 20, 0, 12, 22, 0) }
    fakes.setPlayer(11, 21, 0)
    fakes.setInstance(false, nil)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testIsRestrictedReturnsOneBoolean()
    fakes.setPlayer(10, 10, 0)
    local answer = RestrictedAreas.IsRestricted()
    luaunit.assertEquals(type(answer), "boolean")
    luaunit.assertEquals(select("#", RestrictedAreas.IsRestricted()), 1)
end

function TestRestrictedAreas:testIsRestrictedIgnoresArgumentsAndReadsThePlayer()
    lists.blacklist = { area("Argument trap", 50, 50, 0, 50, 50, 0) }
    fakes.setPlayer(1, 1, 0)
    fakes.setInstance(false, nil)
    luaunit.assertEquals(RestrictedAreas.IsRestricted({ x = 50, z = 50, level = 0 }), false)
end

function TestRestrictedAreas:testIsRestrictedAnswersWhenNobodyIsSubscribed()
    lists.blacklist = { area("Pull", 4, 4, 0, 6, 6, 0) }
    fakes.setPlayer(5, 5, 0)
    luaunit.assertEquals(fakes.isTicking(), false)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testWhitelistOnTheOverworldDoesNothing()
    lists.whitelist = { area("Overworld safe", 10, 10, 0, 12, 12, 0) }
    fakes.setPlayer(11, 11, 0)
    fakes.setInstance(false, nil)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), false)
end

function TestRestrictedAreas:testOverworldBlacklistWinsOverWhitelist()
    lists.blacklist = { area("Denied", 10, 10, 0, 12, 12, 0) }
    lists.whitelist = { area("Also listed", 10, 10, 0, 12, 12, 0) }
    fakes.setPlayer(11, 11, 0)
    fakes.setInstance(false, nil)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testOriginTileInABlacklistIsRestricted()
    -- Level 0 and tile 0 are real coordinates, not missing fields.
    lists.blacklist = { area("Origin", 0, 0, 0, 0, 0, 0) }
    fakes.setPlayer(0, 0, 0)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testBothCornerTilesAreIncluded()
    lists.blacklist = { area("Edge", 10, 20, 0, 12, 22, 1) }
    fakes.setInstance(false, nil)
    fakes.setPlayer(10, 20, 0)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
    fakes.setPlayer(12, 22, 1)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testTileJustOutsideAnAreaIsNotRestricted()
    lists.blacklist = { area("Edge", 10, 20, 0, 12, 22, 1) }
    fakes.setInstance(false, nil)
    fakes.setPlayer(9, 20, 0)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), false)
    fakes.setPlayer(12, 23, 1)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), false)
end

function TestRestrictedAreas:testCornerOrderDoesNotMatter()
    lists.blacklist = { area("Flipped", 12, 22, 1, 10, 20, 0) }
    fakes.setPlayer(10, 20, 0)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
    fakes.setPlayer(11, 21, 1)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testLevelSpanIncludesEveryPlaneInTheSameRectangle()
    lists.blacklist = { area("Planes", 10, 10, 0, 12, 12, 2) }
    fakes.setInstance(false, nil)
    fakes.setPlayer(11, 11, 0)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
    fakes.setPlayer(11, 11, 1)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
    fakes.setPlayer(11, 11, 2)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
    fakes.setPlayer(11, 11, 3)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), false)
    fakes.setPlayer(9, 11, 1)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), false)
end

function TestRestrictedAreas:testMalformedAreaIsSkippedAndTheRestApply()
    lists.blacklist = {
        { label = "missing x", corners = { { z = 0, level = 0 }, { x = 5, z = 5, level = 0 } } },
        { label = "missing z", corners = { { x = 0, level = 0 }, { x = 5, z = 5, level = 0 } } },
        { label = "missing level", corners = { { x = 0, z = 0 }, { x = 5, z = 5, level = 0 } } },
        area("Still applies", 100, 100, 0, 102, 102, 0),
    }
    fakes.setInstance(false, nil)
    fakes.setPlayer(0, 0, 0)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), false)
    fakes.setPlayer(5, 5, 0)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), false)
    fakes.setPlayer(101, 101, 0)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testSharedLabelIsNotAnIdentity()
    lists.blacklist = {
        area("Door", 0, 0, 0, 2, 2, 0),
        area("Door", 10, 10, 0, 12, 12, 0),
    }
    fakes.setInstance(false, nil)
    fakes.setPlayer(1, 1, 0)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
    fakes.setPlayer(11, 11, 0)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
    fakes.setPlayer(5, 5, 0)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), false)
end

function TestRestrictedAreas:testInstanceBlacklistUsesTheSourceTile()
    lists.blacklist = { area("Source black", 100, 100, 0, 110, 110, 0) }
    fakes.setPlayer(1, 1, 0)
    fakes.setInstance(true, { x = 105, z = 105, level = 0 })
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testInstanceWhitelistMatchIsNotRestricted()
    lists.whitelist = { area("Allowed copy", 100, 100, 0, 110, 110, 0) }
    fakes.setPlayer(1, 1, 0)
    fakes.setInstance(true, { x = 105, z = 105, level = 0 })
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), false)
end

function TestRestrictedAreas:testInstanceOutsideWhitelistIsRestricted()
    lists.whitelist = { area("Elsewhere", 0, 0, 0, 2, 2, 0) }
    fakes.setPlayer(8, 8, 0)
    fakes.setInstance(true, { x = 50, z = 50, level = 0 })
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testEmptyWhitelistRestrictsEveryInstance()
    fakes.setPlayer(8, 8, 0)
    fakes.setInstance(true, { x = 50, z = 50, level = 0 })
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testEmptyListsLeaveTheOverworldUnrestricted()
    fakes.setPlayer(8, 8, 0)
    fakes.setInstance(false, nil)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), false)
end

function TestRestrictedAreas:testBlacklistWinsWhenTheSourceTileIsInBothLists()
    lists.blacklist = { area("Denied", 10, 10, 0, 20, 20, 0) }
    lists.whitelist = { area("Allowed", 10, 10, 0, 20, 20, 0) }
    fakes.setPlayer(1, 1, 0)
    fakes.setInstance(true, { x = 15, z = 15, level = 0 })
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testInstanceDoesNotTestTheLiveCopyTile()
    lists.blacklist = { area("Live trap", 1, 1, 0, 3, 3, 0) }
    lists.whitelist = { area("Real place", 100, 100, 0, 110, 110, 0) }
    fakes.setPlayer(2, 2, 0)
    fakes.setInstance(true, { x = 105, z = 105, level = 0 })
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), false)
end

function TestRestrictedAreas:testUnreadablePlayerIsRestricted()
    fakes.setPlayerUnavailable()
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testPlayerTileMissingAComponentIsRestricted()
    fakes.setPlayer(4, 4, nil)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testUnreadableSourceTileInAnInstanceIsRestricted()
    fakes.setPlayer(4, 4, 0)
    fakes.setInstance(true, nil)
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
    fakes.setInstance(true, { x = 4, z = 4 })
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
end

function TestRestrictedAreas:testPublishedListsAreTables()
    local info = debug.getinfo(1, "S")
    local path = info.source:match("^@(.*)$") or ""
    local testsDir = path:match("(.*[/\\])") or "./"
    local published = assert(loadfile(testsDir .. "../areas.lua"))()
    luaunit.assertEquals(type(published.blacklist), "table")
    luaunit.assertEquals(type(published.whitelist), "table")
end

function TestRestrictedAreas:testAskingDoesNotDraw()
    fakes.setPlayer(1, 1, 0)
    local subscriptions = fakes.drawSubscriptions()
    local canvases = fakes.canvasCreations()
    RestrictedAreas.IsRestricted()
    luaunit.assertEquals(fakes.drawSubscriptions(), subscriptions)
    luaunit.assertEquals(fakes.canvasCreations(), canvases)
end

function TestRestrictedAreas:testSubscribeDoesNotReplayOrDraw()
    lists.blacklist = { area("Yard", 10, 10, 0, 12, 12, 0) }
    fakes.setPlayer(11, 11, 0)
    local calls = self:watch("watcher")
    luaunit.assertEquals(#calls, 0)
    luaunit.assertEquals(fakes.pump(), true)
    luaunit.assertEquals(#calls, 0)
end

function TestRestrictedAreas:testCrossingIntoRestrictedNotifiesEveryListener()
    lists.blacklist = { area("Yard", 10, 10, 0, 12, 12, 0) }
    fakes.setPlayer(1, 1, 0)
    local first = self:watch("one")
    local second = self:watch("two")
    fakes.setPlayer(11, 11, 0)
    luaunit.assertEquals(fakes.pump(), true)
    luaunit.assertEquals(#first, 1)
    luaunit.assertEquals(first[1].n, 1)
    luaunit.assertEquals(first[1].value, true)
    luaunit.assertEquals(#second, 1)
    luaunit.assertEquals(second[1].n, 1)
    luaunit.assertEquals(second[1].value, true)
end

function TestRestrictedAreas:testCrossingOutOfRestrictedNotifiesFalse()
    lists.blacklist = { area("Yard", 10, 10, 0, 12, 12, 0) }
    fakes.setPlayer(11, 11, 0)
    local first = self:watch("one")
    local second = self:watch("two")
    fakes.setPlayer(1, 1, 0)
    luaunit.assertEquals(fakes.pump(), true)
    luaunit.assertEquals(#first, 1)
    luaunit.assertEquals(first[1].n, 1)
    luaunit.assertEquals(first[1].value, false)
    luaunit.assertEquals(#second, 1)
    luaunit.assertEquals(second[1].n, 1)
    luaunit.assertEquals(second[1].value, false)
end

function TestRestrictedAreas:testSameNameReplacesTheListener()
    lists.blacklist = { area("Yard", 10, 10, 0, 12, 12, 0) }
    fakes.setPlayer(1, 1, 0)
    local first = self:watch("plugin")
    local second = self:watch("plugin")
    fakes.setPlayer(11, 11, 0)
    fakes.pump()
    luaunit.assertEquals(#first, 0)
    luaunit.assertEquals(#second, 1)
    luaunit.assertEquals(second[1].value, true)
end

function TestRestrictedAreas:testUnsubscribeDropsThatListenerOnly()
    lists.blacklist = { area("Yard", 10, 10, 0, 12, 12, 0) }
    fakes.setPlayer(1, 1, 0)
    local kept = self:watch("kept")
    local dropped = self:watch("dropped")
    RestrictedAreas.Unsubscribe("dropped")
    fakes.setPlayer(11, 11, 0)
    fakes.pump()
    luaunit.assertEquals(#dropped, 0)
    luaunit.assertEquals(#kept, 1)
    luaunit.assertEquals(kept[1].value, true)
end

function TestRestrictedAreas:testUnsubscribeOfAnUnknownNameDoesNothing()
    lists.blacklist = { area("Yard", 10, 10, 0, 12, 12, 0) }
    fakes.setPlayer(1, 1, 0)
    RestrictedAreas.Unsubscribe("nobody")
    luaunit.assertEquals(fakes.isTicking(), false)
    local calls = self:watch("kept")
    RestrictedAreas.Unsubscribe("missing")
    fakes.setPlayer(11, 11, 0)
    fakes.pump()
    luaunit.assertEquals(#calls, 1)
    luaunit.assertEquals(calls[1].value, true)
end

function TestRestrictedAreas:testOneListenerErrorDoesNotSilenceTheOthers()
    lists.blacklist = { area("Yard", 10, 10, 0, 12, 12, 0) }
    fakes.setPlayer(1, 1, 0)
    RestrictedAreas.Subscribe("bad", function()
        error("listener failed")
    end)
    self.names[#self.names + 1] = "bad"
    local calls = self:watch("good")
    fakes.setPlayer(11, 11, 0)
    local pumped = fakes.pump()
    luaunit.assertEquals(pumped, true)
    luaunit.assertEquals(#calls, 1)
    luaunit.assertEquals(calls[1].value, true)
end

function TestRestrictedAreas:testTickRunsOnlyWhileAListenerIsSubscribed()
    luaunit.assertEquals(fakes.isTicking(), false)
    self:watch("only")
    luaunit.assertEquals(fakes.isTicking(), true)
    RestrictedAreas.Unsubscribe("only")
    luaunit.assertEquals(fakes.isTicking(), false)
    luaunit.assertEquals(fakes.pump(), false)
end

function TestRestrictedAreas:testLastUnsubscribeForgetsThePreviousValue()
    lists.blacklist = { area("Yard", 10, 10, 0, 12, 12, 0) }
    fakes.setPlayer(11, 11, 0)
    self:watch("first")
    RestrictedAreas.Unsubscribe("first")
    luaunit.assertEquals(fakes.isTicking(), false)
    fakes.setPlayer(1, 1, 0)
    local calls = self:watch("second")
    luaunit.assertEquals(#calls, 0)
    luaunit.assertEquals(fakes.pump(), true)
    luaunit.assertEquals(#calls, 0)
    fakes.setPlayer(11, 11, 0)
    fakes.pump()
    luaunit.assertEquals(#calls, 1)
    luaunit.assertEquals(calls[1].value, true)
end

function TestRestrictedAreas:testStayingRestrictedAcrossBlacklistAreasIsNotAChange()
    lists.blacklist = {
        area("First", 0, 0, 0, 5, 5, 0),
        area("Second", 6, 0, 0, 10, 5, 0),
    }
    fakes.setPlayer(1, 1, 0)
    local calls = self:watch("walk")
    fakes.setPlayer(8, 1, 0)
    fakes.pump()
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
    luaunit.assertEquals(#calls, 0)
end

function TestRestrictedAreas:testEnteringARestrictedInstanceWhileRestrictedIsNotAChange()
    lists.blacklist = { area("Overworld", 0, 0, 0, 5, 5, 0) }
    fakes.setPlayer(1, 1, 0)
    fakes.setInstance(false, nil)
    local calls = self:watch("enter")
    fakes.setInstance(true, { x = 50, z = 50, level = 0 })
    fakes.pump()
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
    luaunit.assertEquals(#calls, 0)
end

function TestRestrictedAreas:testLeavingARestrictedInstanceOntoABlacklistIsNotAChange()
    lists.blacklist = { area("Landing", 1, 1, 0, 3, 3, 0) }
    fakes.setPlayer(2, 2, 0)
    fakes.setInstance(true, { x = 50, z = 50, level = 0 })
    local calls = self:watch("leave")
    fakes.setInstance(false, nil)
    fakes.pump()
    luaunit.assertEquals(RestrictedAreas.IsRestricted(), true)
    luaunit.assertEquals(#calls, 0)
end
