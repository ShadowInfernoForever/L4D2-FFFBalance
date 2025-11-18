// HD_lang_[LANGUE].sp
// Fichier de langage.
// Information 1 : Tout messages utilisés par l'instruction "PrintHintText" doit faire moins de 90 caracteres (sinon le message ne serra pas affiché correctement. Le reste est limité à 200 caracteres.
// Information 2 : Codes couleurs : \x01 : blanc , \x03 : vert clair , \x04 : jaune , \x05 : vert foncé. Blanc pour les commandes, Jaune pour les messages, vert foncé pour les messages importants/events, vert clair pour les variables.
//////////

new _nombreHelp = 5;
new String:_HD_HELP[][] = 
{
"\x03HUMAN DIRECTOR - Commandes Chat (!hd...), Console (sm_hd...)",
"\x03 - Base : !hddirector, !hddemission, !hdmenu, !hdspawn, !hdwhodirector",
"\x03 - Autre : !hdquickspawn, !hdkill, !hdhelp, !hdstats",
"\x03 - Admin (RCON ONLY) : sm_hdon, sm_hdoff, sm_hdbot",
"\x03 - ConVar (RCON ONLY) : sm_humandirector_debug 0, sm_humandirector_forcespawn 1"
}

new String:_HD_HELP_TEXT[] = "Tapez !hdhelp dans le chat pour plus d'informations sur les commandes."; // hint
new String:_HD_DIRECTOR_NOT_ASSIGNED[] = "\x04 Il n'y a pas encore de directeur. Pour le devenir, ecrivez dans le chat : \x01!hddirector";
new String:_HD_YOU_ARE_NOT_DIRECTOR[] = "\x04 Vous n'avez pas acces a cette commande, seul le directeur %s peut le faire.";
new String:_HD_NO_MENU_CAUSE_SURVIVOR[] = "\x04 Vous n'avez pas acces a cette commande en tant que survivant.";
new String:_HD_WELCOME_DIRECTOR_MENU[] = "--- Bienvenue, Director ---"; // menu
new String:_HD_MENU_SPAWN[] = "Menu de spawn"; // menu
new String:_HD_DEMISSION[] = "Demissionner";
new String:_HD_QUICKSPAWN_HELP[] = "Commande console : !hdquickspawn <ID>. ID = 0 (infecte), 1 (10 infecte), 2 (horde), 3 (witch), 4 (special group), 5 (hunter), 6 (smoker), 7 (boomer), 8 (tank)"; // console
new String:_HD_REACHED_MAX_ZOMBIES_ON_MAP[] = "\x04 Tous les infectes speciaux sont deja vivants, ou en cours d'apparition. ";
new String:_HD_CAN_RESPAWN_AS[] = "\x05 Vous pouvez apparaitre en tant que : %s";
new String:_HD_HAS_RECEIVED_SPAWN_ORDER[] = "\x04 %s a recu l'ordre de spawn !"; 
new String:_HD_STATUS_ABLE_TO_SPAWN[] = "\x03 se prepare a apparaitre :\x01 ";
new String:_HD_STATUS_WAITING[] = "\x05 est mort. En attente des ordres."; 
new String:_HD_STATUS_ALIVE[] = "\x03 est vivant !";
new String:_HD_STATUS_FINAL_TEXT[] = "\x04 -- %s est %s";
new String:_HD_CANNOT_SPAWN_YET[] = "\x04 Vous n'avez pas encore le droit d'apparaitre, veuillez attendre que le director vous affecte un role.";
new String:_HD_NEW_DIRECTOR_IS[] = "\x05 Un joueur vient de prendre le controle du director. Le Director est : %s";
new String:_HD_GAME_STARTING_IN_30S[] = "\x04 La partie debute dans 1 minute. Le director est en train de preparer le terrain de jeu.";
new String:_HD_DIRECTOR_ALREADY_AFFECTED[] = "\x04 La place de director est deja occupee par %s .";
new String:_HD_SURVIVOR_CANNOT_BE_DIRECTOR[] = "\x04 Seuls les infectes peuvent prendre la place du director.";
new String:_HD_DEMISSION_INFO[] = "\x05 Le director vient de demissioner, pour prendre la place vacante, ecrivez dans le chat : \x01!hddirector";
new String:_HD_DEMISSION_MESSAGE[] = "\x04 Vous venez de quitter le poste de director.";
new String:_HD_DEMISSION_BUT_NOT_DIRECTOR[] = "\x04 Vous n'etes pas le director, inutile de demissionner.";
new String:_HD_DEMISSION_BUT_SURVIVOR[] = "\x04 Vous etes survivant, inutile d'essayer de demissionner du poste de director.";
new String:_HD_DIRECTOR_LEFT[] = "\x05 Le director a quitte la partie. Si vous voulez le remplacer, ecrivez dans le chat : \x01!hddirector";
new String:_HD_DIRECTOR_WENT_SURVIVOR[] = "\x05 Le director est passe chez les survivants en laissant sa place. Si vous voulez remplacer le Director, ecrivez dans le chat : \x01!hddirector";
new String:_HD_DEBUG_START_ROUND[] = "Debug[HUMAN DIRECTOR] - Debut round"; // console
new String:_HD_DEBUG_END_ROUND[] = "Debug[HUMAN DIRECTOR] - Fin Round"; // console
new String:_HD_WELCOME_NO_DIRECTOR[] = "\x05 Bienvenue. Si vous etes infecte, et vous voulez devenir le Director, ecrivez dans le chat : \x01!hddirector";
new String:_HD_HORDE_READY[] = "La horde est desormais disponible dans votre menu de spawn."; // hint
new String:_HD_INFECTED_NEED_DIRECTOR[] = "Il faut qu'un infecte prenne le controle du director, via la commande chat : !hddirector"; // hint
new String:_HD_SURVIVOR_NEED_DIRECTOR[] = "Veuillez patienter que le Director soit designe parmi les infectes..."; // hint
new String:_HD_INFECTED_WAIT_DIRECTOR[] = "Quand le Director vous donnera le droit d'apparaitre, entrez dans le chat : !hdspawn"; // hint
new String:_HD_SURVIVOR_WAIT_DIRECTOR[] = "Veuillez patienter pendant que le director prepare le terrain..."; // hint
new String:_HD_INFECTED_CAN_SPAWN[] = "Vous pouvez spawner en %s. Visez une place, et entez !hdspawn dans le chat."; // hint
new String:_HD_WELCOME_DIRECTOR[] = "Bienvenue, Director. Pour ouvrir le menu, ecrivez dans le chat : !hdmenu"; // hint
new String:_HD_PROBLEM_SPAWN[] = "En cas de problemes, eloignez vous, prevoyez l'apparition des infectes a l'avance."; // hint
new String:_HD_PROBLEM_SPAWN_SPECIAL[] = "Attention, tous vos infectes speciaux sont inactifs, et attendant vos ordres."; // hint
new String:_HD_ROUND_START_UNFREEZE[] = "\x05 La partie est lancee ! Les survivants peuvent desormais bouger, et le director n'est plus limite dans ses actions.";
new String:_HD_RESSOURCES_AMOUNT[] = "Ressources : %i"; // center message
new String:_HD_NOT_ENOUGH_MONEY[] = "\x04 Vous n'avez pas assez de ressources pour ceci. ";
new String:_HD_TOO_MANY_WITCHES[] = "\x04 Vous n'avez plus de witches disponibles ";
new String:_HD_REMAINING_WITCHES[] = "\x05 Witchs restantes : %i";
new String:_HD_WITCH_SPAWN[] = "La Witch est apparue."; // hint
new String:_HD_TOO_MANY_TANKS[] = "\x04 Un seul tank par tour !";
new String:_HD_REMAINING_TANKS[] = "\x05 Tanks restants : %i";
new String:_HD_TANK_SPAWN[] = "Le Tank est apparu."; // hint
new String:_HD_NO_HORDE[] = "\x04 Veuillez patienter 4 minutes pour appeler une nouvelle horde.";
new String:_HD_WAIT_TIME_FOR_HORDE[] = "\x05 Vous ne pouvez plus appeller une nouvelle horde, pendant 4 minutes.";
new String:_HD_HORDE_INCOMING[] = "La horde est appellee !"; // hint
new String:_HD_WAIT_FOR_ANOTHER_HUNTER[] = "\x04 Veuillez patienter 15 secondes avant de recreer un Hunter.";
new String:_HD_WAIT_FOR_ANOTHER_BOOMER[] = "\x04 Veuillez patienter 15 secondes avant de recreer un Boomer";
new String:_HD_WAIT_FOR_ANOTHER_SMOKER[] = "\x04 Veuillez patienter 15 secondes avant de recreer un Smoker";
new String:_HD_CANT_SPAWN_ANY_SPECIAL[] = "\x04 Veuillez patienter avant de faire spawner un nouveau groupe d'infectes speciaux.";
new String:_HD_ALL_INFECTED_ALIVE[] = "\x04 Tous vos infectes speciaux sont deja sur le terrain, ou ils ont deja recu leurs ordres !";
new String:_HD_GO_FURTHER[] = "\x04 Vous etes trop pres des survivants ! Eloignez vous d'eux, en Camera libre !";
new String:_HD_AIM_FURTHER[] = "\x04 Vous visez trop pres des survivants ! Visez ailleurs !";
new String:_HD_FULL_ZOMBIZ[] = "\x04 Il y a trop d'infectes sur le terrain, vous ne pouvez plus en faire apparaitre.";
new String:_HD_WARN_NO_ZOMBIZ[] = "Il n'y a plus d'infectes sur le terrain, remplissez le!"; // hint
new String:_HD_PLUGIN_ACTIVE_SERVER[] = "\x03 Plugin [HUMAN DIRECTOR] active. Les changements s'appliqueront au prochain round.";
new String:_HD_PLUGIN_ACTIVE_ALL[] = "\x03 Plugin [HUMAN DIRECTOR] active. La partie commencera au prochain round.";
new String:_HD_PLUGIN_ACTIVE_ALREADY[] = "\x03 Plugin [HUMAN DIRECTOR] deja active";
new String:_HD_PLUGIN_NOACTIVE_SERVER[] = "\x03 Plugin [HUMAN DIRECTOR] desactive. Les changements s'appliqueront au prochain round.";
new String:_HD_PLUGIN_NOACTIVE_ALL[] = "\x03 Plugin [HUMAN DIRECTOR] desactive. Les changements s'appliqueront au prochain round.";
new String:_HD_PLUGIN_NOACTIVE_ALREADY[] = "\x03 Plugin [HUMAN DIRECTOR] deja desactive";
new String:_HD_WELCOME_START[] = "\x03 Bienvenue au mode '\x04HUMAN DIRECTOR\x03' !! Entrez \x01!hdhelp \x03dans le chat pour plus d'informations sur les commandes.";
new String:_HD_WHO_DIRECTOR[] = "\x04 %s est actuellement le Director."
new String:_HD_WHO_NO_DIRECTOR[] = "\x04 Il n'y a pas encore de Director. Entrez \x01!hddirector \x04dans le chat pour le devenir."
new String:_HD_CAMERALIBRE[] = "\x03 Pour changer la vue en \x04Camera Libre\x03 (quand vous etes mort ou en spectateur), il faut activer l'option \x04Vue Libre\x03 dans 'Multijoueur'.";
new String:_HD_CAMERALIBRE_DEUX[] = "\x03 Enfin, appuyez sur la touche \x04SAUT\x03 pour changer de vue. Visez la zone dans lequel vous voulez apparaitre, quand vous aurez recu un ordre.";
new String:_HD_STATS_TITLE[] = "\x03 Statistiques de jeu :";
new String:_HD_GAME_DIRECTED_BY[] = "\x03 Partie dirigee par %s.";
new String:_HD_NB_NORMAL_INFECTED[] = "\x03 - %i infectes normaux";
new String:_HD_NB_HUNTERS[] = "\x03 - %i Hunters";
new String:_HD_NB_SMOKERS[] = "\x03 - %i Smokers";
new String:_HD_NB_BOOMERS[] = "\x03 - %i Boomers";
new String:_HD_SPAWN_FORCE_ALERT[] = "\x05 Pour cause de votre lenteur, un joueur va automatiquement incarner un special pour un prix plus cher !! Pensez a invoquer les speciaux pour limiter les couts !";
