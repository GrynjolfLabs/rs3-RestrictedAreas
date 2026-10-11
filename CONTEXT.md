# RestrictedAreas

The shared answer for where the local player is Restricted. Other plugins ask; this plugin decides.

## Language

**Instance**:
A private copy of part of the world. This is the word players use.
_Avoid_: Region

**Checked tile**:
The overworld tile the lists are tested against. Outside an Instance it is the tile the player is standing on. Inside an Instance it is the source tile that copy was built from.
_Avoid_: Policy position, instance coordinates, live copy coordinates

**Area**:
The tiles inside an axis-aligned rectangle on every plane from the lower corner's level through the upper corner's level, including both corners. An editor's label on an Area is not its identity, and players do not see it.
_Avoid_: Rect, zone, region

**Blacklist**:
The Areas that make the player Restricted when the checked tile lies inside any of them. Blacklist wins when a Whitelist Area covers the same tile.
_Avoid_: Blocklist, deny list

**Whitelist**:
The Areas that exempt an Instance when the checked tile lies inside any of them. Outside an Instance they have no effect. An empty Whitelist exempts nothing, so every Instance is Restricted.
_Avoid_: Allow list, safe zone

**Restricted**:
The player is Restricted when the checked tile lies in a Blacklist Area, or the player is in an Instance and the checked tile lies in no Whitelist Area. An unreadable player tile is Restricted.
_Avoid_: Lite, restricted mode

**Restricted change**:
The moment the player becomes Restricted or stops being Restricted. Listeners who were already subscribed hear the new value, with no reason. Moving from one Area to another while staying Restricted is not a change. A listener that has just subscribed does not hear the current value.
_Avoid_: Replay, reason, per-Area notice
