# Cordon Truce

A mod for Anomaly and GAMMA that honors the Sidorovic-bought truce between Army and Loners. It is inspired by ["Mora's Combat Ignore Military Fix"](https://www.moddb.com/mods/stalker-anomaly/addons/moras-combat-ignore-military-fix-v152) but is rewritten from scratch using only callbacks and monkey patches to be as compatible as possible with other mods.

It works like this:
- if NPC A gets too close (default 16m) NPC B will point their gun as a warning
- if nothing happens after ~1m game time NPC A and NPC B will drop their guns and move on (keeps NPCs from getting stuck in a standoff)
- Military will stand their ground, but Loners will back away at the end.
- if that time completely elapses, NPC A and NPC B will have a delay (default 3min game time) before standing off again
- if NPC A gets even closer (~8m) NPC B will attack
- if NPC A moves farther than 16m and breaks line of sight, NPC B will stop shooting
- if NPC A fires on NPC B outside of 8m, the truce will be suspended for ~ 6hr game time
- news messages indicate when truces stop and restart
- a configurable keyboard shortcut will show a news message indicating the current state of the truce
- MCM options to tweak many settings
- NPCs will stand off permanently with the actor until they move away
- Companions by default do not stand off but will react to

It was originally created to resolve the conflict with ["Useful Idiots"](https://www.moddb.com/mods/stalker-anomaly/addons/useful-idiots-v125) and can be used as a replacement for the patch that comes with RE:COMBAT. Source code is 100% free to steal without restrictions or credit needed (same goes for any of my mods). I only ask that you stick to the principle of not overwriting core files if you use all or part of it.
