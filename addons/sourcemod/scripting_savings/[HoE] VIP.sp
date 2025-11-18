/*=========================================================================================================

	Plugin Info:

*	Name	:	L4D2 Admiral Menu
*	Author	:	alasfourom
*	Descp	:	Display Admiral Menu For Your Loyal Players
*	Link	:	https://forums.alliedmods.net/showthread.php?t=339644
*	Thanks	:	Dragokas, Silvers, AtomicStryker, King_OXO, 000, Eyal282, Eddie, Sourcemod.

===========================================================================================================

	General Updates:

*	20-10-2022 > Version 2.3: Adding more texts color, and general fixes.
*	15-10-2022 > Version 2.2: Fixing some particles positions, and adding an option to change texts color.
*	14-10-2022 > Version 2.1: Clearing admiral ghosts, thanks to Dragokas, and fixed some bugs
*	11-10-2022 > Version 2.0: Data file was added, thanks to Dragokas and some general updates
*	24-09-2022 > Version 1.0: Initial release

 *================================================================================================================ *
 *												Includes, Pragmas and Define			   						   *
 *================================================================================================================ */

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.3"
#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"
#define VOTE_NAME	0
#define VOTE_AUTHID	1
#define	VOTE_IP		2

/* =============================================================================================================== *
 *												Bools, Floats, and ConVars			   							   *
 *================================================================================================================ */

enum struct Admiral
{
	int TimeJoin;
	int TimeDuration;
	int TimeLeft;
}

enum MENU_ACTION
{
	MENU_ACTION_ADD_ADMIRAL,
	MENU_ACTION_ADD_TIME
}

MENU_ACTION g_eMenuAction[MAXPLAYERS+1];

const int TIME_FOREVER = -1;

Menu g_hVoteMenu = null;
char g_VoteInfo [3][65];

int	g_iVotesTarget;
int	g_iNextMapTime;
int g_iWeaponSelectionCounter [MAXPLAYERS+1];
int g_iRecentVotes [MAXPLAYERS+1];
int g_iEntEnvTrail [MAXPLAYERS+1];
int g_iEntParticle [MAXPLAYERS+1];
int g_iMenusTarget [MAXPLAYERS+1];
int g_iBeam;
int g_iHalo;

bool g_bText_White	[MAXPLAYERS+1];
bool g_bText_Green	[MAXPLAYERS+1];
bool g_bText_Olive	[MAXPLAYERS+1];
bool g_bText_Orange	[MAXPLAYERS+1];
bool g_bText_Red	[MAXPLAYERS+1];
bool g_bText_Blue	[MAXPLAYERS+1];
bool g_bText_Gray	[MAXPLAYERS+1];

bool g_bEngineSupportLeft4Dead;
bool g_bPlayersHasLeftSafeArea;

bool g_bPlayerReplenishHealths [MAXPLAYERS+1];
bool g_bClientIsHoldByInfected [MAXPLAYERS+1];
bool g_bInfectedSmokeIsDisable [MAXPLAYERS+1];
bool g_bEnableChatPrefixSwitch [MAXPLAYERS+1];
bool g_bAutoActivePrimaryLaser [MAXPLAYERS+1];

ConVar g_Cvar_AdmiralMenuEnables;
ConVar g_Cvar_AdmiralTagPrefixes;
ConVar g_Cvar_AdmiralWeaponsPick;
ConVar g_Cvar_AdmiralTeamsAccess;
ConVar g_Cvar_AdmiralStartHealth;
ConVar g_Cvar_AdmiralHPLifeSteal;
ConVar g_Cvar_AdmiralVoteBlocker;
ConVar g_Cvar_AdmiralVoteMinimum;
ConVar g_Cvar_AdmiralVotePercent;
ConVar g_Cvar_AdmiralVotebanTime;
ConVar g_Cvar_AdmiralVoteDelayer;
ConVar g_Cvar_AdmiralSmokeEnable;
ConVar g_Cvar_AdmiralSmokeDamage;
ConVar g_Cvar_AdmiralSmokeLength;
ConVar g_Cvar_AdmiralSmokeColors;
ConVar g_Cvar_AdmiralSmokeTimers;

KeyValues g_kv;
char g_sPath[PLATFORM_MAX_PATH];

/* =============================================================================================================== *
 *													Plugin Info			   										   *
 *================================================================================================================ */

public Plugin myinfo =
{
	name = "L4D2 Admiral Menu",
	author = "alasfourom",
	description = "Display Admiral Menu For Your Loyal Players",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=339644"
};

/* =============================================================================================================== *
 *												Plugin Only Supports L4D2			   							   *
 *================================================================================================================ */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bEngineSupportLeft4Dead = true;
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) g_bEngineSupportLeft4Dead = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead: 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

/* =============================================================================================================== *
 *													Plugin Start			   									   *
 *================================================================================================================ */

public void OnPluginStart()
{
	CreateConVar ("l4d2_admiral_menu_version", PLUGIN_VERSION, "L4D2 Admiral Menu", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_Cvar_AdmiralMenuEnables = CreateConVar("l4d2_admiral_menu_enable", "1", "Enable Admiral Menu To Autherized Players (Admins and Admirals).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_AdmiralTagPrefixes = CreateConVar("l4d2_admiral_tag_prefix", "1", "Add Special Tag Prefix And Color Change To Admiral Players When Using Chats.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_AdmiralWeaponsPick = CreateConVar("l4d2_admiral_weapons_selection", "1", "Set How Many Weapons Survivors Are Allowed To Pick From The Weapons Menu.", FCVAR_NOTIFY);
	g_Cvar_AdmiralTeamsAccess = CreateConVar("l4d2_admiral_team_menu_access", "0", "Block Team Switch Menu, And Allow Changing Teams Throw Admiral Menu Only.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_AdmiralStartHealth = CreateConVar("l4d2_admiral_survivors_health", "100", "Set Admiral Survivors Max Health (Above 100 Will Unlock Healing Limit).",FCVAR_NOTIFY, true, 0.0, true, 65535.0);
	g_Cvar_AdmiralHPLifeSteal = CreateConVar("l4d2_admiral_survivors_lifesteal", "0", "Set The Ammount Of Health Admirals Will Get After Killing Special Infected.",FCVAR_NOTIFY, true, 0.0, true, 65535.0);
	g_Cvar_AdmiralVoteBlocker = CreateConVar("l4d2_admiral_callvote_blocker", "1", "Block Access To Call Vote Feature And Only Allow It Through Admin and Admiral Menu.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_AdmiralVoteMinimum = CreateConVar("l4d2_admiral_vote_minplayers", "3", "Set The Minimum Number Of Players Required To Be Able To Initiate A Vote.", FCVAR_NOTIFY, true, 0.0, true, 32.0);
	g_Cvar_AdmiralVotePercent = CreateConVar("l4d2_admiral_vote_percent", "0.51", "Set The Minimum Percentage Required For A Vote To Be Considered Successful.", FCVAR_NOTIFY, true, 0.01, true, 1.00);
	g_Cvar_AdmiralVotebanTime = CreateConVar("l4d2_admiral_vote_ban_time", "30", "Set The Length Of A Vote Ban (In Minutes), After A Successfuly Vote Ban Occurs.", FCVAR_NOTIFY, true, 0.0);
	g_Cvar_AdmiralVoteDelayer = CreateConVar("l4d2_admiral_vote_delay", "120", "Set The Minimum Delay (In Seconds) Between Each Vote To Avoid Abusing It.", FCVAR_NOTIFY, true, 0.0);
	g_Cvar_AdmiralSmokeEnable = CreateConVar("l4d2_admiral_smoke_enable", "1", "Allow Smoke Ability For The Speical Infected (Located In The Upgrades Section).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_AdmiralSmokeDamage = CreateConVar("l4d2_admiral_smoke_damage", "4.0", "Set The Damage Ammount (Every 2 Seconds) When Someone Trapepd Inside The Smoke.", FCVAR_NOTIFY);
	g_Cvar_AdmiralSmokeLength = CreateConVar("l4d2_admiral_smoke_duration", "20.0", "Set The Smoke Duration (In Seconds), After This Time It Will Fade Away", FCVAR_NOTIFY);
	g_Cvar_AdmiralSmokeColors = CreateConVar("l4d2_admiral_smoke_color", "16 122 0", "Set The Smoke RGB Color (Seperated By Space): <Red> <Green> <Blue> (0-255).", FCVAR_NOTIFY);
	g_Cvar_AdmiralSmokeTimers = CreateConVar("l4d2_admiral_smoke_locktime", "60.0", "Set The Time Duration After Which Infected Can Use The Smoke Ability Again (In Seconds).", FCVAR_NOTIFY);
	AutoExecConfig(true, "L4D2_Admiral_Menu");
	
	BuildPath(Path_SM, g_sPath, PLATFORM_MAX_PATH, "data/L4D2_Admiral_Menu.cfg");
	LoadConfig();
	
	RegConsoleCmd("sm_admiral", Command_AdmiralMenu, "Display Admiral Menu");
	RegConsoleCmd("sm_admins", Command_AdminsMenu, "Display Online Admins And Admirals");
	RegConsoleCmd("sm_admiral_reload", Command_AdmiralReload, "Reload Data File");
	
	AddCommandListener(Command_VoteBlocker, "callvote"); 
	
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_freeze_end", Event_OnRoundFreezeEnd);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("bot_player_replace", Event_OnBotPlayerReplace);
	HookEvent("player_left_start_area", Event_LeftStartArea);
	HookEvent("player_left_safe_area", Event_LeftStartArea);
	HookEvent("player_disconnect", Event_PlayerStatusChanged);
	HookEvent("player_connect_full", Event_PlayerStatusChanged);
	HookEvent("weapon_drop", Event_WeaponPickUp);
	HookEvent("item_pickup", Event_WeaponPickUp);
	HookEvent("choke_start", Event_HoldByInfected);
	HookEvent("lunge_pounce", Event_HoldByInfected);
	HookEvent("jockey_ride", Event_HoldByInfected);
	HookEvent("charger_pummel_start", Event_HoldByInfected);
	HookEvent("tongue_grab", Event_HoldByInfected);
	HookEvent("choke_end", Event_ReleasedFromInfected);
	HookEvent("pounce_stopped", Event_ReleasedFromInfected);
	HookEvent("jockey_ride_end", Event_ReleasedFromInfected);
	HookEvent("charger_pummel_end", Event_ReleasedFromInfected);
	HookEvent("tongue_release", Event_ReleasedFromInfected);
}

/* =============================================================================================================== *
 *													OnEntityCreated			   									   *
 *================================================================================================================ */

public void OnEntityCreated(int entity, const char[] sClassName)
{
	if(strcmp(sClassName, "env_spritetrail", false) == 0)
		FixSpriteTrail(entity);
}

/* =============================================================================================================== *
 *											On Map Start, Round Start and End			   						   *
 *================================================================================================================ */

public void OnMapStart()
{
	int index = -1;
	
	while((index = FindEntityByClassname(index, "env_spritetrail")) != -1)
		if (IsValidEdict(index)) FixSpriteTrail(index);
	
	g_iBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHalo = PrecacheModel("materials/sprites/halo01.vmt");	
	
	PrecacheParticle("spitter_slime_trail");
	PrecacheParticle("fire_small_01");
	PrecacheParticle("flame_blue");
	PrecacheParticle("fire_pipe");
	PrecacheParticle("embers_small_01");
	PrecacheParticle("embers_wood_01_smoke");
	
	for (int i = 1; i <= MaxClients; i++)
		Disable_TextColors(i);
}

void Event_OnRoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bPlayerReplenishHealths [i] = false;
		g_bClientIsHoldByInfected [i] = false;
		g_bInfectedSmokeIsDisable [i] = false;
		g_iWeaponSelectionCounter [i] = g_Cvar_AdmiralWeaponsPick.IntValue;
	}
	
	g_bPlayersHasLeftSafeArea = false;
	CreateTimer(0.1, Timer_UnlockHealthLimit, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, Timer_LockTeamChooseMenu, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_UnlockHealthLimit (Handle timer)
{
	if (g_Cvar_AdmiralStartHealth.IntValue == 100) return Plugin_Handled;
	FindConVar("pain_pills_health_threshold").SetFloat(g_Cvar_AdmiralStartHealth.FloatValue - 1);
	FindConVar("first_aid_kit_max_heal").SetFloat(g_Cvar_AdmiralStartHealth.FloatValue - 1);
	return Plugin_Handled;
}
 
Action Timer_LockTeamChooseMenu(Handle timer)
{
	SetConVarInt(FindConVar("sb_all_bot_game"), 1);
	SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
	
	if (g_Cvar_AdmiralTeamsAccess.BoolValue) SetConVarInt(FindConVar("vs_max_team_switches"), 0);
	else ResetConVar(FindConVar("vs_max_team_switches"));
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *												Events: Round Start/End			   								   *
 *================================================================================================================ */

void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

/* =============================================================================================================== *
 *														LoadConfig			   									   *
 *================================================================================================================ */

bool LoadConfig()
{
	g_kv = new KeyValues("Admiral Menu");
	
	if(!FileExists(g_sPath))
		ThrowError("Missing file %s.", g_sPath);
	
	if(!g_kv.ImportFromFile(g_sPath))
	{
		delete g_kv;
		ThrowError("Couldn't open file %s.", g_sPath);
	}

	RemoveAdmiralGhosts();
	return true;
}

/* =============================================================================================================== *
 *											   sm_admins: Command_AdmiralReload			   						   *
 *================================================================================================================ */

Action Command_AdmiralReload(int client, int argc)
{
	if(LoadConfig()) ReplyToCommand(client, "\x04[Admiral Menu] \x01Data file has beed reloaded successfully.");
	else ReplyToCommand(client, "\x04[Admiral Menu] \x01Failed to load data file, please check error logs.");
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *												sm_admiral: Command_AdmiralMenu									   *
 *================================================================================================================ */

Action Command_AdmiralMenu(int client, int args) 
{
	if (g_bEngineSupportLeft4Dead && g_Cvar_AdmiralMenuEnables.BoolValue)
	{
		if (IsPlayerAdmiral(client) || IsClientGenericAdmin(client))
		{
			Create_AdmiralMenu(client);
			//PrintToChat(client, "\x04[Admiral Menu] \x01Player \x05%N \x01Access: \x03Autherized", client);
		}
		else PrintToChat(client, "\x04[Admiral Menu] \x01Player \x05%N \x01Access: \x04Denied", client);
	}
	else PrintToChat(client, "\x04[Admiral Menu] \x01Sorry \x05%N\x01, This Command Is Currently \x04Disabled", client);
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *											CommandListener: Votes Blocker										   *
 *================================================================================================================ */

Action Command_VoteBlocker(int client, char [] command, int args)
{
	if (!g_Cvar_AdmiralVoteBlocker.BoolValue)
	{
		PrintToChatAll("\x04[Voto Bloqueado] \x01 a casaa pt > \x04%N ");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/* =============================================================================================================== *
 *										Add Tag and Chat Color To Admiral Players								   *
 *================================================================================================================ */

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (!IsPlayerAdmiral(client) || !g_Cvar_AdmiralTagPrefixes.BoolValue || !g_bEnableChatPrefixSwitch[client]) return Plugin_Continue;
	
	if (strcmp(command, "say_team", false) != 0)
	{
		Create_FakeBots();
		
		for (int i = 1; i <= MaxClients; i++) 
		{
			if (!IsClientInGame(i) || IsFakeClient(i)) return Plugin_Stop;
			
			if(g_bText_Olive[client]) SayText2(i,  FindRandomPlayersByTeam(3), "\x03(T̶r̸u̶e̵R̷e̶b̴e̸l̷l̷i̸o̶n̶) \x01%N \x01:  %s", client, sArgs);
			else if(g_bText_Green[client]) PrintToChat(i, "\x05(Rebellion) \x04%N \x03:  %s", client, sArgs);
			else if(g_bText_Orange[client]) SayText2(i, client, "\x05(Rebellion) \x03%N \x04:  %s", client, sArgs);
			else if(g_bText_Gray[client]) SayText2(i, FindRandomPlayersByTeam(1), "\x04(Rebellion) \x05%N \x03:  %s", client, sArgs);
			else if(g_bText_Blue[client]) SayText2(i, FindRandomPlayersByTeam(2), "\x04(T̶r̸u̶e̵R̷e̶b̴e̸l̷l̷i̸o̶n̶) \x01%N \x01:  %s", client, sArgs);
			else if(g_bText_Red[client]) SayText2(i,  FindRandomPlayersByTeam(3), "\x03(Pλtient-Zero) \x01%N \x01:  %s", client, sArgs);
			else if(g_bText_White[client]) SayText2(i, client, "\x03(Rebellion) \x06%N \x01:  %s", client, sArgs);
			//else SayText2(i, FindRandomPlayersByTeam(3), "\x03[ .50 AE\x04✏\x03] \x01%N \x01:  %s", client, sArgs);
			else SayText2(i, FindRandomPlayersByTeam(3), "\x03[ENT_INDEX] \x01%N \x01:  %s", client, sArgs);
		}
	}
	else if (strcmp(command, "say_team", true) != -1)
	{
		Create_FakeBots();
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i)) return Plugin_Stop;
			
			if(GetClientTeam(i) == GetClientTeam(client))
			{
				char sTeam[16];
				if (GetClientTeam(client) == 1) Format(sTeam, sizeof(sTeam), "Spectator");
				else if (GetClientTeam(client) == 2) Format(sTeam, sizeof(sTeam), "Survivor");
				else if (GetClientTeam(client) == 3) Format(sTeam, sizeof(sTeam), "Infected");
				
				if(g_bText_Olive[client]) SayText2(i, client, "\x04(Rebellion %s) \x03%N \x05:  %s", sTeam, client, sArgs);
				else if(g_bText_Green[client]) PrintToChat(i, "\x05(Rebellion %s) \x04%N \x03:  %s", sTeam, client, sArgs);
				else if(g_bText_Orange[client]) SayText2(i, client, "\x05(Rebellion %s) \x03%N \x04:  %s", sTeam, client, sArgs);
				else if(g_bText_Gray[client]) SayText2(i, FindRandomPlayersByTeam(1), "\x04(Rebellion %s) \x05%N \x03:  %s", sTeam, client, sArgs);
				else if(g_bText_Blue[client]) SayText2(i, FindRandomPlayersByTeam(2), "\x04(Rebellion %s) \x05%N \x03:  %s", sTeam, client, sArgs);
				//else if(g_bText_Red[client]) SayText2(i, FindRandomPlayersByTeam(3), "\x03(Rebellion %s) \x06%N \x01:  %s", client, sArgs);
				else if(g_bText_White[client]) SayText2(i, client, "\x04(Rebellion %s) \x03%N \x01:  %s", sTeam, client, sArgs);
				else SayText2(i, client, "\x03%N \x01:  %s", sTeam, client, sArgs);
			}
		}
	}
	return Plugin_Stop;
}

void SayText2(int client, int author, const char[] format, any ...)
{
	char sMessage[255];
	VFormat(sMessage, sizeof(sMessage), format, 4);

	Handle hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, sMessage);
	EndMessage();
}

/* =============================================================================================================== *
 *												Create_AdmiralMenu			   									   *
 *================================================================================================================ */

void Create_AdmiralMenu(int client)
{
	Admiral admiral;
	bool IsAdmiral;
	IsAdmiral = GetAdmiralInfo(client, admiral);
	
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
	Menu menu = new Menu(AdmiralMenuList, MENU_ACTIONS_ALL);
	if(admiral.TimeDuration == TIME_FOREVER && IsAdmiral) menu.SetTitle("» NAME: %N \n» %s \n» ACCESS: Autherized \n» TIME: Permanent", client, SteamID);
	else menu.SetTitle("» NAME: %N \n» %s \n» ACCESS: Autherized \n» TIME: %d hr %d min %d sec", client, SteamID, admiral.TimeLeft / 3600, admiral.TimeLeft / 60 % 60, admiral.TimeLeft % 60);
	menu.AddItem("RULES", "Admiral Duties");
	menu.AddItem("COMMANDS", "Server Commands");
	menu.AddItem("APPEARANCE", "Change Appearance");
	menu.AddItem("WEAPONS", "Weapons Menu");
	menu.AddItem("TEAMS", "Teams Manager");
	menu.AddItem("VOTEMENU", "Voting System");
	menu.AddItem("SETTINGS", "Settings");
	menu.Display(client, MENU_TIME_FOREVER);
}

int AdmiralMenuList(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			
			if (StrEqual(item, "RULES")) Create_RulesMenu(param1);
			else if (StrEqual(item, "COMMANDS")) Create_CommandsMenu(param1);
			else if (StrEqual(item, "APPEARANCE")) Create_AppearanceMenu(param1);
			else if (StrEqual(item, "WEAPONS")) Create_WeaponsMenu(param1);
			else if (StrEqual(item, "TEAMS")) Create_TeamsManagerMenu(param1);
			else if (StrEqual(item, "VOTEMENU")) Create_VoteMenu(param1);
			else if (StrEqual(item, "SETTINGS")) Create_SettingsMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Create_RulesMenu			   								   *
 *================================================================================================================ */
		
void Create_RulesMenu(int client)
{
	char sKey[32], sValue[128];
	
	Menu menu = new Menu(RulesList);
	menu.SetTitle("» Admiral Duties: \n ", ITEMDRAW_DEFAULT);
	g_kv.Rewind();
	
	if(!g_kv.JumpToKey("Admiral Duties"))
	{
		delete g_kv;
		ThrowError("Corrupted file %s.", g_sPath);
	}
	
	if(g_kv.GotoFirstSubKey(false))
	{
		do
		{
			if(g_kv.GetSectionName(sKey, sizeof(sKey)))
			{
				g_kv.GetString(NULL_STRING, sValue, sizeof(sValue));
				menu.AddItem("", sValue, ITEMDRAW_DISABLED);
			}
			
		} while(g_kv.GotoNextKey(false));
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int RulesList(Menu menu, MenuAction action, int param1, int param2) 
{
	switch (action) 
	{
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_AdmiralMenu(param1);
			}
    	}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Create_CommandsMenu										 	   *
 *================================================================================================================ */

void Create_CommandsMenu(int client)
{
	char sKey[32], sValue[128];
	Menu menu = new Menu(Handle_CommandsMenu);
	menu.SetTitle("» Server Commands:");
	g_kv.Rewind();
	
	if(!g_kv.JumpToKey("Admiral Commands"))
	{
		delete g_kv;
		ThrowError("Corrupted file %s.", g_sPath);
	}
	
	if(g_kv.GotoFirstSubKey(false))
	{
		do
		{
			if(g_kv.GetSectionName(sKey, sizeof(sKey)))
			{
				g_kv.GetString(NULL_STRING, sValue, sizeof(sValue));
				menu.AddItem(sKey, sValue);
			}
			
		} while(g_kv.GotoNextKey(false));
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_CommandsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			
			if(CommandExists(item)) FakeClientCommand(param1, item);
			else PrintToChat(param1, "\x04[Commands] \x03Error: \x01This command is not implemented in the server.");
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_AdmiralMenu(param1);
			}
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Command Admins										 		   *
 *================================================================================================================ */

Action Command_AdminsMenu(int client, int args)
{
	DispalyOnlineAdminsMenu(client);
	return Plugin_Handled;
}

void DispalyOnlineAdminsMenu(int client)
{
	Menu menu = new Menu(Handle_OnlineAdminsMenu);
	
	char buffer[128];
	int count;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
		
		bool flag = false;
		Format(buffer, sizeof(buffer), "%N", i);
		
		if(IsPlayerAdmiral(i))
		{
			StrCat(buffer, sizeof(buffer), " (Admiral)");
			flag = true;
		}
		
		if(IsClientGenericAdmin(i))
		{
			StrCat(buffer, sizeof(buffer), " (Admin)");
			flag = true;
		}
				
		if(flag)
		{
			++count;
			char sUserID[10];
			int UserID = GetClientUserId(i);
			IntToString(UserID, sUserID, sizeof(sUserID));
			menu.AddItem(sUserID, buffer);
		}
	}
	if (!count) menu.AddItem("", "No Admins/Admirals", ITEMDRAW_DISABLED);
	
	menu.SetTitle("» Online Admins: (%d)", count);
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_OnlineAdminsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Create_AppearanceMenu										   *
 *================================================================================================================ */
			
void Create_AppearanceMenu(int client)
{
	Menu menu = new Menu(Handle_AppearanceMenu);
	menu.SetTitle("» Select An Item:");
	menu.AddItem("COLORS", "Change Color");
	menu.AddItem("AURAS", "Change Aura");
	menu.AddItem("PARTICLES", "Particles Effect");
	menu.AddItem("TRAILS", "Trails Effect");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_AppearanceMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			
			if (StrEqual(item, "COLORS")) Create_ColorsMenu(param1);
			else if (StrEqual(item, "AURAS")) Create_AurasMenu(param1);
			else if (StrEqual(item, "PARTICLES")) Create_ParticlesMenu(param1);
			else if (StrEqual(item, "TRAILS")) Create_TrailsMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_AdmiralMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Create_ColorsMenu											   *
 *================================================================================================================ */

void Create_ColorsMenu(int client)
{
	Menu menu = new Menu(ColorsList);
	menu.SetTitle("» Your Color Menu");
	menu.AddItem("NORMAL", "Normal");
	menu.AddItem("RED", "Red");
	menu.AddItem("ORANGE", "Orange");
	menu.AddItem("YELLOW", "Yellow");
	menu.AddItem("GREEN", "Green");
	menu.AddItem("BLUE", "Blue");
	menu.AddItem("PINK", "Pink");
	menu.AddItem("PURPLE", "Purple");
	menu.AddItem("VIOLET", "Violet");
	menu.AddItem("CYAN", "Cyan");
	menu.AddItem("LIME", "Lime");
	menu.AddItem("BLACK", "Black");
	menu.AddItem("GOLD", "Gold");
	menu.AddItem("RAINBOW", "Rainbow");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int ColorsList(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			
			if (StrEqual(item, "NORMAL"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 255, 255, 255, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Normal\x01.");
			}
			else if (StrEqual(item, "RED"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 255, 0, 0, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Red\x01.");
			}
			else if (StrEqual(item, "ORANGE"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 255, 128, 0, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Orange\x01.");
			}
			else if (StrEqual(item, "YELLOW"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 255, 255, 0, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Yellow\x01.");
			}
			else if (StrEqual(item, "GREEN"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 0, 255, 0, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Green\x01.");
			}
			else if (StrEqual(item, "BLUE"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 0, 0, 255, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Blue\x01.");
			}
			else if (StrEqual(item, "PINK"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 255, 105, 180, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Pink\x01.");
			}
			else if (StrEqual(item, "PURPLE"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 128, 0, 128, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Purple\x01.");
			}
			else if (StrEqual(item, "VIOLET"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 249, 19, 250, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Violet\x01.");
			}
			else if (StrEqual(item, "CYAN"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 0, 255, 255, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Cyan\x01.");
			}
			else if (StrEqual(item, "LIME"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 128, 255, 0, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Lime\x01.");
			}
			else if (StrEqual(item, "BLACK"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 0, 0, 0, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Black\x01.");
			}
			else if (StrEqual(item, "GOLD"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Color);
				SetEntityRenderColor(param1, 255, 215, 0, 255);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Gold\x01.");
			}
			else if (StrEqual(item, "RAINBOW"))
			{
				SDKHook(param1, SDKHook_PreThink, Rainbow_Color);
				PrintToChat(param1, "\x04[Color] \x01Your Color Has Been Set To \x05Rainbow\x01.");
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_AppearanceMenu(param1);
			}
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *												Method To Give Rainbow Color				 					   *
 *================================================================================================================ */

Action Rainbow_Color(int client)
{
	if (!(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)))
		SDKUnhook(client, SDKHook_PreThink, Rainbow_Color);
    
	int color[3];
	color[0] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 1) * 127.5 + 127.5);
	color[1] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 3) * 127.5 + 127.5);
	color[2] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 5) * 127.5 + 127.5);
    
	SetEntityRenderColor(client, color[0], color[1], color[2], 255);
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *													Create_AurasMenu											   *
 *================================================================================================================ */

void Create_AurasMenu(int client)
{
	Menu menu = new Menu(AuraList);
	menu.SetTitle("» Your Aura Menu");
	menu.AddItem("NORMAL", "Normal");
	menu.AddItem("RED", "Red");
	menu.AddItem("ORANGE", "Orange");
	menu.AddItem("YELLOW", "Yellow");
	menu.AddItem("GREEN", "Green");
	menu.AddItem("BLUE", "Blue");
	menu.AddItem("PINK", "Pink");
	menu.AddItem("PURPLE", "Purple");
	menu.AddItem("VIOLET", "Violet");
	menu.AddItem("CYAN", "Cyan");
	menu.AddItem("LIME", "Lime");
	menu.AddItem("WHITE", "White");
	menu.AddItem("GOLD", "Gold");
	menu.AddItem("RAINBOW", "Rainbow");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int AuraList(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			
			if (StrEqual(item, "NORMAL"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 0);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", 0);
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05Normal\x01.");
			}
			else if (StrEqual(item, "RED"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (0 * 65536));
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05RED\x01.");
			}
			else if (StrEqual(item, "ORANGE"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", 255 + (128 * 256) + (0 * 65536));
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05ORANGE\x01.");
			}
			else if (StrEqual(item, "YELLOW"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", 255 + (255 * 256) + (0 * 65536));
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05YELLOW\x01.");
			}
			else if (StrEqual(item, "GREEN"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", 0 + (255 * 256) + (0 * 65536));
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05GREEN\x01.");
			}
			else if (StrEqual(item, "BLUE"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", 7 + (19 * 256) + (250 * 65536));
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05BLUE\x01.");
			}
			else if (StrEqual(item, "PINK"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (150 * 65536));
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05PINK\x01.");
			}
			else if (StrEqual(item, "PURPLE"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", 155 + (0 * 256) + (255 * 65536));
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05PURPLE\x01.");
			}
			else if (StrEqual(item, "VIOLET"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", 249 + (19 * 256) + (250 * 65536));
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05VIOLET\x01.");
			}
			else if (StrEqual(item, "CYAN"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", 66 + (250 * 256) + (250 * 65536));
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05CYAN\x01.");
			}
			else if (StrEqual(item, "LIME"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", 128 + (255 * 256) + (0 * 65536));
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05LIME\x01.");
			}
			else if (StrEqual(item, "WHITE"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", -1 + (-1 * 256) + (-1 * 65536));
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05WHITE\x01.");
			}
			else if (StrEqual(item, "GOLD"))
			{
				SDKUnhook(param1, SDKHook_PreThink, Rainbow_Aura);
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SetEntPropEx(param1, Prop_Send, "m_glowColorOverride", 249 + (155 * 256) + (84 * 65536));
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05GOLD\x01.");
			}
			else if (StrEqual(item, "RAINBOW"))
			{
				SetEntPropEx(param1, Prop_Send, "m_iGlowType", 3);
				SDKHook(param1, SDKHook_PreThink, Rainbow_Aura);
				PrintToChat(param1, "\x04[Aura] \x01Your Aura Has Been Set To \x05RAINBOW\x01.");
			}
		}
		case MenuAction_Cancel:
		{
            if (param2 == MenuCancel_ExitBack) 
            {
                Create_AppearanceMenu(param1);
			}
    	}
	}
	return 0;
}

Action Rainbow_Aura(int client)
{
	if (!(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)))
		SDKUnhook(client, SDKHook_PreThink, Rainbow_Aura);
    
	int color[3];
	color[0] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 1) * 127.5 + 127.5);
	color[1] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 3) * 127.5 + 127.5);
	color[2] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 5) * 127.5 + 127.5);
    
	SetEntPropEx(client, Prop_Send, "m_glowColorOverride", color[0] + (color[1] * 256) + (color[2] * 65536));
	SetEntPropEx(client, Prop_Send, "m_iGlowType", 3);
	SetEntPropEx(client, Prop_Send, "m_nGlowRange", 99999);
	SetEntPropEx(client, Prop_Send, "m_nGlowRangeMin", 0);
	
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *											Double Check To Reset Aura and Colors								   *
 *================================================================================================================ */

void Event_PlayerStatusChanged(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || IsFakeClient(client)) return;
	
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SDKUnhook(client, SDKHook_PreThink, Rainbow_Aura);
	SetEntPropEx(client, Prop_Send, "m_iGlowType", 0);
	SetEntPropEx(client, Prop_Send, "m_glowColorOverride", 0);
}

/* =============================================================================================================== *
 *												Create_ParticlesMenu											   *
 *================================================================================================================ */

void Create_ParticlesMenu(int client)
{
	Menu menu = new Menu(ParticlesList, MENU_ACTIONS_ALL);
	menu.SetTitle("» Select A Particle:");
	menu.AddItem("NORMAL", "Normal");
	menu.AddItem("SPIT", "Spit");
	menu.AddItem("FIRE", "Fire");
	menu.AddItem("BLUEFLAME", "Blue Flame");
	menu.AddItem("REDFLAME", "Red Flame");
	menu.AddItem("EMBER", "Ember");
	menu.AddItem("SMOKE", "Smoke");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int ParticlesList(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			
			if (StrEqual(item, "NORMAL")) Particle_Remove(param1);
			else if (StrEqual(item, "SPIT")) Particle_Spit(param1);
			else if (StrEqual(item, "FIRE")) Particle_Fire(param1);
			else if (StrEqual(item, "BLUEFLAME")) Particle_BlueFlame(param1);
			else if (StrEqual(item, "REDFLAME")) Particle_RedFlame(param1);
			else if (StrEqual(item, "EMBER")) Particle_Ember(param1);
			else if (StrEqual(item, "SMOKE")) Particle_Smoke(param1);
		}
		case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack) 
            {
                Create_AppearanceMenu(param1);
			}
    	}
	}
	return 0;
}

/* =============================================================================================================== *
 *										Particles: Using Silvers Method In Dev Cmd								   *
 *================================================================================================================ */

void Particle_Remove(int client)
{
	if(g_iEntParticle[client] && EntRefToEntIndex(g_iEntParticle[client]) != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(g_iEntParticle[client], "Kill");
		PrintToChat(client, "\x04[Particle] \x01Your Particle Has Been Set To \x05Normal\x01.");
	}
}

void Particle_Spit(int client)
{
	if(g_iEntParticle[client] && EntRefToEntIndex(g_iEntParticle[client]) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(g_iEntParticle[client], "Kill");
	
	char sAttachment[12];
	FormatEx(sAttachment, sizeof(sAttachment), "forward");
	g_iEntParticle[client] = DisplayParticle("spitter_slime_trail", view_as<float>({ 0.0, 0.0, 0.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
	g_iEntParticle[client] = EntIndexToEntRef(g_iEntParticle[client]);
	PrintToChat(client, "\x04[Particle] \x01Your Particle Has Been Set To \x05Spit\x01.");
}

void Particle_Fire(int client)
{
	if(g_iEntParticle[client] && EntRefToEntIndex(g_iEntParticle[client]) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(g_iEntParticle[client], "Kill");
	
	char sAttachment[12];
	FormatEx(sAttachment, sizeof(sAttachment), "forward");
	g_iEntParticle[client] = DisplayParticle("fire_small_01", view_as<float>({ 0.0, 0.0, -58.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
	g_iEntParticle[client] = EntIndexToEntRef(g_iEntParticle[client]);
	PrintToChat(client, "\x04[Particle] \x01Your Particle Has Been Set To \x05Fire\x01.");
}

void Particle_BlueFlame(int client)
{
	if(g_iEntParticle[client] && EntRefToEntIndex(g_iEntParticle[client]) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(g_iEntParticle[client], "Kill");
	
	char sAttachment[12];
	FormatEx(sAttachment, sizeof(sAttachment), "forward");
	g_iEntParticle[client] = DisplayParticle("flame_blue", view_as<float>({ 0.0, 0.0, -50.0 }), view_as<float>({ 0.0, 180.0, 0.0 }), client, sAttachment);
	g_iEntParticle[client] = EntIndexToEntRef(g_iEntParticle[client]);
	PrintToChat(client, "\x04[Particle] \x01Your Particle Has Been Set To \x05Blue Flame\x01.");
}

void Particle_RedFlame(int client)
{
	if(g_iEntParticle[client] && EntRefToEntIndex(g_iEntParticle[client]) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(g_iEntParticle[client], "Kill");
	
	char sAttachment[12];
	FormatEx(sAttachment, sizeof(sAttachment), "forward");
	g_iEntParticle[client] = DisplayParticle("fire_pipe", view_as<float>({ 0.0, 0.0, -50.0 }), view_as<float>({ 0.0, 180.0, 0.0 }), client, sAttachment);
	g_iEntParticle[client] = EntIndexToEntRef(g_iEntParticle[client]);
	PrintToChat(client, "\x04[Particle] \x01Your Particle Has Been Set To \x05Red Flame\x01.");
}

void Particle_Ember(int client)
{
	if(g_iEntParticle[client] && EntRefToEntIndex(g_iEntParticle[client]) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(g_iEntParticle[client], "Kill");
	
	char sAttachment[12];
	FormatEx(sAttachment, sizeof(sAttachment), "forward");
	g_iEntParticle[client] = DisplayParticle("embers_small_01", view_as<float>({ 0.0, 0.0, -50.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
	g_iEntParticle[client] = EntIndexToEntRef(g_iEntParticle[client]);
	PrintToChat(client, "\x04[Particle] \x01Your Particle Has Been Set To \x05Ember\x01.");
}

void Particle_Smoke(int client)
{
	if(g_iEntParticle[client] && EntRefToEntIndex(g_iEntParticle[client]) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(g_iEntParticle[client], "Kill");
	
	char sAttachment[12];
	FormatEx(sAttachment, sizeof(sAttachment), "forward");
	g_iEntParticle[client] = DisplayParticle("embers_wood_01_smoke", view_as<float>({ 0.0, 0.0, -50.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
	g_iEntParticle[client] = EntIndexToEntRef(g_iEntParticle[client]);
	PrintToChat(client, "\x04[Particle] \x01Your Particle Has Been Set To \x05Smoke\x01.");
}

int DisplayParticle(char[] sParticle, float vPos[3], float fAng[3], int client = 0, const char[] sAttachment = "")
{
	int entity = CreateEntityByName("info_particle_system");

	if( entity != -1 && IsValidEdict(entity) )
	{
		DispatchKeyValue(entity, "effect_name", sParticle);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");

		if(client)
		{
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client);
			
			if(strlen(sAttachment) != 0)
			{
				SetVariantString(sAttachment);
				AcceptEntityInput(entity, "SetParentAttachment");
			}
		}

		TeleportEntity(entity, vPos, fAng, NULL_VECTOR);

		return entity;
	}
	return 0;
}

/* =============================================================================================================== *
 *													Create_TrailsMenu											   *
 *================================================================================================================ */

void Create_TrailsMenu(int client)
{
	Menu menu = new Menu(Handle_TrailsMenu, MENU_ACTIONS_ALL);
	menu.SetTitle("» Select A Color:");
	menu.AddItem("NORMAL", "Normal");
	menu.AddItem("RED", "Red");
	menu.AddItem("ORANGE", "Orange");
	menu.AddItem("YELLOW", "Yellow");
	menu.AddItem("GREEN", "Green");
	menu.AddItem("BLUE", "Blue");
	menu.AddItem("PINK", "Pink");
	menu.AddItem("PURPLE", "Purple");
	menu.AddItem("VIOLET", "Violet");
	menu.AddItem("CYAN", "Cyan");
	menu.AddItem("LIME", "Lime");
	menu.AddItem("WHITE", "White");
	menu.AddItem("GOLD", "Gold");
	menu.AddItem("MIDNIGHT", "Midnight");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_TrailsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			
			if (StrEqual(item, "NORMAL"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
				{
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
					PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Normal\x01.");
				}
			}
			else if (StrEqual(item, "RED"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "255 0 0");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Red\x01.");
			}
			else if (StrEqual(item, "ORANGE"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "255 128 0");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Orange\x01.");
			}
			else if (StrEqual(item, "YELLOW"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "255 255 0");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Yellow\x01.");
			}
			else if (StrEqual(item, "GREEN"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "0 255 0");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Green\x01.");
			}
			else if (StrEqual(item, "BLUE"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "0 0 255");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Blue\x01.");
			}
			else if (StrEqual(item, "PINK"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "255 153 255");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Pink\x01.");
			}
			else if (StrEqual(item, "PURPLE"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "102 0 102");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Purple\x01.");
			}
			else if (StrEqual(item, "VIOLET"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "127 0 255");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Violet\x01.");
			}
			else if (StrEqual(item, "CYAN"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "0 204 204");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Cyan\x01.");
			}
			else if (StrEqual(item, "LIME"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "153 255 51");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Lime\x01.");
			}
			else if (StrEqual(item, "WHITE"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "255 255 255");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05White\x01.");
			}
			else if (StrEqual(item, "GOLD"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "218 165 32");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Gold\x01.");
			}
			else if (StrEqual(item, "MIDNIGHT"))
			{
				if(g_iEntEnvTrail[param1] && EntRefToEntIndex(g_iEntEnvTrail[param1]) != INVALID_ENT_REFERENCE)
					AcceptEntityInput(g_iEntEnvTrail[param1], "Kill");
				
				g_iEntEnvTrail[param1] = SetEntityTrail(param1, "0 51 51");
				g_iEntEnvTrail[param1] = EntIndexToEntRef(g_iEntEnvTrail[param1]);
				PrintToChat(param1, "\x04[Trail] \x01Your Trail Has Been Set To \x05Midnight\x01.");
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
            {
				Create_AppearanceMenu(param1);
			}
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *										Method To Create Tails: (000) Plugin									   *
 *================================================================================================================ */

int SetEntityTrail(int client = 0, char[] sColor)
{
	float vPos[3];
	GetClientAbsOrigin(client, vPos);
	vPos[2] += 10;
	
	int entity = CreateEntityByName("env_spritetrail");
	
	if(entity != -1 && IsValidEdict(entity))
	{
		DispatchKeyValue(entity, "lifetime", "2.0");
		DispatchKeyValue(entity, "startwidth", "8.0");
		DispatchKeyValue(entity, "endwidth", "2.0");
		DispatchKeyValue(entity, "spritename", "materials/sprites/laserbeam.vmt");
		DispatchKeyValue(entity, "rendermode", "5");
		DispatchKeyValue(entity, "rendercolor", sColor);
		DispatchKeyValue(entity, "renderamt", "255");
		DispatchSpawn(entity);
		
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		SetVariantString("!activator");
		
		AcceptEntityInput(entity, "SetParent", client);
		AcceptEntityInput(entity, "ShowSprite");
		AcceptEntityInput(entity, "Start");
		return entity;
	}
	return 0;
}

void FixSpriteTrail(int entity)
{
	SetVariantString("OnUser1 !self:SetScale:2:0.5:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}

/* =============================================================================================================== *
 *													Create_WeaponsMenu											   *
 *================================================================================================================ */

void Create_WeaponsMenu(int client)
{
	Menu menu = new Menu(Handle_WeaponsMenu, MENU_ACTIONS_ALL);
	menu.SetTitle("» Select A Section:");
	menu.AddItem("HEALTH", "Health Products");
	menu.AddItem("PRIMARY", "Primary Weapons");
	menu.AddItem("SECONDARY", "Secondary Weapons");
	menu.AddItem("EQUIPMENTS", "Equipments");
	menu.AddItem("UPGRADES", "Upgrades");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_WeaponsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			
			if (StrEqual(item, "HEALTH")) Create_HealthMenu(param1);
			else if (StrEqual(item, "PRIMARY")) Create_PrimaryWeaponsMenu(param1);
			else if (StrEqual(item, "SECONDARY")) Create_SecondaryWeaponsMenu(param1);
			else if (StrEqual(item, "EQUIPMENTS")) Create_EquipmentsMenu(param1);
			else if (StrEqual(item, "UPGRADES")) Create_UpgradesMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_AdmiralMenu(param1);
			}
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Create_HealthMenu											   *
 *================================================================================================================ */

void Create_HealthMenu(int client)
{
	Menu menu = new Menu(Handle_HealthMenu, MENU_ACTIONS_ALL);
	menu.SetTitle("» Select Your Item \n» (%d) Items Allowed To Pick", g_iWeaponSelectionCounter[client]);
	menu.AddItem("KITS", "First Aid Kit");
	menu.AddItem("PILLS", "Pills Medicine");
	menu.AddItem("ADREN", "Adrenaline Medicine");
	menu.AddItem("DEFIB", "Defibrillator");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_HealthMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			
			if (StrEqual(item, "KITS")) GiveFirstAidKits(param1);
			else if (StrEqual(item, "PILLS")) GivePainPills(param1);
			else if (StrEqual(item, "ADREN")) GiveAdrenaline(param1);
			else if (StrEqual(item, "DEFIB")) GiveDefibrillator(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_WeaponsMenu(param1);
			}
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *												Create_PrimaryWeaponsMenu										   *
 *================================================================================================================ */

void Create_PrimaryWeaponsMenu(int client)
{
	Menu menu = new Menu(Handle_PrimaryWeaponsMenu, MENU_ACTIONS_ALL);
	menu.SetTitle("» Select Your Item \n» (%d) Items Allowed To Pick", g_iWeaponSelectionCounter[client]);
	menu.AddItem("SMG", "SMG");
	menu.AddItem("SILENCE", "Silence SMG");
	menu.AddItem("MP5", "SMG MP5");
	menu.AddItem("PUMP", "Pump Shotgun");
	menu.AddItem("CHROME", "Chrome Shutgun");
	menu.AddItem("AUTO", "Auto Shutgun");
	menu.AddItem("SPAS", "Spas Shotgun");
	menu.AddItem("DESERT", "Desert Rifle");
	menu.AddItem("SG552", "SG552 Rifle");
	menu.AddItem("M16", "M-16 Rifle");
	menu.AddItem("AK47", "AK-47 Rifle");
	menu.AddItem("HUNTING", "Hunting Sniper");
	menu.AddItem("MILITARY", "Military Sniper");
	menu.AddItem("AWP", "AWP Sniper");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_PrimaryWeaponsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			
			if (StrEqual(item, "SMG")) GiveSMG(param1);
			else if (StrEqual(item, "SILENCE")) GiveSilenceSMG(param1);
			else if (StrEqual(item, "MP5")) GiveMP5(param1);
			else if (StrEqual(item, "PUMP")) GivePumpShotgun(param1);
			else if (StrEqual(item, "CHROME")) GiveChromeShotgun(param1);
			else if (StrEqual(item, "AUTO")) GiveAutoShotgun(param1);
			else if (StrEqual(item, "SPAS")) GiveSpasShotgun(param1);
			else if (StrEqual(item, "DESERT")) GiveDesertRifle(param1);
			else if (StrEqual(item, "SG552")) GiveSG552(param1);
			else if (StrEqual(item, "M16")) GiveM16(param1);
			else if (StrEqual(item, "AK47")) GiveAK47(param1);
			else if (StrEqual(item, "HUNTING")) GiveHuntingRifle(param1);
			else if (StrEqual(item, "MILITARY")) GiveMilitarySniper(param1);
			else if (StrEqual(item, "AWP")) GiveAWP(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_WeaponsMenu(param1);
			}
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *												Create_SecondaryWeaponsMenu										   *
 *================================================================================================================ */

void Create_SecondaryWeaponsMenu(int client)
{
	Menu menu = new Menu(Handle_SecondaryWeaponsMenu, MENU_ACTIONS_ALL);
	menu.SetTitle("» Select Your Item \n» (%d) Items Allowed To Pick", g_iWeaponSelectionCounter[client]);
	menu.AddItem("PISTOL", "Pistol");
	menu.AddItem("MAGNUM", "Magnum");
	menu.AddItem("BAT", "Bat");
	menu.AddItem("MACHETE", "Machete");
	menu.AddItem("KATANA", "Katana");
	menu.AddItem("TONFA", "Tonfa");
	menu.AddItem("FIREAXE", "Fire Axe");
	menu.AddItem("KNIFE", "Knife");
	menu.AddItem("PAN", "Pan");
	menu.AddItem("CROWBAR", "Crowbar");
	menu.AddItem("GOLDCLUB", "Gold Club");
	menu.AddItem("SHOVEL", "Shovel");
	menu.AddItem("PITCHFORK", "Pitchfork");
	menu.AddItem("CHAINSAW", "Chainsaw");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_SecondaryWeaponsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			
			if (StrEqual(item, "PISTOL")) GivePistol(param1);
			else if (StrEqual(item, "MAGNUM")) GiveMagnum(param1);
			else if (StrEqual(item, "BAT")) GiveBat(param1);
			else if (StrEqual(item, "MACHETE")) GiveMachete(param1);
			else if (StrEqual(item, "KATANA")) GiveKatana(param1);
			else if (StrEqual(item, "TONFA")) GiveTonfa(param1);
			else if (StrEqual(item, "FIREAXE")) GiveFireAxe(param1);
			else if (StrEqual(item, "KNIFE")) GiveKnife(param1);
			else if (StrEqual(item, "PAN")) GivePan(param1);
			else if (StrEqual(item, "CROWBAR")) GiveCrowbar(param1);
			else if (StrEqual(item, "GOLDCLUB")) GiveGolfClub(param1);
			else if (StrEqual(item, "SHOVEL")) GiveShovel(param1);
			else if (StrEqual(item, "PITCHFORK")) GivePitchfork(param1);
			else if (StrEqual(item, "CHAINSAW")) GiveChainsaw(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_WeaponsMenu(param1);
			}
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Create_EquipmentsMenu										   *
 *================================================================================================================ */

void Create_EquipmentsMenu(int client)
{
	Menu menu = new Menu(Handle_EquipmentsMenu, MENU_ACTIONS_ALL);
	menu.SetTitle("» Select Your Item \n» (%d) Items Allowed To Pick", g_iWeaponSelectionCounter[client]);
	menu.AddItem("PIPE", "Pipe Bomb");
	menu.AddItem("MOLLY", "Molotov");
	menu.AddItem("BILE", "Bile Bomb");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_EquipmentsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			
			if (StrEqual(item, "PIPE")) GivePipeBomb(param1);
			else if (StrEqual(item, "MOLLY")) GiveMolotov(param1);
			else if (StrEqual(item, "BILE")) GiveBileBomb(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_WeaponsMenu(param1);
			}
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Create_UpgradesMenu											   *
 *================================================================================================================ */

void Create_UpgradesMenu(int client)
{
	Menu menu = new Menu(UpgradesList, MENU_ACTIONS_ALL);
	menu.SetTitle("» Select An Upgrade:");
	menu.AddItem("LASER", "Laser");
	menu.AddItem("AMMO", "Ammo");
	menu.AddItem("VISION", "Night Vision");
	menu.AddItem("SMOKE", "Toxic Smoke");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int UpgradesList(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			
			if (StrEqual(item, "LASER")) ToggleLaser(param1);
			else if (StrEqual(item, "AMMO")) GiveAmmo(param1);
			else if (StrEqual(item, "VISION")) ToggleNightVision(param1);
			else if (StrEqual(item, "SMOKE")) ActivateSmoke(param1);
		}
		case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack) 
            {
                Create_WeaponsMenu(param1);
			}
    	}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Give Health Items											   *
 *================================================================================================================ */
 
Action GiveFirstAidKits(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "first_aid_kit");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05First Aid\x01.");
			Create_HealthMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GivePainPills(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "pain_pills");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Pill\x01.");
			Create_HealthMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveAdrenaline(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "adrenaline");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Adrenaline\x01.");
			Create_HealthMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveDefibrillator(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "defibrillator");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Defibrillator\x01.");
			Create_HealthMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *													Give Primary Weapons										   *
 *================================================================================================================ */

Action GiveSMG(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "smg");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05SMG\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveSilenceSMG(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "smg_silenced");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Silence SMG\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveMP5(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "smg_mp5");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05MP5\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GivePumpShotgun(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "pumpshotgun");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Pump Shotgun\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveChromeShotgun(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "shotgun_chrome");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Chrome Shotgun\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveAutoShotgun(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "autoshotgun");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Auto Shotgun\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveSpasShotgun(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "shotgun_spas");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Shotgun Spas\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveDesertRifle(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "rifle_desert");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Desert Rifle\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveSG552(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "rifle_sg552");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05SG552 Rifle\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveM16(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "rifle");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05M-16 Rifle\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveAK47(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "rifle_ak47");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05AK-47 Rifle\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveHuntingRifle(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "hunting_rifle");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved A \x05Hunting Rifle\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveMilitarySniper(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "sniper_military");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Military\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveAWP(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "sniper_awp");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05AWP\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *													Give Secondary Weapons										   *
 *================================================================================================================ */

Action GiveMachete(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "machete");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Machete\x01.");
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GivePistol(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "pistol");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Pistol\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

			
Action GiveMagnum(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "pistol_magnum");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Magnum\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveBat(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "cricket_bat");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Bat\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveKatana(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "katana");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Katana\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveTonfa(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "tonfa");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Tonfa\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveFireAxe(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "fireaxe");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Fire Axe\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveKnife(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "knife");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Knife\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GivePan(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "frying_pan");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Pan\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveCrowbar(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "crowbar");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Crow Bar\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveGolfClub(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "golfclub");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Golf Club\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveShovel(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "shovel");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Shovel\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GivePitchfork(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "pitchfork");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Pitchfork\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveChainsaw(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "chainsaw");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Chain Saw\x01.");
			Create_PrimaryWeaponsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *													Give Equipments												   *
 *================================================================================================================ */

Action GivePipeBomb(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "pipe_bomb");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Pipe Bomb\x01.");
			Create_EquipmentsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveMolotov(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "molotov");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Molotov\x01.");
			Create_EquipmentsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

Action GiveBileBomb(int client)
{
	if (g_iWeaponSelectionCounter[client] > 0)
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			-- g_iWeaponSelectionCounter[client];
			CheatCommand(client, "give", "vomitjar");
			PrintToChat(client, "\x04[Weapons] \x01You Have Recieved: \x05Bile Bomb\x01.");
			Create_EquipmentsMenu(client);
		}
		else PrintToChat(client, "\x04[Weapons] \x01Only \x05Survivors \x01Are Allowed To Get A Weapon.");
	}
	else PrintToChat(client, "\x04[Weapons] \x01You Can't Recieve \x05Weapons \x01Any More.");
	
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *													 Give Upgrades												   *
 *================================================================================================================ */

/* =============================================================================================================== *
 *												Laser Activation Method											   *
 *================================================================================================================ */

Action ToggleLaser(int client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		//This Method Was Taken From Unamed Scipt By cravenge
		int iPrimary = GetPlayerWeaponSlot(client, 0);
		if (iPrimary < 1 || !IsValidEntity(iPrimary) || !IsValidEdict(iPrimary))
		{
			PrintToChat(client, "\x04[Upgrades] \x01You Are Not Allowed To Use \x05Laser Upgrade\x01.");
			return Plugin_Handled;
		}
			
		char sEntityNetClass[32];
		GetEntityNetClass(iPrimary, sEntityNetClass, sizeof(sEntityNetClass));
		
		if (FindSendPropInfo(sEntityNetClass, "m_upgradeBitVec") > 0)
		{
			int iUpgradeBits = GetEntProp(iPrimary, Prop_Send, "m_upgradeBitVec");
			if (iUpgradeBits & (1 << 2)) //If You Have Already Laser
			{
				SetEntPropEx(iPrimary, Prop_Send, "m_upgradeBitVec", 0);
				PrintToChat(client, "\x04[Upgrades] \x01You Have Turned \x05Laser OFF\x01.");
			}
			else // If You don't have laser, activate it
			{
				SetEntPropEx(iPrimary, Prop_Send, "m_upgradeBitVec", iUpgradeBits | (1 << 2));
				PrintToChat(client, "\x04[Upgrades] \x01You Have Turned \x05Laser ON\x01.");
			}
		}
	}
	else PrintToChat(client, "\x04[Upgrades] \x01Only \x05Alive Survivors \x01Can Get Laser.");
	
	return Plugin_Handled;
}

void Event_WeaponPickUp(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!client || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !g_bAutoActivePrimaryLaser[client]) return;

	char sWeapon[32];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));
	if (StrEqual(sWeapon, "weapon_grenade_launcher")) return;

	char sEntityNetClass[32];
	int iPrimary = GetPlayerWeaponSlot(client, 0);
	if (iPrimary < 1 || !IsValidEntity(iPrimary) || !IsValidEdict(iPrimary)) return;
	
	GetEntityNetClass(iPrimary, sEntityNetClass, sizeof(sEntityNetClass));
	if (FindSendPropInfo(sEntityNetClass, "m_upgradeBitVec") > 0)
	{
		int iUpgradeBits = GetEntProp(iPrimary, Prop_Send, "m_upgradeBitVec");
		if (iUpgradeBits & (1 << 2)) return;
		else // If You don't have laser, activate it
		{
			SetEntPropEx(iPrimary, Prop_Send, "m_upgradeBitVec", iUpgradeBits | (1 << 2));
			PrintToChat(client, "\x04[Upgrades] \x01You Have Turned \x05Laser ON\x01.");
		}
	}
}

/* =============================================================================================================== *
 *														Give Ammo												   *
 *================================================================================================================ */

Action GiveAmmo(int client)
{
	if (!client || !IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04[Upgrades] \x01Only \x05Alive Survivors \x01Can Recieve Ammo.");
		return Plugin_Handled;
	}
	
	else if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "\x04[Upgrades] \x01Only \x05Survivors \x01Can Recieve Ammo.");
		return Plugin_Handled;
	}
	
	else
	{
		CheatCommand(client, "give", "ammo");
		FakeClientCommand(client, "give ammo");
	}
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *											Night Vision Activation Method										   *
 *================================================================================================================ */

Action ToggleNightVision(int client)
{
	int NightVisionActivated = GetEntProp(client, Prop_Send, "m_bNightVisionOn");
	
	if (!IsClientInGame(client) && IsFakeClient(client) && !IsPlayerAlive(client) && GetClientTeam(client != 2))
	{
		PrintToChat(client, "\x04[Upgrades] \x01Only \x05Alive Survivors \x01Can Get Upgrades.");
		return Plugin_Handled;
	}
	else if (NightVisionActivated == 0)
	{
		SetEntPropEx(client, Prop_Send, "m_bNightVisionOn", 1); 
		PrintToChat(client, "\x04[Upgrades] \x01You Have Turned \x05NightVision ON\x01.");
	}
	else
	{
		SetEntPropEx(client, Prop_Send, "m_bNightVisionOn", 0);
		PrintToChat(client, "\x04[Upgrades] \x01You Have Turned \x05NightVision OFF\x01.");	
	}
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *										Smoke: Using AtomicStryker Smoke Plugin			   						   *
 *================================================================================================================ */

Action ActivateSmoke(int client)
{
	if (!g_Cvar_AdmiralSmokeEnable.BoolValue)
	{
		PrintToChat(client, "\x04[Upgrades] \x01This Upgrade Is Currently \x05Disabled\x01.");
		return Plugin_Handled;
	}
	
	else if (GetClientTeam(client) != 3 || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_isGhost") == 1)
	{
		PrintToChat(client, "\x04[Upgrades] \x01This Upgrade Can Be Activated By \x05Alive Infected\x01 Only.");
		return Plugin_Handled;
	}
		
	else if (g_bInfectedSmokeIsDisable[client])
	{
		PrintToChat(client, "\x04[Upgrades] \x01You Cant Use This Ability Too Often.");
		return Plugin_Handled;
	}
	
	else
	{
		float g_pos[3];
		GetClientEyePosition(client, g_pos);	
		CreateGasCloud(client, g_pos);
		
		PrintToChat(client, "\x04[Upgrades] \x01You Have Activated The \x05Toxic Smoke\x01.");
		g_bInfectedSmokeIsDisable[client] = true;
		CreateTimer(g_Cvar_AdmiralSmokeTimers.FloatValue, Timer_SmokeResetTime, client, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}
}

Action Timer_SmokeResetTime(Handle timer, int client)
{
	g_bInfectedSmokeIsDisable[client] = false;
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *												Method To Create Smoke			   								   *
 *================================================================================================================ */

void CreateGasCloud(int client, float g_pos[3])
{	
	float targettime = GetEngineTime() + g_Cvar_AdmiralSmokeLength.FloatValue;
	
	DataPack data = new DataPack();
	data.WriteCell(client);
	data.WriteFloat(g_pos[0]);
	data.WriteFloat(g_pos[1]);
	data.WriteFloat(g_pos[2]);
	data.WriteFloat(targettime);
	
	CreateTimer(2.0, Point_Hurt, data, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	
	float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	
	DataPack cloud = new DataPack();
	cloud.WriteCell(client);
	cloud.WriteFloat(pos[0]);
	cloud.WriteFloat(pos[1]);
	cloud.WriteFloat(pos[2]);
	cloud.WriteFloat(targettime);

	CreateSmoke(client);
}

public Action Point_Hurt(Handle timer, DataPack hurt)
{
	hurt.Reset();
	int client = hurt.ReadCell();
	float g_pos[3];
	g_pos[0] = hurt.ReadFloat();
	g_pos[1] = hurt.ReadFloat();
	g_pos[2] = hurt.ReadFloat();
	float targettime = hurt.ReadFloat();
	
	if (targettime - GetEngineTime() < 0)
	{
		hurt.Close();
		return Plugin_Stop;
	}
	
	if (!IsClientInGame(client)) client = -1;
	
	float targetVector[3];
	float distance;
	
	for (int target = 1; target <= MaxClients; target++)
	{
		if (!target || !IsClientInGame(target) || !IsPlayerAlive(target) || GetClientTeam(target) != 2)
			continue;
		
		GetClientEyePosition(target, targetVector);
		distance = GetVectorDistance(targetVector, g_pos);
		
		if (distance > 300.0 || !IsVisibleTo(g_pos, targetVector))
			continue;

		EmitSoundToClient(target, "player/survivor/voice/choke_5.wav");
		
		int SmokeDMG = GetConVarInt(g_Cvar_AdmiralSmokeDamage);
		int CurrentHp = GetClientHealth(target);
		if (CurrentHp > SmokeDMG) SetEntPropEx(target, Prop_Send, "m_iHealth", CurrentHp - SmokeDMG, 1);
		else 
		{
			SetEntityHealth(target, 1);
			SDKHooks_TakeDamage(target, target, target, 100.0, DMG_GENERIC);
		}
		
		ScreenFade(target, 16, 122, 0, 100, RoundToZero(1 * 1000.0), 1);
		
		Handle hBf = StartMessageOne("Shake", target);
		BfWriteByte(hBf, 0);
		BfWriteFloat(hBf,6.0);
		BfWriteFloat(hBf,1.0);
		BfWriteFloat(hBf,1.0);
		EndMessage();
		CreateTimer(1.0, StopShake, target, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

void ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0) BfWriteShort(msg, (0x0002 | 0x0008));
	else BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

public Action StopShake(Handle timer, any target)
{
	if (!target || !IsClientInGame(target))
		return Plugin_Handled;
	
	Handle hBf = StartMessageOne("Shake", target);
	BfWriteByte(hBf, 0);
	BfWriteFloat(hBf, 0.0);
	BfWriteFloat(hBf, 0.0);
	BfWriteFloat(hBf, 0.0);
	EndMessage();
	
	return Plugin_Handled;
}

bool IsVisibleTo(float position[3], float targetposition[3])
{
	float vAngles[3];
	float vLookAt[3];
	static const float TRACE_TOLERANCE = 25.0;
	
	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	Handle trace = TR_TraceRayFilterEx(position, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter);
	
	bool isVisible = false;
	if (TR_DidHit(trace))
	{
		float vStart[3];
		TR_GetEndPosition(vStart, trace);
		
		if ((GetVectorDistance(position, vStart, false) + TRACE_TOLERANCE) >= GetVectorDistance(position, targetposition)) isVisible = true;
	}
	else
	{
		LogError("Tracer Bug: Player-Zombie Trace did not hit anything, WTF");
		isVisible = true;
	}
	trace.Close();
	
	return isVisible;
}

public bool TraceFilter(int entity, int contentsMask)
{
	if (!entity || !IsValidEntity(entity)) return false;
	return true;
}

void CreateSmoke(int target)
{
	if (target > 0 && IsValidEdict(target) && IsClientInGame(target) && IsPlayerAlive(target))
	{
		int SmokeEnt = CreateEntityByName("env_smokestack");
		float location[3];
		GetClientAbsOrigin(target, location);
	
		char originData[64];
		Format(originData, sizeof(originData), "%f %f %f", location[0], location[1], location[2]);

		char SmokeColor[128];
		g_Cvar_AdmiralSmokeColors.GetString(SmokeColor, sizeof(SmokeColor));

		float delay = g_Cvar_AdmiralSmokeLength.FloatValue;
		
		if (SmokeEnt)
		{
			char SName[128];
			Format(SName, sizeof(SName), "Smoke%i", target);
			DispatchKeyValue(SmokeEnt, "targetname", SName);
			DispatchKeyValue(SmokeEnt, "Origin", originData);
			DispatchKeyValue(SmokeEnt, "BaseSpread", "100");
			DispatchKeyValue(SmokeEnt, "SpreadSpeed", "70");
			DispatchKeyValue(SmokeEnt, "Speed", "80");
			DispatchKeyValue(SmokeEnt, "StartSize", "200");
			DispatchKeyValue(SmokeEnt, "EndSize", "2");
			DispatchKeyValue(SmokeEnt, "Rate", "30");
			DispatchKeyValue(SmokeEnt, "JetLength", "400");
			DispatchKeyValue(SmokeEnt, "Twist", "20"); 
			DispatchKeyValue(SmokeEnt, "RenderColor", SmokeColor);
			DispatchKeyValue(SmokeEnt, "RenderAmt", "155");
			DispatchKeyValue(SmokeEnt, "SmokeMaterial", "particle/particle_smokegrenade1.vmt");
			
			DispatchSpawn(SmokeEnt);
			AcceptEntityInput(SmokeEnt, "TurnOn");

			DataPack pack;
			CreateDataTimer(delay, Timer_KillSmoke, pack);
			pack.WriteCell(SmokeEnt);

			float longerdelay = 5.0 + delay;
			DataPack pack2;
			CreateDataTimer(longerdelay, Timer_StopSmoke, pack2);
			pack2.WriteCell(SmokeEnt);
		}
	}
}

public Action Timer_KillSmoke(Handle timer, DataPack pack)
{	
	pack.Reset();
	int SmokeEnt = pack.ReadCell();
	StopSmokeEnt(SmokeEnt);
	return Plugin_Handled;
}

void StopSmokeEnt(int target)
{
	if (IsValidEntity(target)) AcceptEntityInput(target, "TurnOff");
}

public Action Timer_StopSmoke(Handle timer, DataPack pack)
{	
	pack.Reset();
	int SmokeEnt = pack.ReadCell();
	RemoveSmokeEnt(SmokeEnt);
	return Plugin_Handled;
}

void RemoveSmokeEnt(int target)
{
	if (IsValidEntity(target)) AcceptEntityInput(target, "Kill");
}

/* =============================================================================================================== *
 *												Create_TeamsManagerMenu			   								   *
 *================================================================================================================ */

void Create_TeamsManagerMenu(int client)
{
	Menu menu = new Menu(TeamsManagerMenuList, MENU_ACTIONS_ALL);
	menu.SetTitle("» Teams Manager Menu:");
	menu.AddItem("TEAMS", "Display Players");
	menu.AddItem("SPECTATOR", "Join Spectators");
	menu.AddItem("SURVIVOR", "Join Survivors");
	menu.AddItem("INFECTED", "Join Infected");
	menu.AddItem("TAKEOVER", "Takeover Bots");
	menu.AddItem("SWAP", "Swap Players");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int TeamsManagerMenuList(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			
			if (StrEqual(item, "TEAMS")) Create_ShowTeamsPanel(param1);
			else if (StrEqual(item, "SPECTATOR")) SwitchToSpectator(param1);
			else if (StrEqual(item, "SURVIVOR")) SwitchToSurvivors(param1);
			else if (StrEqual(item, "INFECTED")) SwitchToInfected(param1);
			else if (StrEqual(item, "TAKEOVER"))
			{
				int count = GetAliveSurvivorsBots();
				if (count > 0) Create_TakeOverMenu(param1);
				else PrintToChatAll("\x04[TakeOver] \x01There Are No Survivor Bots To Takeover", param1);
			}
			else if (StrEqual(item, "SWAP")) Create_SwapMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_AdmiralMenu(param1);
			}
    	}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *                     			Sub Menu: Create_ShowTeamsPanel > From Create_TeamsManagerMenu					   *
 *================================================================================================================ */

void Create_ShowTeamsPanel(int client)
{
	Panel panel = new Panel();
	
	static char sID [12];
	static char sName [MAX_NAME_LENGTH];
	
	panel.DrawItem("Spectator Team"); // Spectators Team Panel
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		else if (GetClientTeam(i) == 1)
		{
			GetClientName(i, sName, sizeof(sName));
			Format(sID, sizeof(sID), "%s", GetClientUserId(i));
			
			panel.DrawItem(sName, ITEMDRAW_RAWLINE);
		}
	}
	
	panel.DrawItem("Survivors Team"); // Survivors Team Panel
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		else if (GetClientTeam(i) == 2)
		{
			GetClientName(i, sName, sizeof(sName));
			Format(sID, sizeof(sID), "%s", GetClientUserId(i));
			panel.DrawItem(sName, ITEMDRAW_RAWLINE);
		}
	}
	
	panel.DrawItem("Infected Team"); // Infected Team Panel
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		else if (GetClientTeam(i) == 3)
		{
			GetClientName(i, sName, sizeof(sName));
			Format(sID, sizeof(sID), "%s", GetClientUserId(i));
			panel.DrawItem(sName, ITEMDRAW_RAWLINE);
		}
	}
	panel.Send(client, HandleShowTeamsPanel, MENU_TIME_FOREVER);
	delete panel;
}

int HandleShowTeamsPanel(Menu menu, MenuAction action, int client, int selectedIndex)
{
	switch(action) 
	{
		case MenuAction_End: 
		{
			delete menu;
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *                     		 		 		 Method To Change Teams												   *
 *================================================================================================================ */

Action SwitchToSpectator(int client)
{
	if (GetClientTeam(client) == 1)
		PrintToChat(client, "\x04[Teams] \x01You Are Already In The \x05Spectator Team", client);
	
	else
	{
		ChangeClientTeam(client, 1);
		PrintToChatAll("\x04[Teams] \x01Player \x03%N \x01has moved to the \x05Spectator Team", client);
	}
	return Plugin_Handled;
}

Action SwitchToSurvivors(int client)
{
	char GameMode[64];
	int iTotal = TotalTeamPlayers();
	int iSurvivors = HumanSurvivors();
	int iInfected = HumanInfected();
	FindConVar("mp_gamemode").GetString(GameMode, sizeof(GameMode));
	
	if (client == 0 || StrContains("versus", GameMode) != 0)
	{
		PrintToServer("Command cannot be used by server.");
		return Plugin_Handled;
	}
	
	else if (GetClientTeam(client) == 2)
	{
		PrintToChat(client, "\x04[Teams] \x01You Are Already In The \x05Survivor Team", client);
		return Plugin_Handled;
	}
	
	else if (iTotal - iSurvivors < 1)
	{
		PrintToChat(client, "\x04[Teams] \x01Survivor Team Is Currently \x03Full \x01Now.", client);
		return Plugin_Handled;
	}
	
	else if (iSurvivors >= iInfected && GetClientTeam(client) != 1 || iSurvivors > iInfected && GetClientTeam(client) == 1)
	{
		PrintToChat(client, "\x04[Teams] \x01Changing Teams Will Make The Game Unbalanced");
		return Plugin_Handled;
	}
	
	else
	{
		SetConVarInt(FindConVar("vs_max_team_switches"), 999);
		ClientCommand(client, "jointeam 2");
		PrintToChatAll("\x04[Teams] \x01Player \x03%N \x01has joined the \x05Survivor Team", client);
		CreateTimer(0.5, Timer_LockTeamChooseMenu, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}
}

Action SwitchToInfected(int client)
{
	char GameMode[64];
	int iTotal = TotalTeamPlayers();
	int iSurvivors = HumanSurvivors();
	int iInfected = HumanInfected();
	FindConVar("mp_gamemode").GetString(GameMode, sizeof(GameMode));
	
	if (client == 0 || StrContains("versus", GameMode) != 0)
	{
		PrintToServer("Command cannot be used by server.");
		return Plugin_Handled;
	}
	
	else if (GetClientTeam(client) == 3)
	{
		PrintToChat(client, "\x04[Teams] \x01You Are Already In The \x05Survivor Team", client);
		return Plugin_Handled;
	}
	
	else if (iTotal - iSurvivors < 1)
	{
		PrintToChat(client, "\x04[Teams] \x01Infected Team Is Currently \x03Full \x01Now.", client);
		return Plugin_Handled;
	}
	
	else if (iInfected >= iSurvivors && GetClientTeam(client) != 1 || iInfected > iSurvivors && GetClientTeam(client) == 1)
	{
		PrintToChat(client, "\x04[Teams] \x01Changing Teams Will Make The Game Unbalanced");
		return Plugin_Handled;
	}
	
	else
	{
		SetConVarInt(FindConVar("vs_max_team_switches"), 999);
		ClientCommand(client, "jointeam 3");
		PrintToChatAll("\x04[Teams] \x01Player \x03%N \x01has joined the \x05Infected Team", client);
		CreateTimer(0.5, Timer_LockTeamChooseMenu, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}
}

/* =============================================================================================================== *
 *                     			Sub Menu: Create_TakeOverMenu > From Create_TeamsManagerMenu					   *
 *================================================================================================================ */

void Create_TakeOverMenu(int client)
{
	Menu menu = new Menu(AvailableBotsList, MENU_ACTIONS_ALL);
	menu.SetTitle("» Select A Bot:");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsFakeClient(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
			continue;
		
		static char sID [12];
		static char sName [MAX_NAME_LENGTH];
		GetClientName(i, sName, sizeof(sName));
		
		static char BotInfo[100];
		static char BotStatus[32];
		
		if (IsClientIncapped(i) && !g_bClientIsHoldByInfected[i]) Format(BotStatus, sizeof(BotStatus), "Incapped");
		else if (IsClientHanging(i)) Format(BotStatus, sizeof(BotStatus), "Hanging");
		else if (g_bClientIsHoldByInfected[i]) Format(BotStatus, sizeof(BotStatus), "Hold By Infected");
		else Format(BotStatus, sizeof(BotStatus), "Standing");
		
		Format(sID, sizeof(sID), "%i", GetClientUserId(i));
		Format(BotInfo, sizeof(BotInfo), "%s ( %i HP ) ( %s )", sName, GetEntProp(i, Prop_Send, "m_iHealth"), BotStatus);
		
		menu.AddItem(sID, BotInfo);
		menu.ExitBackButton = true;
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

int AvailableBotsList(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			
			if (menu.GetItem(param2, info, sizeof(info)))
			{
				int TargetBot = GetClientOfUserId(StringToInt(info));
				
				if (!IsClientInGame(TargetBot) || !IsFakeClient(TargetBot) || !IsPlayerAlive(TargetBot) || GetClientTeam(TargetBot) != 2)
					return 0;
				
				//TakeOver Simple Method - ByPassing Admin Cheats				
				int CmdFlags = GetCommandFlags("sb_takecontrol");
				SetCommandFlags("sb_takecontrol", CmdFlags & ~FCVAR_CHEAT);
				FakeClientCommand(param1, "sb_takecontrol %N", TargetBot);
				SetCommandFlags("sb_takecontrol", CmdFlags);
				PrintToChatAll("\x04[TakeOver] \x01Player \x03%N \x01has took over \x03%N\x01.", param1, TargetBot);
			}
    	}
    	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_TeamsManagerMenu(param1);
			}
    	}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *										Change TakeOver Status To: Hold By Infected 							   *
 *================================================================================================================ */
 
void Event_HoldByInfected(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!victim || !IsClientInGame(victim) || GetClientTeam(victim) != 2 || !IsPlayerAlive(victim) || !IsFakeClient(victim)) return;
	
	g_bClientIsHoldByInfected[victim] = true;
}

void Event_ReleasedFromInfected(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!victim || !IsClientInGame(victim) || GetClientTeam(victim) != 2 || !IsPlayerAlive(victim) || !IsFakeClient(victim)) return;
	
	g_bClientIsHoldByInfected[victim] = false;
}

/* =============================================================================================================== *
 *                     				Sub Menu: Create_SwapMenu > From Create_TeamsManagerMenu					   *
 *================================================================================================================ */

void Create_SwapMenu(int client)
{
	Menu menu = new Menu(PlayersList, MENU_ACTIONS_ALL);
	menu.SetTitle("» Select A Player:");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		static char sID [12];
		static char sName [MAX_NAME_LENGTH];
		
		GetClientName(i, sName, sizeof(sName));
		
		Format(sID, sizeof(sID), "%i", GetClientUserId(i));
		menu.AddItem(sID, sName);
		menu.ExitBackButton = true;
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

int PlayersList(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			
			if (menu.GetItem(param2, info, sizeof(info)))
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			{
				int Target = GetClientOfUserId(StringToInt(info));
				
				if (!IsClientInGame(Target) || IsFakeClient(Target))
					return 0; //Double Check
					
				StartSwappingThePlayer(Target);
			}
    	}
    	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_TeamsManagerMenu(param1);
			}
    	}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Swap Method													   *
 *================================================================================================================ */

Action StartSwappingThePlayer(int client)
{
	SetConVarInt(FindConVar("vs_max_team_switches"), 999);
	CreateTimer(1.0, Timer_LockTeamChooseMenu, _, TIMER_FLAG_NO_MAPCHANGE);
	
	if (GetClientTeam(client) == 2)
	{
		ClientCommand(client, "jointeam 3");
		PrintToChatAll("\x04[SM] \x01Player \x03%N \x01Swapped To \x05Infected Team", client);
	}
	else if (GetClientTeam(client) == 3)
	{
		ClientCommand(client, "jointeam 2");
		PrintToChatAll("\x04[SM] \x01Player \x03%N \x01Swapped To \x05Survivors Team", client);
	}
	else PrintToChatAll("\x04[SM] \x01Player \x03%N \x01Is Currently \x05AFK", client);
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *														Create_VoteMenu 										   *
 *================================================================================================================ */

void Create_VoteMenu(int client)
{
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
	Menu menu = new Menu(Handle_VoteMenuList, MENU_ACTIONS_ALL);
	menu.SetTitle("» Vote Menu Selection:");
	menu.AddItem("MAP", "Vote Map");
	menu.AddItem("RESTART", "Vote Restart");
	menu.AddItem("SHUFFLE", "Vote Shuffle");
	menu.AddItem("SLAY", "Vote Slay");
	menu.AddItem("KICK", "Vote Kick");
	menu.AddItem("BAN", "Vote Ban");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_VoteMenuList(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			if (StrEqual(item, "MAP")) SelectMap_ToVoteChange(param1);
			else if (StrEqual(item, "RESTART")) Confirm_ToVoteRestart(param1);
			else if (StrEqual(item, "SHUFFLE")) Confirm_ToVoteShuffling(param1);
			else if (StrEqual(item, "SLAY")) SelectPlayer_ToVoteSlay(param1);
			else if (StrEqual(item, "KICK")) SelectPlayer_ToVoteKick(param1);
			else if (StrEqual(item, "BAN")) SelectPlayer_ToVoteBan(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_AdmiralMenu(param1);
			}
    	}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Start Vote Map 											   *
 *================================================================================================================ */

void SelectMap_ToVoteChange(int client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "\x04[Vote System] \x01A vote is already in progress...");
		return;
	}
	if (!TestVoteDelay(client))
	{
		return;
	}
	Create_VoteMapMenu(client);
	return;
}

void Create_VoteMapMenu(int client)
{
	Menu menu = new Menu(Handle_MapVoteList, MENU_ACTIONS_ALL);
	menu.SetTitle("» Choose A Campaign:");
	menu.AddItem("c1m1_hotel", "Dead Center");
	menu.AddItem("c2m1_highway", "Dark Carnival");
	menu.AddItem("c3m1_plankcountry", "Swamp Fever");
	menu.AddItem("c4m1_milltown_a", "Hard Rain");
	menu.AddItem("c5m1_waterfront", "The Parish");
	menu.AddItem("c6m1_riverbank", "The Passing");
	menu.AddItem("c7m1_docks", "The Sacrifice");
	menu.AddItem("c8m1_apartment", "No Mercy");
	menu.AddItem("c9m1_alleys", "Crash Course");
	menu.AddItem("c10m1_caves", "Death Toll");
	menu.AddItem("c11m1_greenhouse", "Dead Air");
	menu.AddItem("c12m1_hilltop", "Blood Harvest");
	menu.AddItem("c13m1_alpinecreek", "Cold Stream");
	menu.AddItem("c14m1_junkyard", "The Last Stand");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_MapVoteList(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!IsVoteAllowed(param1)) return 0;
			
			char camp[128];
			char campaignname[128];
			GetMenuItem(menu, param2, camp, sizeof(camp), _,campaignname, sizeof(campaignname));
			DoVoteMapMenu(camp, campaignname);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_VoteMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

void DoVoteMapMenu(const char[] camp, const char[] campaignname)
{
	PrintToChatAll("\x04[Vote System] \x01Vote map was initiated on: \x05%s", campaignname);
	
	g_hVoteMenu = new Menu(Handler_VoteMapAnswer, MENU_ACTIONS_ALL);
	if (strcmp(camp, "map"))
	{
		g_hVoteMenu.SetTitle("Change Map To: %s?", campaignname);
		g_hVoteMenu.AddItem(camp, "Yes");
		g_hVoteMenu.AddItem(VOTE_NO, "No");
		g_hVoteMenu.ExitButton = false;
		g_hVoteMenu.DisplayVoteToAll(20);
	}	
}

int Handler_VoteMapAnswer(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete g_hVoteMenu;
	}
	else if (action == MenuAction_DisplayItem)
	{
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			char buffer[255];
			Format(buffer, sizeof(buffer), display, param1);

			return RedrawMenuItem(buffer);
		}
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("\x04[Vote System] \x01No votes were cast.");
	}
	else if (action == MenuAction_VoteEnd)
	{
		char camp[PLATFORM_MAX_PATH], display[64];
		float percent, limit;
		int votes, totalVotes;
		
		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, camp, sizeof(camp), _, display, sizeof(display));
		
		if (strcmp(camp, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = float(votes) / float(totalVotes);
		limit = g_Cvar_AdmiralVotePercent.FloatValue;
		
		if ((strcmp(camp, VOTE_YES) == 0 && FloatCompare(percent, limit) < 0 && param1 == 0) || (strcmp(camp, VOTE_NO) == 0 && param1 == 1))
		{
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("\x04[Vote System] \x01Vote failed. \x05%d%% \x01vote required. (Received \x05%d%% \x01of \x05%d \x01votes)", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		} 
		else
		{
			PrintToChatAll("\x04[Vote System] \x01Vote successful. (Received \x05%d%% \x01of \x05%d votes)", RoundToNearest(100.0*percent), totalVotes);
			PrintToChatAll("\x04[Vote System] \x01Changing map to \x05%s", camp);
			
			if (strcmp(camp, "map"))
			{
				g_iNextMapTime = 10;
				CreateTimer(1.0, Timer_MapChangeCountdown, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);  
				Handle pack;
				CreateDataTimer(10.0, Timer_ChangeMap, pack);
				WritePackString(pack, camp);
			}
		}
	}
	return 0;
}

Action Timer_MapChangeCountdown(Handle timer)
{
	if (g_iNextMapTime <= 0) return Plugin_Stop;
	
	g_iNextMapTime--;
	PrintHintTextToAll("Changing Map: %d", g_iNextMapTime);
	return Plugin_Continue;
}

Action Timer_ChangeMap(Handle timer, Handle pack)
{
	char camp[65];
	
	ResetPack(pack);
	ReadPackString(pack, camp, sizeof(camp));
	
	ServerCommand("changelevel %s", camp);
	
	return Plugin_Stop;
}

/* =============================================================================================================== *
 *													Start Vote Restart 											   *
 *================================================================================================================ */

void Confirm_ToVoteRestart(int client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "\x04[Vote System] \x01A vote is already in progress...");
		return;
	}
	
	if (!TestVoteDelay(client))
	{
		return;
	}
	
	Create_ConfirmVoteRestart(client);
	return;
}

void Create_ConfirmVoteRestart(int client)
{
	Menu menu = new Menu(Handle_Restart, MENU_ACTIONS_ALL);
	menu.SetTitle("» Are You Sure:");
	menu.AddItem("YES", "Yes");
	menu.AddItem("NO", "No");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_Restart(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!IsVoteAllowed(param1)) return 0;
			
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			
			if (StrEqual(item, "YES")) DisplayVoteToRestartRound(param1);
			else if (StrEqual(item, "NO")) Create_VoteMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_VoteMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

void DisplayVoteToRestartRound(int client)
{
	PrintToChatAll("\x04[Vote System] \x01Vote restart was initiated by: \x05%N", client);

	g_hVoteMenu = new Menu(Handler_VoteRestartAnswer, MENU_ACTIONS_ALL);
	g_hVoteMenu.SetTitle("Do You Want To Vote Round Restart?");
	g_hVoteMenu.AddItem(VOTE_YES, "Yes");
	g_hVoteMenu.AddItem(VOTE_NO, "No");
	g_hVoteMenu.ExitButton = false;
	g_hVoteMenu.DisplayVoteToAll(20);
}

int Handler_VoteRestartAnswer(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete g_hVoteMenu;
	}
	else if (action == MenuAction_DisplayItem)
	{
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			char buffer[255];
			Format(buffer, sizeof(buffer), display, param1);

			return RedrawMenuItem(buffer);
		}
	}

	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("\x04[Vote System] \x01No votes were cast.");
	}
	else if (action == MenuAction_VoteEnd)
	{
		char camp[PLATFORM_MAX_PATH], display[64];
		float percent, limit;
		int votes, totalVotes;
		
		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, camp, sizeof(camp), _, display, sizeof(display));
		
		if (strcmp(camp, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = float(votes) / float(totalVotes);
		limit = g_Cvar_AdmiralVotePercent.FloatValue;
		
		if ((strcmp(camp, VOTE_YES) == 0 && FloatCompare(percent, limit) < 0 && param1 == 0) || (strcmp(camp, VOTE_NO) == 0 && param1 == 1))
		{
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("\x04[Vote System] \x01Vote failed. \x05%d%% \x01vote required. (Received \x05%d%% \x01of \x05%d \x01votes)", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		} 
		else
		{
			PrintToChatAll("\x04[Vote System] \x01Vote successful. (Received \x05%d%% \x01of \x05%d votes)", RoundToNearest(100.0*percent), totalVotes);
			PrintToChatAll("\x04[Restart] \x01Round Is Getting \x03Restarted\x01.");
			
			SetConVarInt(FindConVar("mp_restartgame"), 1);
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Start Vote Shuffle 											   *
 *================================================================================================================ */

void Confirm_ToVoteShuffling(int client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "\x04[Vote System] \x01A vote is already in progress...");
		return;
	}
	
	if (!TestVoteDelay(client))
	{
		return;
	}
	
	Create_ConfirmVoteShuffle(client);
	return;
}

void Create_ConfirmVoteShuffle(int client)
{
	Menu menu = new Menu(Handle_Shuffling, MENU_ACTIONS_ALL);
	menu.SetTitle("» Are You Sure:");
	menu.AddItem("YES", "Yes");
	menu.AddItem("NO", "No");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_Shuffling(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!IsVoteAllowed(param1)) return 0;
			
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			
			if (StrEqual(item, "YES")) DisplayVoteToShuffleTeamsToAll(param1);
			else if (StrEqual(item, "NO")) Create_VoteMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_VoteMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

void DisplayVoteToShuffleTeamsToAll(int client)
{
	PrintToChatAll("\x04[Vote System] \x01Vote shuffle was initiated by: \x05%N", client);

	g_hVoteMenu = new Menu(Handler_VoteShuffleAnswer, MENU_ACTIONS_ALL);
	g_hVoteMenu.SetTitle("Do You Want To Vote Shuffle?");
	g_hVoteMenu.AddItem(VOTE_YES, "Yes");
	g_hVoteMenu.AddItem(VOTE_NO, "No");
	g_hVoteMenu.ExitButton = false;
	g_hVoteMenu.DisplayVoteToAll(20);
}

int Handler_VoteShuffleAnswer(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete g_hVoteMenu;
	}
	else if (action == MenuAction_DisplayItem)
	{
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			char buffer[255];
			Format(buffer, sizeof(buffer), display, param1);

			return RedrawMenuItem(buffer);
		}
	}

	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("\x04[Vote System] \x01No votes were cast.");
	}
	else if (action == MenuAction_VoteEnd)
	{
		char camp[PLATFORM_MAX_PATH], display[64];
		float percent, limit;
		int votes, totalVotes;
		
		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, camp, sizeof(camp), _, display, sizeof(display));
		
		if (strcmp(camp, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = float(votes) / float(totalVotes);
		limit = g_Cvar_AdmiralVotePercent.FloatValue;
		
		if ((strcmp(camp, VOTE_YES) == 0 && FloatCompare(percent, limit) < 0 && param1 == 0) || (strcmp(camp, VOTE_NO) == 0 && param1 == 1))
		{
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("\x04[Vote System] \x01Vote failed. \x05%d%% \x01vote required. (Received \x05%d%% \x01of \x05%d \x01votes)", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		} 
		else
		{
			PrintToChatAll("\x04[Vote System] \x01Vote successful. (Received \x05%d%% \x01of \x05%d votes)", RoundToNearest(100.0*percent), totalVotes);
			PrintToChatAll("\x04[Shuffle] \x01Teams Are Getting \x03Shuffled\x01.");
			
			StartShufflingTeams();
		}
	}
	return 0;
}

void StartShufflingTeams()
{
	char GameMode[64];
	int iTotal = TotalTeamPlayers();
	int iSurvivors = HumanSurvivors();
	int iInfected = HumanInfected();
	
	FindConVar("mp_gamemode").GetString(GameMode, sizeof(GameMode));
	SetConVarInt(FindConVar("vs_max_team_switches"), 999);
	CreateTimer(0.5, Timer_LockTeamChooseMenu, _, TIMER_FLAG_NO_MAPCHANGE);
	
	if (StrContains("versus", GameMode) != 0)
	{
		PrintToServer("Command cannot be used by server.");
		PrintToChatAll("\x04[Shuffle] \x01Teams Shuffle \x03Failed \x01Due To Incompatible Modes.");
		return;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != 1)
		{
			ChangeClientTeam(i, 1);
			
			int shuffle = GetRandomInt(1, 2);
			switch (shuffle)
			{
				case 1:
				{
					if (iTotal - iSurvivors < 1 && iInfected >= iSurvivors)
						ClientCommand(i, "jointeam 2");
					else ClientCommand(i, "jointeam 3");
				}
				case 2:
				{
					if (iTotal - iSurvivors < 1 && iSurvivors >= iInfected)
						ClientCommand(i, "jointeam 3");
					else ClientCommand(i, "jointeam 2");
				}
			}
		}
	}
	return;
}

/* =============================================================================================================== *
 *													Start Vote Slay 											   *
 *================================================================================================================ */

void SelectPlayer_ToVoteSlay(int client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "\x04[Vote System] \x01A vote is already in progress...");
		return;
	}
	
	if (!TestVoteDelay(client))
	{
		return;
	}
	else
	{
		Menu menu = new Menu(Handle_VoteSlayPlayerSelection, MENU_ACTIONS_ALL);
		
		char buffer[128];
		char clientname[255];
		
		Format(buffer, sizeof(buffer), "» Start Vote Slay:", LANG_SERVER);		
		menu.SetTitle(buffer);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
				Format(clientname, sizeof(clientname), "%N", i);
				char sUserID[10];
				int UserID = GetClientUserId(i);
				IntToString(UserID, sUserID, sizeof(sUserID));
				menu.AddItem(sUserID, clientname);
			}
		}
		menu.ExitBackButton = true;
		menu.Display(client, 20);
	}
	return;
}

int Handle_VoteSlayPlayerSelection(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (!IsVoteAllowed(param1)) return 0;
			
			char menu_item_title[50];
			menu.GetItem(param2, menu_item_title, sizeof(menu_item_title));
			int UserID = StringToInt(menu_item_title);
			int client = GetClientOfUserId(UserID);
			
			if(client == 0) return 0;
			if (IsClientGenericAdmin(client))
			{
				PrintToChat(param1, "\x04[Vote System] \x01You are not allowed to vote against \x05%N", client);
				return 0;
			}
			else DisplayVoteSlayChooseAnswerMenuToAll(param1, client);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_VoteMenu(param1);
			}
    	}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

void DisplayVoteSlayChooseAnswerMenuToAll(int client, int target)
{
	g_iVotesTarget = GetClientUserId(target);

	GetClientName(target, g_VoteInfo[VOTE_NAME], sizeof(g_VoteInfo[]));
	GetClientAuthId(target, AuthId_Steam2, g_VoteInfo[VOTE_AUTHID], sizeof(g_VoteInfo[]));
	GetClientIP(target, g_VoteInfo[VOTE_IP], sizeof(g_VoteInfo[]));

	LogAction(client, target, "\"%L\" initiated a slay vote against \"%L\"", client, target);
	PrintToChatAll("\x04[Vote System] \x01Vote slay was initiated on: \x05%N", target);

	g_hVoteMenu = new Menu(Handler_VoteSlayAnswer, MENU_ACTIONS_ALL);
	g_hVoteMenu.SetTitle("Vote Slay %N?", target);
	g_hVoteMenu.AddItem(VOTE_YES, "Yes");
	g_hVoteMenu.AddItem(VOTE_NO, "No");
	g_hVoteMenu.ExitButton = false;
	g_hVoteMenu.DisplayVoteToAll(20);
}

int Handler_VoteSlayAnswer(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete g_hVoteMenu;
	}
	else if (action == MenuAction_DisplayItem)
	{
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			char buffer[255];
			Format(buffer, sizeof(buffer), display, param1);

			return RedrawMenuItem(buffer);
		}
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("\x04[Vote System] \x01No votes were cast.");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		char item[PLATFORM_MAX_PATH], display[64];
		float percent, limit;
		int votes, totalVotes;
		
		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = float(votes) / float(totalVotes);
		limit = g_Cvar_AdmiralVotePercent.FloatValue;
		
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent, limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("\x04[Vote System] \x01Vote failed. \x05%d%% \x01vote required. (Received \x05%d%% \x01of \x05%d \x01votes)", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			PrintToChatAll("\x04[Vote System] \x01Vote successful. (Received \x05%d%% \x01of \x05%d \x01votes)", RoundToNearest(100.0*percent), totalVotes);
			
			PrintToChatAll("\x04[Vote System] \x01Slayed player \x05\"%s\"", g_VoteInfo[VOTE_NAME]);
			
			int voteTarget;
			if((voteTarget = GetClientOfUserId(g_iVotesTarget)) == 0)
			{
				LogAction(-1, -1, "Vote slay successful, slayed \"%s\" (%s)", g_VoteInfo[VOTE_NAME], g_VoteInfo[VOTE_AUTHID]);
			}
			else
			{
				LogAction(-1, voteTarget, "Vote slay successful, slayed \"%L\"", voteTarget);
				ForcePlayerSuicide(voteTarget);
			}
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Start Vote Kick 											   *
 *================================================================================================================ */

void SelectPlayer_ToVoteKick(int client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "\x04[Vote System] \x01A vote is already in progress...");
		return;
	}
	
	if (!TestVoteDelay(client))
	{
		return;
	}
	else
	{
		Menu menu = new Menu(Handle_VoteKickPlayerSelection, MENU_ACTIONS_ALL);
		
		char buffer[128];
		char clientname[255];
		
		Format(buffer, sizeof(buffer), "» Start Vote Kick:", LANG_SERVER);		
		menu.SetTitle(buffer);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
				Format(clientname, sizeof(clientname), "%N", i);
				char sUserID[10];
				int UserID = GetClientUserId(i);
				IntToString(UserID, sUserID, sizeof(sUserID));
				menu.AddItem(sUserID, clientname);
			}
		}
		menu.ExitBackButton = true;
		menu.Display(client, 20);
	}
	return;
}

int Handle_VoteKickPlayerSelection(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (!IsVoteAllowed(param1)) return 0;
			
			char menu_item_title[50];
			menu.GetItem(param2, menu_item_title, sizeof(menu_item_title));
			int UserID = StringToInt(menu_item_title);
			int client = GetClientOfUserId(UserID);
			
			if(client == 0) return 0;
			if (IsClientGenericAdmin(client))
			{
				PrintToChat(param1, "\x04[Vote System] \x01You are not allowed to vote against \x05%N", client);
				return 0;
			}
			else DisplayVoteKickChooseAnswerMenuToAll(param1, client);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_VoteMenu(param1);
			}
    	}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

void DisplayVoteKickChooseAnswerMenuToAll(int client, int target)
{
	g_iVotesTarget = GetClientUserId(target);

	GetClientName(target, g_VoteInfo[VOTE_NAME], sizeof(g_VoteInfo[]));
	GetClientAuthId(target, AuthId_Steam2, g_VoteInfo[VOTE_AUTHID], sizeof(g_VoteInfo[]));
	GetClientIP(target, g_VoteInfo[VOTE_IP], sizeof(g_VoteInfo[]));

	LogAction(client, target, "\"%L\" initiated a kick vote against \"%L\"", client, target);
	PrintToChatAll("\x04[Vote System] \x01Vote kick was initiated on: \x05%N", target);

	g_hVoteMenu = new Menu(Handler_VoteKickAnswer, MENU_ACTIONS_ALL);
	g_hVoteMenu.SetTitle("Vote Kick %N?", target);
	g_hVoteMenu.AddItem(VOTE_YES, "Yes");
	g_hVoteMenu.AddItem(VOTE_NO, "No");
	g_hVoteMenu.ExitButton = false;
	g_hVoteMenu.DisplayVoteToAll(20);
}

int Handler_VoteKickAnswer(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete g_hVoteMenu;
	}
	else if (action == MenuAction_DisplayItem)
	{
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			char buffer[255];
			Format(buffer, sizeof(buffer), display, param1);

			return RedrawMenuItem(buffer);
		}
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("\x04[Vote System] \x01No votes were cast.");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		char item[PLATFORM_MAX_PATH], display[64];
		float percent, limit;
		int votes, totalVotes;
		
		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = float(votes) / float(totalVotes);
		limit = g_Cvar_AdmiralVotePercent.FloatValue;
		
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent, limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("\x04[Vote System] \x01Vote failed. \x05%d%% \x01vote required. (Received \x05%d%% \x01of \x05%d \x01votes)", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			PrintToChatAll("\x04[Vote System] \x01Vote successful. (Received \x05%d%% \x01of \x05%d \x01votes)", RoundToNearest(100.0*percent), totalVotes);
			
			PrintToChatAll("\x04[Vote System] \x01Kicked Player \x05\"%s\"", g_VoteInfo[VOTE_NAME]);
			
			int voteTarget;
			if((voteTarget = GetClientOfUserId(g_iVotesTarget)) == 0)
			{
				LogAction(-1, -1, "Vote kick successful, kicked \"%s\" (%s)", g_VoteInfo[VOTE_NAME], g_VoteInfo[VOTE_AUTHID]);
			}
			else
			{
				LogAction(-1, voteTarget, "Vote kick successful, kicked \"%L\"", voteTarget);
				KickClient(voteTarget, "You Were Kicked By Votes", "sm_admiral");
			}
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Start Vote Ban 											   *
 *================================================================================================================ */

void SelectPlayer_ToVoteBan(int client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "\x04[Vote System] \x01A vote is already in progress...");
		return;
	}

	if (!TestVoteDelay(client))
		return;
	
	else
	{
		Menu menu = new Menu(Handle_VoteBanPlayerSelection, MENU_ACTIONS_ALL);
		
		char buffer[128];
		char clientname[255];
		
		Format(buffer, sizeof(buffer), "» Start Vote Ban:", LANG_SERVER);		
		menu.SetTitle(buffer);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
				Format(clientname, sizeof(clientname), "%N", i);
				char sUserID[10];
				int UserID = GetClientUserId(i);
				IntToString(UserID, sUserID, sizeof(sUserID));
				menu.AddItem(sUserID, clientname);
			}
		}
		menu.ExitBackButton = true;
		menu.Display(client, 20);
	}
	return;
}

int Handle_VoteBanPlayerSelection(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (!IsVoteAllowed(param1)) return 0;
			
			char menu_item_title[50];
			menu.GetItem(param2, menu_item_title, sizeof(menu_item_title));
			int UserID = StringToInt(menu_item_title);
			int client = GetClientOfUserId(UserID);
			
			if(client == 0) return 0;
			if (IsClientGenericAdmin(client))
			{
				PrintToChat(param1, "\x04[Vote System] \x01You are not allowed to vote against \x05%N", client);
				return 0;
			}
			else DisplayVoteBanChooseAnswerMenuToAll(param1, client);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_VoteMenu(param1);
			}
    	}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

void DisplayVoteBanChooseAnswerMenuToAll(int client, int target)
{
	g_iVotesTarget = GetClientUserId(target);

	GetClientName(target, g_VoteInfo[VOTE_NAME], sizeof(g_VoteInfo[]));
	GetClientAuthId(target, AuthId_Steam2, g_VoteInfo[VOTE_AUTHID], sizeof(g_VoteInfo[]));
	GetClientIP(target, g_VoteInfo[VOTE_IP], sizeof(g_VoteInfo[]));

	LogAction(client, target, "\"%L\" initiated a ban vote against \"%L\"", client, target);
	PrintToChatAll("\x04[Vote System] \x01Vote ban was initiated on: \x05%N", target);

	g_hVoteMenu = new Menu(Handler_VoteBanAnswer, MENU_ACTIONS_ALL);
	g_hVoteMenu.SetTitle("Vote Ban %N?", target);
	g_hVoteMenu.AddItem(VOTE_YES, "Yes");
	g_hVoteMenu.AddItem(VOTE_NO, "No");
	g_hVoteMenu.ExitButton = false;
	g_hVoteMenu.DisplayVoteToAll(20);
}

int Handler_VoteBanAnswer(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete g_hVoteMenu;
	}
	else if (action == MenuAction_DisplayItem)
	{
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			char buffer[255];
			Format(buffer, sizeof(buffer), display, param1);

			return RedrawMenuItem(buffer);
		}
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("\x04[Vote System] \x01No votes were cast.");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		char item[PLATFORM_MAX_PATH], display[64];
		float percent, limit;
		int votes, totalVotes;
		
		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes;
		}
		
		percent = float(votes) / float(totalVotes);
		limit = g_Cvar_AdmiralVotePercent.FloatValue;
		
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent, limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("\x04[Vote System] \x01Vote failed. \x05%d%% \x01vote required. (Received \x05%d%% \x01of \x05%d \x01votes)", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			PrintToChatAll("\x04[Vote System] \x01Vote successful. (Received \x05%d%% \x01of \x05%d \x01votes)", RoundToNearest(100.0*percent), totalVotes);
			
			int minutes = g_Cvar_AdmiralVotebanTime.IntValue;
			
			PrintToChatAll("\x04[Vote System] \x01Banned player \x05\"%s\" \x01for \x05%d minutes\x01.", g_VoteInfo[VOTE_NAME], minutes);
			
			int voteTarget;
			if((voteTarget = GetClientOfUserId(g_iVotesTarget)) == 0)
			{
				LogAction(-1, -1, "Vote ban successful, banned \"%s\" (%s) (minutes \"%d\")", g_VoteInfo[VOTE_NAME], g_VoteInfo[VOTE_AUTHID], minutes);
				
				BanIdentity(g_VoteInfo[VOTE_AUTHID], minutes, BANFLAG_AUTHID, "sm_voteban");
			}
			else
			{
				LogAction(-1, voteTarget, "Vote ban successful, banned \"%L\" (minutes \"%d\")", voteTarget, minutes);
				BanClient(voteTarget, minutes, BANFLAG_AUTO, "Admiral Vote Ban", "You Were Banned By Votes");
			}
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *											Test Vote Delay For Vote Menu 										   *
 *================================================================================================================ */

bool TestVoteDelay(int client)
{
	if (CheckCommandAccess(client, "sm_vote_delay_bypass", ADMFLAG_CONVARS, true))
		return true;
	
 	int delay = CheckVoteDelay();
	
 	if (delay > 0)
 	{
 		if (delay > 60) ReplyToCommand(client, "[SM] Vote Delay Minutes", (delay / 60));
 		else ReplyToCommand(client, "[SM] Vote Delay Seconds", delay);
 		return false;
 	}
	return true;
}

/* =============================================================================================================== *
 *													Create_SettingsMenu 										   *
 *================================================================================================================ */

void Create_SettingsMenu(int client)
{
	Admiral admiral;
	bool IsAdmiral;
	IsAdmiral = GetAdmiralInfo(client, admiral);
	
	char str[64];
	FormatEx(str, sizeof(str), "STATE: %s", IsAdmiral ? "Admiral" : "None");
	StrCat(str, sizeof(str), IsClientGenericAdmin(client) ? " (Admin)" : " (User)");
	
	char item[64];
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
	Menu menu = new Menu(Handle_SettingsMenu);
	if(admiral.TimeDuration == TIME_FOREVER) menu.SetTitle("» NAME: %N \n» %s \n» %s \n» Time: Permanent", client, SteamID, str);
	else menu.SetTitle("» NAME: %N \n» %s \n» %s \n» TIME: %d hr %d min %d sec", client, SteamID, str, admiral.TimeLeft / 3600, admiral.TimeLeft / 60 % 60, admiral.TimeLeft % 60);
	
	Format(item, sizeof(item), "Auto Laser: %s", g_bAutoActivePrimaryLaser[client] ? "Yes" : "No");
	menu.AddItem("LASER", item);
	
	if(g_Cvar_AdmiralTagPrefixes.BoolValue)
	{
		Format(item, sizeof(item), "Text Prefix: %s", g_bEnableChatPrefixSwitch[client] ? "Yes" : "No");
		menu.AddItem("PREFIX", item);
	}	
	else menu.AddItem("", "Text Prefix: Disabled", ITEMDRAW_DISABLED);
	
	menu.AddItem("TEXT", "Change Text Color", g_bEnableChatPrefixSwitch[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("ADD", "Manage Admirals", IsClientGenericAdmin(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_SettingsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			
			if (StrEqual(item, "LASER"))
			{
				g_bAutoActivePrimaryLaser[param1] = !g_bAutoActivePrimaryLaser[param1];
				Create_SettingsMenu(param1);
			}
			else if (StrEqual(item, "PREFIX"))
			{
				g_bEnableChatPrefixSwitch[param1] = !g_bEnableChatPrefixSwitch[param1];
				Create_SettingsMenu(param1);
			}
			else if (StrEqual(item, "TEXT"))
			{
				Create_TextColorMenu(param1);
			}
			else if (StrEqual(item, "ADD")) Create_AddAdmiralMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_AdmiralMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

void Create_AddAdmiralMenu(int client)
{
	Menu menu = new Menu(Handle_AddAdmiralMenu);
	
	char buffer[128];
	int count;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
		
		Format(buffer, sizeof(buffer), "%N", i);
		
		if(IsPlayerAdmiral(i)) StrCat(buffer, sizeof(buffer), " (Admiral)");
		if(IsClientGenericAdmin(i)) StrCat(buffer, sizeof(buffer), " (Admin)");
		if (!IsClientGenericAdmin(i) && !IsPlayerAdmiral(i)) StrCat(buffer, sizeof(buffer), "");
		
		++count;
		char sUserID[10];
		int UserID = GetClientUserId(i);
		IntToString(UserID, sUserID, sizeof(sUserID));
		menu.AddItem(sUserID, buffer);
	}
	
	menu.SetTitle("» Select A Player: (%d)", count);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_AddAdmiralMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			int UserId = StringToInt(item);
			int target = GetClientOfUserId(UserId);
			
			if(target && IsClientInGame(target))
			{
				ShowAdmiralManageMenu(param1, target);
			}
			else 
			{
				PrintToChat(param1, "\x04[Admiral] \x03Error: \x01Player left the game.");	
				Create_AddAdmiralMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_SettingsMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

void ShowAdmiralManageMenu(int client, int target)
{
	Admiral admiral;
	bool IsAdmiral;
	IsAdmiral = GetAdmiralInfo(target, admiral);
	
	Menu menu = new Menu(Handle_AdmiralManageMenu);
	menu.SetTitle("» Manage: (%N)", target);
	
	char str[64];
	FormatEx(str, sizeof(str), "State: %s", IsAdmiral ? "Admiral" : "None");
	StrCat(str, sizeof(str), IsClientGenericAdmin(target) ? " (Admin)" : " (User)");
	menu.AddItem("", str, ITEMDRAW_DISABLED);
	
	if(admiral.TimeDuration == TIME_FOREVER) str = "Time left: Permanent";
	else if(admiral.TimeLeft <= 60) FormatEx(str, sizeof(str), "Time left: %i seconds", admiral.TimeLeft % 60);
	else if(admiral.TimeLeft > 60 && admiral.TimeLeft <= 3600) FormatEx(str, sizeof(str), "Time left: %i minutes", admiral.TimeLeft / 60 % 60);
	else if(admiral.TimeLeft > 3600 && admiral.TimeLeft <= 86400) FormatEx(str, sizeof(str), "Time left: %i hours", admiral.TimeLeft / 3600);
	else if(admiral.TimeLeft > 86400) FormatEx(str, sizeof(str), "Time left: %i days", admiral.TimeLeft / 86400);
	
	menu.AddItem("", str, ITEMDRAW_DISABLED);
	menu.AddItem("1", "Add admiral", IsAdmiral ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("2", "Add time", IsAdmiral ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("3", "Remove admiral", IsAdmiral ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	g_iMenusTarget[client] = GetClientUserId(target);
}

int Handle_AdmiralManageMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			int task = StringToInt(item);
			int target = GetClientOfUserId(g_iMenusTarget[param1]);
			
			if(!target || !IsClientInGame(target))
			{
				PrintToChat(param1, "[SM] Client has left the game!");
				Create_AddAdmiralMenu(param1);
			}
			
			else switch(task)
			{
				case 1:
				{
					// Add admiral
					g_eMenuAction[param1] = MENU_ACTION_ADD_ADMIRAL;
					ShowMenuTimeCount(param1);
				}
				case 2:
				{
					// Add time
					g_eMenuAction[param1] = MENU_ACTION_ADD_TIME;
					ShowMenuTimeCount(param1);
				}
				case 3:
				{
					float vPos[3];
					GetClientAbsOrigin(target, vPos);
					vPos[2] += 35.0;
					
					// Remove admiral
					RemoveAdmiral(target);
					PrintToChatAll("\x04[Admiral] \x03%N \x01has removed admiral access from \x05%N", param1, target);
					TE_SetupBeamRingPoint(vPos, 10.0, 100.0, g_iBeam, g_iHalo, 0, 10, 1.5, 3.0, 0.5, {255, 50, 50, 120}, 150, 0);
					TE_SendToAll();
					Create_AddAdmiralMenu(param1);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_AddAdmiralMenu(param1);
			}
		}
	}
	return 0;
}

void ShowMenuTimeCount(int client)
{
	int target = GetClientOfUserId(g_iMenusTarget[client]);
	if(!target || !IsClientInGame(target))
	{
		PrintToChat(client, "[SM] Client has left the game!");
		return;
	}
	
	Menu menu = new Menu(Handle_TimeCountMenu);
	
	if(g_eMenuAction[client] == MENU_ACTION_ADD_ADMIRAL)
	{
		menu.SetTitle("» Set time for: (%N)", target);
	}
	else if (g_eMenuAction[client] == MENU_ACTION_ADD_TIME)
	{
		menu.SetTitle("» Adding time for: (%N)", target);
	}
	
	menu.AddItem("3600", "60 Minutes");
	menu.AddItem("86400", "24 Hours");
	menu.AddItem("2592000", "30 Days");
	
	char str[32];
	IntToString(TIME_FOREVER, str, sizeof(str));
	menu.AddItem(str, "Permanent");
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_TimeCountMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				Create_AddAdmiralMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			Admiral admiral;
			bool IsAdmiral;
			
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			int duration = StringToInt(item);
			int target = GetClientOfUserId(g_iMenusTarget[param1]);
			IsAdmiral = GetAdmiralInfo(target, admiral);
			
			float vPos[3];
			GetClientAbsOrigin(target, vPos);
			vPos[2] += 35.0;
			
			if(!target || !IsClientInGame(target))
			{
				Create_AddAdmiralMenu(param1);
				PrintToChat(param1, "[SM] Client has left the game!");
				return 0;
			}
			
			else if(g_eMenuAction[param1] == MENU_ACTION_ADD_ADMIRAL)
			{
				if(duration > 0) PrintToChatAll("\x04[Admiral] \x03%N \x01gave admiral access to \x05%N \x01for \x05%i \x01hours", param1, target, duration/3600);
				else PrintToChatAll("\x04[Admiral] \x03%N \x01gave \x04permanent \x01admiral access to \x05%N.", param1, target);
				
				AddAdmiral(target, duration);
				TE_SetupBeamRingPoint(vPos, 10.0, 100.0, g_iBeam, g_iHalo, 0, 10, 1.5, 3.0, 0.5, {50, 255, 50, 120}, 150, 0);
				TE_SendToAll();
			}
			else if (g_eMenuAction[param1] == MENU_ACTION_ADD_TIME)
			{
				if(IsAdmiral && admiral.TimeDuration == TIME_FOREVER) PrintToChat(param1, "\x04[Admiral] \x03Error: \x05%N \x01already has permanent access to the menu", target);
				else
				{
					if(duration > 0) PrintToChatAll("\x04[Admiral] \x03%N \x01gave \x05%N \x01additional admiral time: \x05+%i \x01hours", param1, target, duration/3600);
					else PrintToChatAll("\x04[Admiral] \x03%N \x01gave \x04permanent \x01admiral access to \x05%N.", param1, target);
					UpdateAdmiral(target, duration);
					TE_SetupBeamRingPoint(vPos, 10.0, 100.0, g_iBeam, g_iHalo, 0, 10, 1.5, 3.0, 0.5, {50, 50, 255, 120}, 150, 0);
					TE_SendToAll();
				}
			}
			Create_AddAdmiralMenu(param1);
		}
	}
	return 0;
}

/* =============================================================================================================== *
 *													Create_TextColorMenu										   *
 *================================================================================================================ */

void Create_TextColorMenu(int client)
{
	Menu menu = new Menu(Handle_TextColorMenu);
	menu.SetTitle("» Select A Color:");
	menu.AddItem("WHITE", "White", g_bText_White[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("PatientZero", "Red", g_bText_Red[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("BLUE", "Blue", g_bText_Blue[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("GREEN", "Green", g_bText_Green[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("OLIVE", "Olive", g_bText_Olive[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("ORANGE", "Orange", g_bText_Orange[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("GRAY", "Gray", g_bText_Gray[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_TextColorMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			
			Disable_TextColors(param1);
			Create_FakeBots();
			
			if (StrEqual(item, "WHITE")) g_bText_White [param1] = true;
			else if (StrEqual(item, "RED")) g_bText_Red [param1] = true;
			else if (StrEqual(item, "BLUE")) g_bText_Blue [param1] = true;
			else if (StrEqual(item, "GREEN")) g_bText_Green [param1] = true;
			else if (StrEqual(item, "OLIVE")) g_bText_Olive [param1] = true;
			else if (StrEqual(item, "ORANGE")) g_bText_Orange [param1] = true;
			else if (StrEqual(item, "GRAY")) g_bText_Gray [param1] = true;
			
			Create_TextColorMenu(param1);
		}
		case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack) 
            {
                Create_SettingsMenu(param1);
			}
    	}
	}
	return 0;
}

/* =============================================================================================================== *
 *												Now To Increase Max Health										   *
 *================================================================================================================ */

void Event_LeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || GetClientTeam(client) != 2) return;
	
	g_bPlayersHasLeftSafeArea = true;
}

void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAdmiral(client)) return;
	
	if (GetClientTeam(client) == 2)
	{
		//SetEntPropEx(client, Prop_Send, "m_iMaxHealth", g_Cvar_AdmiralStartHealth.IntValue);
		//SetEntPropEx(client, Prop_Send, "m_iHealth", g_Cvar_AdmiralStartHealth.IntValue);
		
		if (!g_bPlayersHasLeftSafeArea && !g_bPlayerReplenishHealths [client])
			CreateTimer(0.1, Timer_StartReplenishingMaxHealth, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_StartReplenishingMaxHealth(Handle timer, int client)
{
	CheatCommand(client, "give", "health");
	g_bPlayerReplenishHealths [client] = true;
	return Plugin_Handled;
}

void Event_OnBotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	if (!player || GetClientTeam(player) != 2 || !IsPlayerAdmiral(player)) return;
	
	int bot = GetClientOfUserId(event.GetInt("bot"));
	if (!bot || !IsFakeClient(bot) || GetClientTeam(bot) != 2 ) return;
	
	//int BotCurrentHp = GetClientHealth(bot);
	//SetEntPropEx(player, Prop_Send, "m_iHealth", BotCurrentHp, 1);
}

void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !IsClientInGame(victim)) return;
	
	//Remove Glow Bug Persistance After Death
	SetEntityRenderColor(victim, 255, 255, 255, 255);
	SDKUnhook(victim, SDKHook_PreThink, Rainbow_Aura);
	SetEntPropEx(victim, Prop_Send, "m_iGlowType", 0);
	SetEntPropEx(victim, Prop_Send, "m_glowColorOverride", 0);
	
	//We need to kill any entity, to make sure they are not visible after death
	if(g_iEntEnvTrail[victim] && EntRefToEntIndex(g_iEntEnvTrail[victim]) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(g_iEntEnvTrail[victim], "Kill");
		
	if(g_iEntParticle[victim] && EntRefToEntIndex(g_iEntParticle[victim]) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(g_iEntParticle[victim], "Kill");
	
	//Giving Admiral Survivors LifeSteal Ability
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || attacker > MaxClients || GetClientTeam(attacker) != 2 || !IsPlayerAlive(attacker) || IsFakeClient(attacker) || IsClientIncapped(attacker) || !IsPlayerAdmiral(attacker)) return;
	
	int LifeSteal = g_Cvar_AdmiralHPLifeSteal.IntValue;
	int iMaxHealth = GetEntProp(attacker, Prop_Send, "m_iMaxHealth");
	int CurrentHp = GetClientHealth(attacker);
	
	if ((CurrentHp + LifeSteal) > iMaxHealth) SetEntPropEx(attacker, Prop_Send, "m_iHealth", iMaxHealth, 1);
	else SetEntPropEx(attacker, Prop_Send, "m_iHealth", LifeSteal + CurrentHp, 1);
}

/* =============================================================================================================== *
 *                     							  Here Is All My Checks 										   *
 *================================================================================================================ */

/* =============================================================================================================== *
 *													  Cheat Command 											   *
 *================================================================================================================ */

void CheatCommand(int client, const char[] command, const char[] item)
{
	int CmdFlags = GetCommandFlags(command);
	SetCommandFlags(command, CmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, item);
	SetCommandFlags(command, CmdFlags);
}

 /* ============================================================================================================== *
 *                     					 Admiral Players To Access Admiral Menu									   *
 *================================================================================================================ */
 
bool IsPlayerAdmiral(int client)
{
	Admiral admiral;
	if (GetAdmiralInfo(client, admiral))
		return true;
		
	return false;
}

void SaveConfig()
{
	g_kv.Rewind();
	g_kv.ExportToFile(g_sPath);
}

bool GetAdmiralInfo(int client, Admiral admiral)
{
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	g_kv.Rewind();
	
	if(!g_kv.JumpToKey("Admirals List"))
	{
		delete g_kv;
		ThrowError("Corrupted file %s.", g_sPath);
	}	
	
	if(g_kv.JumpToKey(SteamID))
	{
		char str[32];
		g_kv.GetString("jointime", str, sizeof(str));
		admiral.TimeJoin = StringToInt(str);
		g_kv.GetString("duration", str, sizeof(str));
		admiral.TimeDuration = StringToInt(str);
		admiral.TimeLeft = admiral.TimeJoin + admiral.TimeDuration - GetTime();
		if(admiral.TimeLeft <= 0 && admiral.TimeDuration != TIME_FOREVER)
		{
			g_kv.DeleteThis();
			SaveConfig();
			return false;
		}
		else return true;
	}
	return false;
}

stock bool RemoveAdmiral(int client)
{
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	g_kv.Rewind();
	
	if(!g_kv.JumpToKey("Admirals List"))
	{
		delete g_kv;
		ThrowError("Corrupted file %s.", g_sPath);
	}
		
	if( g_kv.JumpToKey(SteamID) )
	{
		g_kv.DeleteThis();
		SaveConfig();
		return true;
	}
	return false;
}

stock void RemoveAdmiralGhosts()
{
	bool save = false;
	Admiral admiral;
	g_kv.Rewind();
	
	if(!g_kv.JumpToKey("Admirals List"))
	{
		delete g_kv;
		ThrowError("Corrupted file %s.", g_sPath);
	}
	
	if(g_kv.GotoFirstSubKey())
	{
		do
		{
			char str[32];
			g_kv.GetString("jointime", str, sizeof(str));
			admiral.TimeJoin = StringToInt(str);
			g_kv.GetString("duration", str, sizeof(str));
			admiral.TimeDuration = StringToInt(str);
			admiral.TimeLeft = admiral.TimeJoin + admiral.TimeDuration - GetTime();
			
			if( admiral.TimeLeft <= 0 && admiral.TimeDuration != TIME_FOREVER )
			{
				save = true;
				if(g_kv.DeleteThis() != 1)
					break;
			}
			
		} while(g_kv.GotoNextKey());
	}
	if(save) SaveConfig();
}

stock bool AddAdmiral(int client, int duration)
{
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	g_kv.Rewind();
	
	if(!g_kv.JumpToKey("Admirals List"))
	{
		delete g_kv;
		ThrowError("Corrupted file %s.", g_sPath);
	}
	
	if( g_kv.JumpToKey(SteamID, true) )
	{
		char str[32];
		IntToString(GetTime(), str, sizeof(str));
		g_kv.SetString("jointime", str);
		IntToString(duration, str, sizeof(str));
		g_kv.SetString("duration", str);
		SaveConfig();
		
		PrintHintText(client, "Admiral Data File Has Been Updated!");
		return true;
	}
	return false;
}

stock bool UpdateAdmiral(int client, int add_duration)
{
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	g_kv.Rewind();
	
	if(!g_kv.JumpToKey("Admirals List"))
	{
		delete g_kv;
		ThrowError("Corrupted file %s.", g_sPath);
	}
	
	if( g_kv.JumpToKey(SteamID, true) )
	{
		char str[32];
		g_kv.GetString("duration", str, sizeof(str));
		int time = StringToInt(str);
		
		if( add_duration == TIME_FOREVER ) time = TIME_FOREVER;
		else time += add_duration;
		
		IntToString(time, str, sizeof(str));
		g_kv.SetString("duration", str);
		SaveConfig();
		return true;
	}
	return false;
}

 /* ============================================================================================================== *
 *                     						Hanging To Update TakeOver Status									   *
 *================================================================================================================ */

bool IsClientHanging(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0 || GetEntProp(client, Prop_Send, "m_isFallingFromLedge") != 0;
}

/* =============================================================================================================== *
 *                     						Incapped To Update TakeOver Status									   *
 *================================================================================================================ */

bool IsClientIncapped(int client)
{
    return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0 && GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 1;
}

/* =============================================================================================================== *
 *											IsVoteAllowed Check > From Dragokas									   *
 *================================================================================================================ */

bool IsVoteAllowed(int client)
{
	if (g_iRecentVotes[client] != 0)
	{
		if (g_iRecentVotes[client] + g_Cvar_AdmiralVoteDelayer.IntValue > GetTime()) 
		{
			PrintToChat(client, "\x04[Vote System] \x01You can't vote too often!");
			return false;
		}
	}
	
	g_iRecentVotes[client] = GetTime();
	
	int iClients = GetRealClientCount();
	
	if (iClients < g_Cvar_AdmiralVoteMinimum.IntValue) 
	{
		PrintToChat(client, "\x04[Vote System] \x01You require at least \x05%i \x01players to start a vote.", g_Cvar_AdmiralVoteMinimum.IntValue);
		return false;
	}
	return true;
}

/* =============================================================================================================== *
 *                     						Stuff To Help Changing Text Color									   *
 *================================================================================================================ */

int FindRandomPlayersByTeam(int color_team)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && GetClientTeam(client) == color_team)
            return client;
    }
    return 0;
}

void Disable_TextColors(int client)
{
	g_bText_White [client] = false;
	g_bText_Green [client] = false;
	g_bText_Olive [client] = false;
	g_bText_Orange [client] = false;
	g_bText_Red [client] = false;
	g_bText_Blue [client] = false;
	g_bText_Gray [client] = false;
}

void Create_FakeBots()
{
	Create_FakeSpectatorBot();
	Create_FakeSurvivorBot();
	Create_FakeInfectedBot();
}

void Create_FakeSpectatorBot()
{
	int bot = CreateFakeClient("Bot");
	ChangeClientTeam(bot, 1);
	DispatchKeyValue(bot,"classname","SpectatorBot");
	DispatchSpawn(bot);
	CreateTimer(0.1, Kick_SpawnedBot, bot, TIMER_FLAG_NO_MAPCHANGE);
}

void Create_FakeSurvivorBot()
{
	int bot = CreateFakeClient("Bot");
	ChangeClientTeam(bot, 3);
	DispatchKeyValue(bot,"classname","SurvivorBot");
	DispatchSpawn(bot);
	CreateTimer(0.1, Kick_SpawnedBot, bot, TIMER_FLAG_NO_MAPCHANGE);
}

void Create_FakeInfectedBot()
{
	int bot = CreateFakeClient("Bot");
	ChangeClientTeam(bot, 3);
	DispatchKeyValue(bot,"classname","InfectedBot");
	DispatchSpawn(bot);
	CreateTimer(0.1, Kick_SpawnedBot, bot, TIMER_FLAG_NO_MAPCHANGE);
}

Action Kick_SpawnedBot(Handle timer, int bot)
{
	if (!bot || !IsClientInGame(bot)) return Plugin_Stop;
	KickClient(bot, "Bot");
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *                     				We Need To Count Survivors Bots To Allow Takeover							   *
 *================================================================================================================ */

int GetAliveSurvivorsBots()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
			number++;
	}
	return number;
}

/* =============================================================================================================== *
 *                     		 		 	Counting Players To Avoid Unbalanced Game								   *
 *================================================================================================================ */

int HumanSurvivors()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			number++;
	}
	return number;
}

int HumanInfected()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i))
			number++;
	}
	return number;
}

int TotalTeamPlayers() //We need to check only survivors cuz infected not always present
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
			number++;
	}
	return number;
}

/* =============================================================================================================== *
 *                     		 		 	Human Players Count To Make The Vota Allowed 							   *
 *================================================================================================================ */

int GetRealClientCount()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			number++;
	}
	return number;
}

/* =============================================================================================================== *
 *                     	 	 			  	Precache Particles Method: By Silvers								   *
 *================================================================================================================ */
 
void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if ( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}
	if ( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

/* =============================================================================================================== *
 *                     	 	 			  		SetEntPro Method: By Dragokas									   *
 *================================================================================================================ */

void SetEntPropEx(int entity, PropType type, const char[] prop, any value, int size = 4, int element = 0)
{
	if(HasEntProp(entity, type, prop)) SetEntProp(entity, type, prop, value, size, element);
}

/* =============================================================================================================== *
 *												  IsClientGenericAdmin 											   *
 *================================================================================================================ */

bool IsClientGenericAdmin(int client)
{
	return CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false);
}