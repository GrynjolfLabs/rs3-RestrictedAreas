# RestrictedAreas

## Problem Statement

Plugins need one shared answer for whether the local player is standing somewhere Jagex does not want them to react to the game. That answer has to change when Jagex updates the area list, without a new release of every plugin that asks.

## Solution

RestrictedAreas is a headless plugin. It holds a Blacklist and a Whitelist of Areas and answers `IsRestricted()` for the local player. It also tells listeners when that answer flips. Jagex updates the lists by publishing a new version of this plugin.

## User Stories

1. As a plugin author, I want to call `IsRestricted()` and get a boolean, so that I do not reimplement that answer.
2. As a plugin author, I want `IsRestricted()` to take no arguments and read the local player, so that every caller is asking about the same person.
3. As a plugin author, I want no reason code on that boolean, so that I cannot start depending on Blacklist versus Instance.
4. As a plugin author, I want to `Subscribe` under a name I choose and `Unsubscribe` that same name, so that I can hear Restricted changes and drop the listener when I am done.
5. As a plugin author, I want a second `Subscribe` with the same name to replace the first listener, so that a reload does not stack listeners.
6. As a plugin author, I want `Unsubscribe` of a name that is not subscribed to do nothing, so that teardown is safe.
7. As a plugin author, I want the callback to receive the new boolean and nothing else, so that the event matches `IsRestricted()`.
8. As a plugin author, I want a listener that just subscribed to hear nothing until the answer flips, so that I read `IsRestricted()` myself for the current value.
9. As a plugin author, I want one listener's error to not stop the others from hearing that change, so that a faulty plugin cannot silence the rest.
10. As a plugin author, I want RestrictedAreas to recheck on the logic tick only while at least one listener is subscribed, so that nobody pays for a tick when nobody is listening.
11. As a plugin author, I want `IsRestricted()` to answer on demand even when nobody is subscribed, so that a caller that only pulls still works.
12. As a plugin author, I want the last `Unsubscribe` to stop the tick and forget the previous value, so that the next subscriber does not get a fake edge.
13. As Jagex, I want the lists to be data shipped in this plugin, so that a new plugin version is how the areas change.
14. As Jagex, I want each Area to have an editor label and two corners, so that I can tell the entries apart while editing.
15. As a player, I want those labels never shown, so that the list is not a user interface.
16. As Jagex, I want a label to not be an identity, so that two Areas may share a label and both still apply.
17. As Jagex, I want each corner to name an x, a z, and a level, so that an Area sits on the world grid.
18. As Jagex, I want corner order not to matter, so that either corner can be written first.
19. As Jagex, I want both corner tiles included, so that standing on the edge counts.
20. As Jagex, I want an Area whose corners are level 0 and level 2 to include levels 0, 1, and 2, with the same x/z rectangle on each of those planes.
21. As Jagex, I want an Area whose corner is missing x, z, or level to be skipped, so that the rest of the list still applies.
22. As a player on the overworld, I want to be Restricted when my tile lies in a Blacklist Area.
23. As a player on the overworld, I want a Whitelist Area under my tile to do nothing.
24. As a player on the overworld outside every Blacklist Area, I want to not be Restricted.
25. As a player in an Instance, I want the lists tested against the source tile that copy was built from, so that a Whitelist written in overworld tiles can match.
26. As a player in an Instance whose source tile lies in a Whitelist Area and in no Blacklist Area, I want to not be Restricted.
27. As a player in an Instance whose source tile lies in no Whitelist Area, I want to be Restricted, including when the Whitelist is empty.
28. As a player whose source tile lies in both lists, I want to be Restricted, so that Blacklist wins.
29. As a player in an Instance, I want the live copy's tile not used for the lists, so that instance coordinates cannot accidentally hit an overworld Area.
30. As a player whose tile cannot be read, I want `IsRestricted()` to return true.
31. As a player who is in an Instance but whose source tile cannot be read, I want `IsRestricted()` to return true.
32. As a player who walks from one Blacklist Area into another without leaving the Blacklist, I want no Restricted change, so that staying Restricted is not an edge.
33. As a player who enters an Instance that is also Restricted, while already Restricted on the overworld, I want no Restricted change.
34. As a player who leaves a Restricted Instance onto a Blacklist tile, I want no Restricted change.
35. As a player who crosses from not Restricted to Restricted, I want every current listener to receive true.
36. As a player who crosses from Restricted to not Restricted, I want every current listener to receive false.
37. As a plugin author, I want this plugin to draw nothing, so that my own UI stays mine.
38. As a plugin author, I want the word Instance used for a private copy of the world, so that player language is the language of the plugin.
39. As a plugin author, I want the published lists to start empty, so that no invented coordinates ship before Jagex writes them.
40. As a player with empty lists, I want every Instance to be Restricted and the overworld to be unrestricted, except when my tile cannot be read.

## Implementation Decisions

- The plugin's global is `RestrictedAreas`. It is headless.
- `IsRestricted()` returns a boolean. It reads the local player and the current lists. It has no parameters and no reason.
- `Subscribe(name, callback)` and `Unsubscribe(name)` follow the client's named-listener shape. The callback is called with the new boolean. The same name replaces. An unknown `Unsubscribe` does nothing.
- A Restricted change is the boolean flipping. Moving between Areas while the boolean stays the same is not a change. Subscribing does not replay.
- While one or more listeners are subscribed, recheck on the logic tick and fire only on a flip. With zero listeners, do not tick, and do not keep a previous value.
- A listener error is isolated from the other listeners.
- An Instance is the client state players call an instance. The client function that reports it is an implementation detail and is not named in docs or UI. This plugin has no UI.
- The checked tile is the player's live tile outside an Instance, and the source tile of that copy inside an Instance. Both lists are authored in overworld tiles and tested against that tile.
- Restricted means the checked tile lies in a Blacklist Area, or the player is in an Instance and the checked tile lies in no Whitelist Area. Blacklist wins. An empty Whitelist restricts every Instance. An unreadable tile, including an unreadable source tile while in an Instance, is Restricted.
- An Area is an axis-aligned rectangle on every plane from the lower corner's level through the upper corner's level, including both corners. A corner without x, z, and level is ignored. The rest of the list still applies. Labels are not identities and are not shown.
- The lists are data in the plugin: a Blacklist and a Whitelist. Ship both empty. Tests supply their own lists through the same read path the published data uses, then assert only through `IsRestricted()` and the listener callback.
- This plugin does not fetch the lists and does not know about Watchdog.

## Testing Decisions

- A good test calls `IsRestricted()` or subscribes, having first set the player, the Instance state, the source tile, and the lists. It does not call a rectangle helper.
- Test the public global only. Cover overworld Blacklist, overworld Whitelist ignored, Instance matched by source tile, Instance with an empty Whitelist, overlap where Blacklist wins, level span, inclusive corners, a skipped malformed Area, unreadable player, unreadable source tile, no callback on subscribe, callback on a flip, no callback when the boolean stays true across two Areas, no tick after the last unsubscribe, and same-name replace.
- Prior art is a luaunit suite that installs fakes for the player and the world and asserts observable return values and callbacks.

## Out of Scope

- Watchdog's triggers, content panel, and manifest.
- Any coordinates Jagex has not written. Empty lists are the shipping data.
- Confirming in the client whether the source tile is the translated tile or only the mapsquare corner. Call the source API as specified. Do not invent a second definition of the checked tile.
- A reason, a per-Area event, a replay-on-subscribe, a push when nobody is listening, and any drawn UI.
- Publishing this plugin to the Plugin Hub, choosing a numeric id, and creating a git repo.

## Further Notes

- The glossary in this plugin and ADR 0001 are the vocabulary and the predicate decision. This spec does not reopen them.
- Tight Areas should wait until someone confirms the source-tile return value in the client. The code still uses that call.
- The contract is closed. Do not rename `IsRestricted`, `Subscribe`, or `Unsubscribe`, and do not add a reason argument.
