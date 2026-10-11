# Restricted means blacklist, or an Instance outside the whitelist

Other plugins need one shared answer for where the local player is Restricted, and the area list has to change without a Watchdog release. RestrictedAreas owns that answer. The player is Restricted when the checked tile lies in a Blacklist Area, or the player is in an Instance and the checked tile lies in no Whitelist Area. Both lists are overworld tiles: outside an Instance the checked tile is the tile the player is standing on, and inside an Instance it is the source tile that copy was built from. Blacklist wins on overlap. An empty Whitelist restricts every Instance. An unreadable tile is Restricted. If RestrictedAreas is absent, the player is not Restricted.

## Considered Options

- Each plugin combines the three checks itself. Rejected: the checks would drift, and a Whitelist written against the live Instance tile would never match an overworld Area.
- Test the live Instance tile against the lists. Rejected: that tile is the copy, not the place the lists name.

## Consequences

The client call that supplies the source tile is documented as the bottom-left of the source data, which may be a mapsquare corner rather than the translated tile. Tight Areas should wait until that return value is confirmed in the client. Dependents read the current answer with `IsRestricted()`.
