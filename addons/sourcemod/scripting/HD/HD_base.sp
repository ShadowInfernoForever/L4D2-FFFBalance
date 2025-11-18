// HD_base.sp
// Inclus tout les fichiers du plugin, et initialise ce dernier.
//////////


//Include
#include "HD/HD_startEndRound.sp"
#include "HD/HD_outils.sp"
#include "HD/HD_commande.sp"
#include "HD/HD_menu.sp"
#include "HD/HD_ressource.sp"
#include "HD/HD_convar.sp"
#include "HD/HD_event.sp"
#include "HD/HD_test.sp"
#include "HD/HD_timer.sp"
#include "HD/HD_directorAction.sp"


//Information
public Plugin:myinfo =
{
	name = "Human Director",
	author = "Luc_Skywalker(THE Director, code), ValVal(Text), [CPC]ShinSH(code), la communaute CPC.",
	description = "Le Director est gerer par les joueurs, et non par l'IA.",
	version = "1.031",
	url = "http://www.canardpc.com/"
}




//Demarage et Initialisation (main)
public OnPluginStart()
{	
		//Variables globales à initialiser
		_hBackground = FindConVar("director_force_background");
		_maxClients = GetMaxClients();
		
		//Convars
		_cvDebug = CreateConVar("sm_humandirector_debug", "0", "Debug messages (for Human Director)", FCVAR_PROTECTED);
		_cvForceSpawn = CreateConVar("sm_humandirector_forcespawn", "1", "Force spawn (all 30 seconds)", FCVAR_PROTECTED);
		
		//Evenement
		HookEvent("round_start", eventRoundStart);
		HookEvent("map_transition", eventRoundFin);
		HookEvent("player_spawn", eventJoueurSpawn);
		HookEvent("infected_death", eventInfecteMort);
		HookEvent("tank_spawn", eventTankSpawn);
		
		// Commandes Admins : Activer/Desactiver/bot
		RegServerCmd("sm_hdon", cmdPluginActiver);
		RegServerCmd("sm_hdoff", cmdPluginDesactiver);
		RegServerCmd("sm_hdbot", cmdActiverBot);

		// Commandes (prefix chat : !hd****, prefix console : sm_hd***)
		RegConsoleCmd("sm_hddemission", cmdDemission);
		RegConsoleCmd("sm_hdmenu", cmdMenu);
		RegConsoleCmd("sm_hdspawn", cmdSpawn);
		RegConsoleCmd("sm_hdwhodirector", cmdWhoDirector);
		RegConsoleCmd("sm_hdstats", cmdStats);
		RegConsoleCmd("sm_hddirector", cmdDirector);
		
		RegConsoleCmd("sm_hdquickspawn", cmdQuickSpawn);
		RegConsoleCmd("sm_hdkill", cmdSuicide);
		RegConsoleCmd("sm_hdhelp", cmdHelp);
		
		//Timer
		CreateTimer(_timerTick, tick, _, TIMER_REPEAT);
		CreateTimer(_timerinformationLong, informationLong, _, TIMER_REPEAT);
		CreateTimer(_timerCleanInfecte, cleanInfecte, _, TIMER_REPEAT);
}