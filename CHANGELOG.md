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
[Sauron]: https://steamcommunity.com/id/mephisto3D/
<!-- add other people :D!!! -->

# Version History

> In this document, you can see all updates from each version

-------------------------------------------------------------------------------

## VERSION 11.60 - 21/6/2026

-------------------------------------------------------------------------------

- Fixed typo in l4dinfectedbots QuantumLite
- Added plugin l4d2_director_commonlimit_block, to block more commons than allowed cvar => z_common_limit
- Removed a lot of text from all cfgs, as these where unnecesary, and now it is explained in the github md
- Fixed syntax in various cfgs, as it would prevent them from executing.
- l4dinfectedbots.cfg doesn't calculate dead now, as it probably made it too hard for players.
- Added All L4D2 Mutations to be selectable via !match

-------------------------------------------------------------------------------

## VERSION 11.50 - 15/6/2026

-------------------------------------------------------------------------------

- Fixed a Typo in l4dinfectedbots Quantum.cfg
- Removed l4d2_finale_fail_ending.smx in various Cfgs, as people didn't really like it, but i will leave it as optional.
- Leaker Boomer has been removed for now, as it doesn't work at the moment.

-------------------------------------------------------------------------------

## VERSION 11.40 - 14/6/2026

-------------------------------------------------------------------------------
- Balanced l4dinfectedbots, Quantum.cfg
- Added Path To Goal Plugin
- Added Crawling plugin to Casual.cfg
- Updated Various includes to lastest version

-------------------------------------------------------------------------------

## VERSION 11.30 - 24/5/2026

-------------------------------------------------------------------------------

### ClassicCasual.cfg, HardMode.cfg, Quantum.cfg, edited weapon replacements:
```text
Military Sniper: 50% chance to become an AWP (with a 50% spawn rate).
Hunting Rifle: 50% chance to become a Scout (with a 50% spawn rate).
Pump Shotgun: 50% chance to become a Scout (with a 50% spawn rate).
Chrome Shotgun: 50% chance to become a Scout (with a 50% spawn rate).
```

### Weapon Balance Changes
* Competitive.cfg
```text
M16 damage 30 => 32
M16 spreadpershot 0.47 => 0.45
ammo_huntingrifle_max 80 => 90
```
* Casual.cfg
```text
M16 spreadpershot 0.47 => 0.45
ammo_sniperrifle_max 100 => 80
ammo_huntingrifle_max 100 => 90
```
- Added missing l4d2_refillreload_fix.sp
- Added missing l4d2_infected_hud.smx
- Added missing l4d2_infected_hudhpbar.smx
- Added laser box removal to equinix.cfg in competitive modes folder.
- Separated Quantum.cfg used by l4dinfectedbots in sourcemod data folder, to quantum.cfg and quantumlite.cfg
- Balanced QuantumLite.cfg and Quantum.cfg
- Updated l4d2_weaponrules.sp to support an additional parameter for map weapon replacement percentages.

-------------------------------------------------------------------------------

## VERSION 11.20 - 31/3/2026

-------------------------------------------------------------------------------

- Edited the Infectedbots configuration "Quantum.cfg" to better balance the number of specials, mini-bosses (witches and tanks), and their respective health depending on how many players are in the match. (Thanks [MrSlenderTOP])
- Added a new plugin to disabled, [FF] Command Cheats.smx. This is only for fun netprop manipulation on players, nothing serious, recommended for playing with friends on Quantum.
- Made a minor change to Equinix Balance (Versus) respawns: (15s-1s = 14s) > (16s-1s = 15s), resulting in a total of 15 seconds respawn time for specials.
- Reintroduced essential Quantum plugins and fixed their loading in the cfg (and also some other plugins). (Thanks [MrSlenderTOP])
- Added a small Zonemod change for the jockey in quantumlite, allowing it to die from a single AWP shot.
- Rebalanced the M60: reload time changed from 5s > 4.5s, magazine size from 100 > 50, and reserve ammo from 200 > 150 (3 magazines + 1 already loaded = 4 = 200 total bullets).

- Added new Voting commands, which are the following:
>ENGLISH
- "sm_teamscramble" — Starts a vote to scramble teams
- "sm_scramble" — Short alias for scrambling teams
- "sm_voteteamscramble" — Explicit vote to scramble teams
- "sm_votescramble" — Voting alias to scramble teams

>SPANISH
- "sm_mezclar" — Inicia votación para mezclar equipos
- "sm_mezclarequipos" — Mezcla equipos (nombre completo)
>General
- sm_mvote — Text that will appear as a vote

-------------------------------------------------------------------------------

## VERSION 11.10 - 20/1/2026

-------------------------------------------------------------------------------

- Removed a lot of unused translation files
- Removed some unused .SP files
- Removed not used plugins in Protected_Plugins_List.txt
- l4d2_ammostack_rework no longer affects m60, as now it is handled separatly with another 2 plugins, which are: l4d_onetimeuseammopile_m60; and M60_NoDrop_AmmoPile_patch
- Removed Informative texts about gamemodes because they are not used anymore, and are detailed in the docs.
- Reworked M60 in Casual, Quantum and QuantumLite.
- Balanced Single and Dual Pistols.
- Updated Coop_Round_Delay plugin to be 2 seconds instead of 1.5 seconds.
- Reworked M16 in both casual and competitive modes.
- Changed some stuff in lilac_config.cfg.
- Night Vision is now available in Casual, Quantum and QuantumLite. (Double Press 'F' Quickly).

-------------------------------------------------------------------------------

## VERSION 11.05 - 5/1/2026

-------------------------------------------------------------------------------

- Fixed [VSCOOP] Team Switcher, switching bots and making the gamemode unplayable.
- Fixed l4dhots not loading in various gamemodes, like hardmode, zonemod t1,t2, and equinix balance (versus only)
- Added some cvars to make fighting with bots a little bit harder in versus coop
- Fixed l4dinfectedbots not loading correctly in versus coop
- Fixed hunter_pz_claw_dmg resetting to 24 claw damage instead of 6 as in vanilla.
- Fixed a typo in friendlyfire weapon balance, vanilla.cfg
- Tweaked l4d2_sb_fix.cfg and made bots a little bit more smart, also selected number of bots will now be 4.

-------------------------------------------------------------------------------

## VERSION 11.00 - 4/1/2026

-------------------------------------------------------------------------------

- Updated 8_slot_lobby.vpk because it didn't work even that players had it installed and activated (Thanks [Sauron])
- Fixed HardMode unsynchronized bot special spawns, so now HardMode is easier and a little bit less of a special spawn (Thanks [Actras_DK]; [Sauron])
- Added SkipIntro to HardMode
- Added Water Move Speed similar to versus in ClassicCasual, HardMode, and Quantum & QuantumLite.
- Unused CS:GO Molotov Port code lines was now moved to Competitive.cfg (it was in HardMode.CFG)
- Fixed QuantumLite not loading l4dinfectedbots from "disabled/gamemodes/XCM" folder.
- Nerfed Common Infected Damage in QuantumLite because l4dinfectedbots now works as intended, and also because it was way to exaggerated and punishing for a casual like 8 player gamemode.
- Tweaked AWP SpreadDecay in Casual Weapons Balance Config, from 8 -> 20, because it took long to get a precise shot, and even more at 30 tick and if the player was lagged < 60ms then even more so.
- Tweaked l4d2_sb_fix, to make bots a little bit more responsive.

-------------------------------------------------------------------------------

## VERSION 10.97d - 30/12/2025

-------------------------------------------------------------------------------

- Removed a LOT of unnecesary plugins.
- Cleaned a lot of gamemodes plugin usage
- Renamed a lot of plugins that had [HoE] referencing "Hell on Earth", and also some of them that had [FF] referencing "Friendly Fire"
- Added missing plugins to protected_plugins_list.txt
- Fixed plugin_unload_protect.smx not protecting plugins with [] at the start, and also not protecting plugins from fixes/,  now it works as intended.
- Now in Casual Weapon Configs, AWP is Tier 3, and Scout is Tier 1, and in Competitive, both awp and scout are Tier 1.
- Fixed cooperative4/3v4HM, using "hardmode.cfg", now it uses correct "hm.cfg".
- Added coop_round_delay to casual
- Removed Stratum.cfg, as it was a gamemode without purpose.
- Added Vendor and Footlocker back to Quantum.cfg... (QuantumLite remains as is, without these two)

-------------------------------------------------------------------------------

## VERSION 10.97c

-------------------------------------------------------------------------------

- Moving versus stuff to versus.
- Fixing Typos.
- Removing not used plugins in protected_plugins_list
- Updated StagerSolver.sp and smx
- Prevented killing special infected with bashes in Equinix.cfg (both coop and versus), Zonemod_T1.cfg and Zonemod_T2.cfg, and in HardMode.cfg
- Added l4d2_ghost_warp to Equinix.cfg
- Removed l4d_revive_health_decay in Casual as it was more punishing and being contrary to the casual experience.
- Cleaned not used stuff in Casual Gamemode, also removed versus stuff
- Reverted Bile Bomb Duration to Pre-TLS in Casual.
-  Added sv_disable_glow_faritems 1 to Equinix.cfg
- Stagger Duration is now 1.5s in Equinix.cfg
- Added Missing Casual Plugins in Quantum.cfg and in QuantumLite.cfg, And also cleaned some code.
- Removed obsolete weapon balancing in quantum, as now it uses a better system, which is exec "friendlyfire_weaponbalance/casual.cfg"
- 

-------------------------------------------------------------------------------

## VERSION 10.97 - 27/12/2025

-------------------------------------------------------------------------------

- Removed a LOT of useless Stuff (in the scriptings folder)
- Fixed missing info in Equinix.cfg
- Reworked some Stuff in ClassicCasual.cfg and removed useless stuff or too gimicky.
- Reworked Equinix Balance.cfg todo what ClassicCasual tried to do originally.
- Removed ReadyUP for HardMode.
- Hardmode now uses advanced_spawnspecials instead of infectedbots.
- Added coop_round_delay to HardMode, as it makes restarting a round faster.
- Removed nb_update_frequency in listenserver.cfg, as now it is handled in npc_manager.
- Balanced rifles from collected feedback, and also hunting rifle now does 55 damage from bodyshot, instead of 65.
- Fixed Smoker Animation not playing in coop.
- Added some plugins to force special infected to play a sound when spawning.
- Added a plugin to fix survivor bots behaviour
- Updated drop_secondary.sp and smx
- Translated Common Infected Damage back to english
- Tweaked [FF] 80% Melee Removal to now be 50%.

-------------------------------------------------------------------------------

## VERSION 10.95 - 22/12/2025

-------------------------------------------------------------------------------

- Balanced infected in Quantum.cfg in InfectedBots Data
- Fixed l4d2_stumble_fix not being protected when voting a new mode
- Removed Plane Crash from autoloaded plugins, it is supposed to be used in attano-sky maps, now it is a Quantum.cfg plugin
- Changed l4d2_fireworks.smx directory and made it a optional tweak, as it affected vanilla game.
- Changed ItemHint to be spanish again, i should think of something to translate it to english later...
- AmmoStackRework Now Removes the entity, i don't think this is a good thing, neither balanced, but whatever, i should think something for this later.
- Removed ItemHing Phrases as now it is hardcoded to spanish, also these didn't work as expected, as these used game instructors and sourcemod can't auto-translate these
- Added Tank Ally Knockback Phrases, for english and spanish.
- Fixed the Stripper Source, Attano Sky Config for c1m1_hotel, the elevator session now works as expected, also made c2m2_streets.cfg, now calling a panic event and not trying to use a non-existant vscript like before.
- Removed the extra damage being done to survivors by infected in 2vs2, thanks for reporting this [MrSlenderTOP]
- Added some Beta Stuff to Deathmatch
- Added some Beta Stuff to 1HP + One Down
- Removed the extra damage being dealt in 1v4HM, because it was too hard, also jockey did extreme amounts of damage already, for some reason i don't know.
- In Classic Casual from Cooperative4, fireworks now attract CI (common infected).
- Made some advancements in Equinix Balance from cooperative4, but it is a not finished Gamemode Yet, as it requires further testing.
- Fixed Spitter Claw dealing 24 dmg in FF_complementaries.cfg, as this affected vanilla gameplay.
- Reduced Military Sniper ReloadDuration 4.0s > 3.3s, as it was a really nerfed weapon already.
- Rounded HuntingRifle ReloadDuration 3.167s > 3.0s
- Reverted and Tweaked SG552 Balance Changes (For like the fifth time already???), anyway, i think it's a good balanced weapon in the current state (this could change in the future but i hope not).
- Added a little more damage from long distances to the ak47, RangeMod 0.88 > 0.90
- Reduced the SCAR headshot damage multiplier 0.75 > 0.65.
- Reverted Deagle Buff, now it is vanilla, because i don't really think deagle needs a buff... This probably changes in the future. 

-------------------------------------------------------------------------------

## VERSION 10.90 - 5/11/2025

-------------------------------------------------------------------------------

- Removed Unnecesary InfectedBots Cvars in Cooperative4/ and Cooperative8/VersusCoop
- Default Quantum.cfg maps are Attanosky now.
- Added Incapacitated Crawling and Incapped Weapons for Quantum.cfg
- Added Bile the World to only Bile Teammates in Cooperative4/ClassicCasual
- Balanced a bit 1 vs 4 HardMode Damages
- Added a lot of beta stuff to cooperative4/1HP.cfg
- Added some infected balancing cvars in Competitive/Equinix.cfg
- Changed a lot of cvars and renamed plugins in deathmatch and also removed some of them that were too niche or gimicky, now deathmatch is in alpha state but it's semi-functional, and really fun.
- Added "Jockey Ride Team Switch Teleport Fix", by HarryPotter, URL: [here](https://steamcommunity.com/profiles/76561198026784913/)

-------------------------------------------------------------------------------

## VERSION 10.80 - 22/11/2025

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
