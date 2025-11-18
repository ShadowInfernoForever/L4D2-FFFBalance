// HD_lang_[LANGUE].sp
// Fichier de langage.
// Information 1 : Tout messages utilisés par l'instruction "PrintHintText" doit faire moins de 90 caracteres (sinon le message ne serra pas affiché correctement. Le reste est limité à 200 caracteres.
// Information 2 : Codes couleurs : \x01 : blanc , \x03 : vert clair , \x04 : jaune , \x05 : vert foncé. Blanc pour les commandes, Jaune pour les messages, vert foncé pour les messages importants/events, vert clair pour les variables.
//////////

new _nombreHelp = 5;
new String:_HD_HELP[][] = 
{
"\x03HUMAN DIRECTOR - Chat Commands (!hd...), Console Commands (sm_hd...)",
"\x03 - Bases : !hddirector, !hddemission, !hdmenu, !hdspawn, !hdwhodirector",
"\x03 - Other : !hdquickspawn, !hdkill, !hdhelp, !hdstats",
"\x03 - Admin (RCON ONLY) : sm_hdon, sm_hdoff, sm_hdbot",
"\x03 - ConVar (RCON ONLY) : sm_humandirector_debug 0, sm_humandirector_forcespawn 1"
}

new String:_HD_HELP_TEXT[] = "Type !hdhelp on chat for more information about commands."; // hint
new String:_HD_DIRECTOR_NOT_ASSIGNED[] = "\x04 The boss is not here! Write in the chat : \x01!hddirector";
new String:_HD_YOU_ARE_NOT_DIRECTOR[] = "\x04 You do not have a whip to do that, unlike him : %s";
new String:_HD_NO_MENU_CAUSE_SURVIVOR[] = "\x04 Since when the survivors have the power?? Bwuhahahahah !!";
new String:_HD_WELCOME_DIRECTOR_MENU[] = "--- Welcome, Director ---"; // menu
new String:_HD_MENU_SPAWN[] = "Spawn menu"; // menu
new String:_HD_DEMISSION[] = "Resign";
new String:_HD_QUICKSPAWN_HELP[] = "Command console : !hdquickspawn <ID>. ID = 0 (infecte), 1 (10 infecte), 2 (horde), 3 (witch), 4 (special group), 5 (hunter), 6 (smoker), 7 (boomer), 8 (tank)"; // console
new String:_HD_REACHED_MAX_ZOMBIES_ON_MAP[] = "\x04 All your guys are on the ground, or have already received the order to spawn!";
new String:_HD_CAN_RESPAWN_AS[] = "\x05 You can spawn as : \x01%s";
new String:_HD_HAS_RECEIVED_SPAWN_ORDER[] = "\x04 %s received the order to spawn."; 
new String:_HD_STATUS_ABLE_TO_SPAWN[] =  "\x03 is preparing to spawn :\x01 ";
new String:_HD_STATUS_WAITING[] = "\x05 is dead. Waiting for orders.";
new String:_HD_STATUS_ALIVE[] = "\x03 is alive!";
new String:_HD_STATUS_FINAL_TEXT[] = "\x04 -- %s is %s";
new String:_HD_CANNOT_SPAWN_YET[] = "\x04 You don't have any right to spawn, wait for an order from the Director.";
new String:_HD_NEW_DIRECTOR_IS[] = "\x05 Oh my God! The Director is %s!";
new String:_HD_GAME_STARTING_IN_30S[] = "\x04 The game begins in 1 minute! Only normal infected can be spawn, during this time.";
new String:_HD_DIRECTOR_ALREADY_AFFECTED[] = "\x04 There is only one chair for the Director : %s .";
new String:_HD_SURVIVOR_CANNOT_BE_DIRECTOR[] = "\x04 You must be an infected player to become the Director!";
new String:_HD_DEMISSION_INFO[] = "\x05 The director resigned from his job! We need an another Director. Write on chat : \x01!hddirector";
new String:_HD_DEMISSION_MESSAGE[] = "\x04 You need to be the Director to do that.";
new String:_HD_DEMISSION_BUT_NOT_DIRECTOR[] = "\x04 You need to be the Director to do that.";
new String:_HD_DEMISSION_BUT_SURVIVOR[] = "\x04 You must be an infected player to become the Director.";
new String:_HD_DIRECTOR_LEFT[] = "\x05 The director left! We need an another Director. Write on chat : \x01!hddirector";
new String:_HD_DIRECTOR_WENT_SURVIVOR[] = "\x05 The director has changed his team! We need an another Director. Write on chat : \x01!hddirector";
new String:_HD_DEBUG_START_ROUND[] = "Debug[HUMAN DIRECTOR] - Start Round"; // console
new String:_HD_DEBUG_END_ROUND[] = "Debug[HUMAN DIRECTOR] - End Round"; // console
new String:_HD_WELCOME_NO_DIRECTOR[] = "\x05 Hi guys, We need a new Director. To become the best, write on chat : \x01!hddirector";
new String:_HD_HORDE_READY[] = "The horde is ready to be called again !"; // hint
new String:_HD_INFECTED_NEED_DIRECTOR[] = "We need a Director to start the game. Type on chat : !hddirector"; // hint
new String:_HD_SURVIVOR_NEED_DIRECTOR[] = "Waiting for a new Director..."; // hint
new String:_HD_INFECTED_WAIT_DIRECTOR[] = "When the Director gives you the order to spawn, enter on chat : !hdspawn"; // hint
new String:_HD_SURVIVOR_WAIT_DIRECTOR[] = "Praying... The game is about to start..."; // hint
new String:_HD_INFECTED_CAN_SPAWN[] = "You can spawn %s. Go to a dark place, and type !hdspawn on chat to spawn."; // hint
new String:_HD_WELCOME_DIRECTOR[] = "Welcome, Director. To open the menu, write on chat: !hdmenu"; // hint
new String:_HD_PROBLEM_SPAWN[] = "In case of problems, move, anticipate survivors movements."; // hint
new String:_HD_PROBLEM_SPAWN_SPECIAL[] = "Your players are excited! Spawn your special infected !"; // hint
new String:_HD_ROUND_START_UNFREEZE[] = "\x05 The hunt is open! Survivors can move, and the Director can do anything he wants!";
new String:_HD_RESSOURCES_AMOUNT[] = "Resources : %i"; // center message
new String:_HD_NOT_ENOUGH_MONEY[] = "\x04 We need more resources!";
new String:_HD_TOO_MANY_WITCHES[] = "\x04 You can't call an another Witch!";
new String:_HD_REMAINING_WITCHES[] = "\x05 Witch remaining : %i";
new String:_HD_WITCH_SPAWN[] = "A Witch is here!"; // hint
new String:_HD_TOO_MANY_TANKS[] = "\x04 You can't call an another Tank.";
new String:_HD_REMAINING_TANKS[] = "\x05 Tank remaining : %i";
new String:_HD_TANK_SPAWN[] = "A Tank arrives!"; // hint
new String:_HD_NO_HORDE[] = "\x04 Wait a moment before a new wave.";
new String:_HD_WAIT_TIME_FOR_HORDE[] = "\x05 Wait few minuts before call a new horde.";
new String:_HD_HORDE_INCOMING[] = "Horde incoming!"; // hint
new String:_HD_WAIT_FOR_ANOTHER_HUNTER[] = "\x04 Wait a moment before spawning a new Hunter.";
new String:_HD_WAIT_FOR_ANOTHER_BOOMER[] = "\x04 Wait a moment before spawning a new Boomer.";
new String:_HD_WAIT_FOR_ANOTHER_SMOKER[] = "\x04 Wait a moment before spawning a new Smoker.";
new String:_HD_CANT_SPAWN_ANY_SPECIAL[] = "\x04 We need more times before invoke a new special group !";
new String:_HD_ALL_INFECTED_ALIVE[] = "\x04 All your infected need to be dead, or without orders, before spawning a new group.";
new String:_HD_GO_FURTHER[] = "\x04 You are too close, use the free look to get further.";
new String:_HD_AIM_FURTHER[] = "\x04 You are targeting survivors! Keep your aim elsewhere!";
new String:_HD_FULL_ZOMBIZ[] = "\x04 There are too much infected on the map, please wait a moment.";
new String:_HD_WARN_NO_ZOMBIZ[] = "You must spawn more normal infected!"; // hint
new String:_HD_PLUGIN_ACTIVE_SERVER[] = "\x03 Plugin [HUMAN DIRECTOR] actived. The change takes place at the next round.";
new String:_HD_PLUGIN_ACTIVE_ALL[] = "\x03 Plugin [HUMAN DIRECTOR] actived. The change takes place at the next round.";
new String:_HD_PLUGIN_ACTIVE_ALREADY[] = "\x03 Plugin [HUMAN DIRECTOR] already active.";
new String:_HD_PLUGIN_NOACTIVE_SERVER[] = "\x03 Plugin [HUMAN DIRECTOR] desactived. The change takes place at the next round.";
new String:_HD_PLUGIN_NOACTIVE_ALL[] = "\x03 Plugin [HUMAN DIRECTOR] desactived. The change takes place at the next round.";
new String:_HD_PLUGIN_NOACTIVE_ALREADY[] = "\x03 Plugin [HUMAN DIRECTOR] already desactivated.";
new String:_HD_WELCOME_START[] = "\x03 Welcome in 'HUMAN DIRECTOR' server mod! Type \x01!hdhelp \x03in chat for more informations.";
new String:_HD_WHO_DIRECTOR[] = "\x04 %s is the Director."
new String:_HD_WHO_NO_DIRECTOR[] = "\x04 There is no director. To take this place, write in the chat : \x01!hddirector"
new String:_HD_CAMERALIBRE[] = "\x03 To change the view in \x04Free Look\x03 (when dead or spectating), you have to activate the option \x04Specating Free look\x03 in 'Multiplayer' menu.";
new String:_HD_CAMERALIBRE_DEUX[] = "\x03 Finaly, press \x04JUMP\x03 to change view. Aim the area where you want to spawn, when you have an order.";
new String:_HD_STATS_TITLE[] = "\x03 Game statistics:";
new String:_HD_GAME_DIRECTED_BY[] = "\x03 Game directed by %s.";
new String:_HD_NB_NORMAL_INFECTED[] = "\x03 %i normal infected";
new String:_HD_NB_HUNTERS[] = "\x03 %i hunters";
new String:_HD_NB_SMOKERS[] = "\x03 %i smokers";
new String:_HD_NB_BOOMERS[] = "\x03 %i boomers";
new String:_HD_SPAWN_FORCE_ALERT[] = "\x05 You are too slow! A special will automatically spawn for an higher price! Think about your players!";
