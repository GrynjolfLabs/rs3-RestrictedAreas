# RestrictedAreas

## Summary

Other plugins call IsRestricted() and Subscribe. This plugin draws no window of its own.

## Description

Other plugins call IsRestricted() and Subscribe. RestrictedAreas answers whether the local player is in a restricted area. This plugin draws no window.

## Feedback and collaboration

Report bugs and suggestions at https://github.com/adamk33n3r/rs3-RestrictedAreas/issues.

## EULA

This Plugin uses software licensed by Jagex to the developer under the terms of the Jagex End User Licence Agreement (EULA) found at https://legal.jagex.com/docs/terms/eula (and all terms incorporated into it by reference). The development and any use of the Plugin is at all times subject to the Jagex EULA.

## Data Protection

RestrictedAreas reads the local player's tile to answer whether that tile is restricted. It keeps listener callbacks in memory. It does not write that tile or send it anywhere.
