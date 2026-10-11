# RestrictedAreas

Headless library that answers whether the local player is Restricted.

Declare it in `plugin.json`. The client then injects the `RestrictedAreas` global.

```json
"requiredDependencies": {
  "RestrictedAreas": "RestrictedAreas"
}
```

## API

`IsRestricted()` takes no arguments and returns one boolean.

`Subscribe(name, callback)` registers a listener under `name`. The callback is `function(restricted)` and receives only the new boolean. Subscribing does not replay the current value; call `IsRestricted()` for that. Subscribing the same name again replaces the previous callback.

`Unsubscribe(name)` drops that listener. An unknown name does nothing.

```lua
if RestrictedAreas.IsRestricted() then
    return
end

RestrictedAreas.Subscribe("MyPlugin", function(restricted)
end)

RestrictedAreas.Unsubscribe("MyPlugin")
```

A Restricted change is the boolean flipping. Walking from one Restricted Area into another does not notify anyone. One listener's error does not stop the others. The plugin rechecks on the logic tick only while at least one listener is subscribed. The last `Unsubscribe` stops that tick and forgets the previous value, so the next subscriber does not hear a fake edge.

## When the player is Restricted

The lists are tested against the checked tile. Outside an Instance that is the tile the player is standing on. Inside an Instance it is the source tile that copy was built from, not the live copy's coordinates.

The player is Restricted when any of these is true:

- The checked tile lies in a Blacklist Area.
- The player is in an Instance and the checked tile lies in no Whitelist Area.
- The checked tile cannot be read, including an unreadable source tile inside an Instance.

Blacklist wins when a tile is in both lists. A Whitelist Area on the overworld does nothing. With both lists empty, the overworld is unrestricted and every Instance is Restricted.

## Lists

Jagex changes the answer by shipping a new version of this plugin. Edit `areas.lua`.

An Area is an editor label plus two corners. The label is not an identity and is never shown; two Areas may share one. Each corner names `x`, `z`, and `level`. Corner order does not matter. Both corner tiles are included, and every plane from the lower level through the upper level is included on that same x/z rectangle. A corner missing `x`, `z`, or `level` is skipped. The rest of the list still applies.

```lua
blacklist = {
    {
        label = "Example yard",
        corners = {
            { x = 3200, z = 3200, level = 0 },
            { x = 3210, z = 3210, level = 2 },
        },
    },
},
```

That example covers x 3200–3210 and z 3200–3210 on levels 0, 1, and 2.

## Tests

From this folder:

```
lua tests/run.lua
```
