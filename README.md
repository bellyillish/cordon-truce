# Cordon Truce

A mod for Anomaly and GAMMA that honors the Sidorovic-bought truce between Army and Loners. It is based on ["Mora's Combat Ignore Military Fix"](https://www.moddb.com/mods/stalker-anomaly/addons/moras-combat-ignore-military-fix-v152) but is rewritten from scratch using only callbacks and monkey patches to be as compatible as possible with other mods.

It works like this:
- if NPC A gets too close (default 16m) NPC B will point their gun as a warning
- if nothing happens after ~1m game time NPC A and NPC B will drop their guns and move on (keeps NPCs from getting stuck in a standoff)
- if that time completely elapses, NPC A and NPC B will have a delay (default 2min game time) before standing off again
- if NPC A gets even closer (~8m) NPC B will attack
- if NPC A moves farther than 16m and breaks line of sight, NPC B will stop shooting
- if NPC A fires on NPC B outside of 8m, the truce will be suspended for ~ 4hr game time
- news messages indicate when truces stop and restart
- config at the top of the script to tweak most settings (see image)
- applies to all NPCs and the actor, except when the actor shoots the enemy the truce stops regardless of distance

It was originally created to resolve the conflict with ["Useful Idiots"](https://www.moddb.com/mods/stalker-anomaly/addons/useful-idiots-v125) and can be used as a replacement for the patch that comes with RE:COMBAT. It is 100% free to steal without restrictions or credit needed. I only ask that you stick to the principle of not overwriting core files if you use all or part of it.
