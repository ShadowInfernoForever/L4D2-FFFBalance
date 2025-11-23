![FFF Balance](img/FFBalanceLogo256.jpg "FF Balance")

> [go back to README](../README.md 'go back to Table of Content')

<!-- steam link shortcuts -->
[Shadow]: https://steamcommunity.com/profiles/76561198021481327/
[MrSlenderTOP]: http://steamcommunity.com/profiles/76561197992537591
[Actras_DK]: https://steamcommunity.com/profiles/76561198886957675/
[-|Tuc]: https://steamcommunity.com/id/Tucu22/
[Luca4808]: https://steamcommunity.com/id/Synth-Dingo/
[DJ master 3000/Juanito_kpo4270]: https://steamcommunity.com/profiles/76561199081627245/
[Zombine]: https://steamcommunity.com/id/Brass_Beast_Boy/
<!-- add other people :D!!! -->

# Version History

> In this document, you can see all updates from each version

-------------------------------------------------------------------------------

## VERSION 10.8 - 22/11/2025

-------------------------------------------------------------------------------

- Disabled Logging in sourcemod/config/core.cfg
- Renamed "★ Competitive/Versus - 8 players" to "★ Versus - 8 players", because it detected it as a CFG.
- Added a infectedbots cfg for 'HvS' Cooperative4 Gamemode
- Trash Cleaning again, removing useless or not used, .cfgs in cfg/sourcemod/
- Removed l4d2_si_stumble_grenade_launcher.smx, because it wasn't balanced.
- Updated [TR] Tank Ally KnockBack.sp and it's corresponding .smx, to prevent it from displaying catapult message from damaging yourself as a tank, and also added a anti-spam for the push message.
- Updated Leaker Boomer, unsure if it works, from testing it seemed fine.
- Reworked and Fixed, 1v1 in competitive versus.
- Fixed HvS in versus competitive, not working as intended, also reduced the shotgun spread ring in that gamemode.
- Balanced a bit Competitive TankRush. Reduced tr_tankhealth to 1100... seemed pretty balanced i guess, but needs further testing.
- Quantum.cfg, straight up just using casual weapon balancing, also re-added Leaker Boomer
- Fixed Hardmode HvS spawning all types of infected and not only hunters.
- Added a CVAR to disable [pa4H]FakePing.
* Balance changes for weapons in the competitive.cfg category.
- Balanced all Assault Rifles, nerfing some of these at long distances, as sniper rifles should do the job.
- Reduced the pistol spread a little bit.
- Rebalanced SG552 (AGAIN... jesus).
* Balance Changes in Shotguns
** What was agreed upon with [Luca4808] and [Zombine]
- Made both Spas Shotgun and AutoShotgun different from eachother, used the popular method of making the Spas now better for taking out special infected, and autoshotgun for hordes.
- Reverted Spas and Autoshotgun reload durations.
- Spas and AutoShotgun now have a 0.75 tankdamagemult.

-------------------------------------------------------------------------------

## VERSION 10.75 - 21/11/2025

-------------------------------------------------------------------------------

- Some matchmodes were renamed.
- A FakePing by pa4H was added and edited to make it dynamic.
- l4d_freely_round_end was moved out of fixes since it’s not a fix, but a tweak.
- Stripper maps were reorganized (AGAIN).
- Some Stripper maps were edited for zonemod_t2.
- Stripper is now enabled by default, but it doesn’t include any map; this allows activating a map CFG at any time through a matchmode.
- Two configs were added for coop, versus, Equinix.cfg and HvS (or HM - HvS).
- The server title was fixed (it was changed because it didn’t fit in readyup).
- SG552 balance was changed; it needs testing.
- AutoShotguns were Balanced... needs testing and feedback.
- Documentation in modes.md was clarified a bit (still missing some things).
- Several objectives in TODO.md were completed, new ones were added, and others remain unfinished.
- Fixed L4D2 Attributes Again, because shotguns couldn't use reloaddurationmult, they instead used tankdamagemult.

-------------------------------------------------------------------------------

## VERSION 10.71 - 18/11/2025

-------------------------------------------------------------------------------
## v10.71
#Fixes & Removal of Useless Stuff
- Fixed an error with l4d2_weapon_attributes
- Removed Not Used stuff in protected_plugins_list.txt
- Removed Not used plugins in plugins folder
- Added Lilac.Log
- Fixed Typo in Readme.MD

-------------------------------------------------------------------------------

## VERSION 10.7 - 18/11/2025

-------------------------------------------------------------------------------
## v10.7
- Trash Cleaning
- Removed mutant tanks from scripting, has it served no relevancy here
- Removed Restart Without Changelevel plugin, gamedata, and script, because it removed weapon spawns in versus mode, when a restart chapter was called.
- Edited Protected plugins to remove [(Restart Without Changelevel)] plugin

-------------------------------------------------------------------------------

## VERSION 10.5 - 17/11/2025

-------------------------------------------------------------------------------

## v10.5
- Private Initial Release yay!
