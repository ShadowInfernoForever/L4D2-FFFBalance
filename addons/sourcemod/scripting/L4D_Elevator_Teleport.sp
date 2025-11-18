/*=========================================================================================================

	Plugin Info:

*	Name	:	L4D Elevator Teleport
*	Author	:	alasfourom
*	Descp	:	Teleport Survivors To The Elevator After Time Passes
*	Link	:	https://forums.alliedmods.net/showthread.php?t=338961
*	Thanks	:	Silvers, HarryPotter, finishlast

===========================================================================================================

Version 1.2 (10-Aug-2022) - Added countdown, elevator auto-activated after teleport.

Version 1.1 (06-Aug-2022) - Rewrote the plugin, made it more simple.

Version 1.0 (06-Aug-2022) - Initial release.

**********************************************************************************************************/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.2"

/* =============================================================================================================== *
 *									Plugin Variables - float, int, bool, cvars				   					   *
 *================================================================================================================ */

float g_fDuration;

int g_iElevatorButton;
int g_iMapType;

bool g_bLeft4Dead2;
bool g_bLockedButtonPressed;
bool g_bUnlockedButtonPressed;

ConVar g_hPluginEnable;
ConVar g_hTeleportDelay;

enum
{
	C1M1 = 1,
	C1M4,
	C4M2,
	C4M3,
	C6M3,
	C8M4,
	L4D_C8M4
}

/* =============================================================================================================== *
 *                                		 		 Plugin Info													   *
 *================================================================================================================ */

public Plugin myinfo =
{
	name = "L4D Elevator Teleport",
	version = PLUGIN_VERSION,
	description = "Teleport Survivors To The Elevator After Time Passes",
	author = "alasfourom",
	url = "https://forums.alliedmods.net/showthread.php?t=338961"
}

/* =============================================================================================================== *
 *                     		 		 	 Plugin Support L4D 1 & 2												   *
 *================================================================================================================ */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead) g_bLeft4Dead2 = false;
	else if (test == Engine_Left4Dead2) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

//*****************************************************************************************************************

public void OnPluginStart()
{
	CreateConVar ("l4d_elevator_teleport_version", PLUGIN_VERSION, "L4D Elevator Teleport" ,FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hPluginEnable   = CreateConVar("l4d_elevator_teleport_enable", "1.0", "Enable Elevator Teleport Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hTeleportDelay  = CreateConVar("l4d_elevator_teleport_delay", "60.0", "Set The Elevator Teleport Countdown Time", FCVAR_NOTIFY, true, 1.0, true, 5400.0);
	AutoExecConfig (true, "L4D_Elevator_Teleport");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

/* =============================================================================================================== *
 *                                 		Silver's Way - From Lift Plugins										   *
 *================================================================================================================ */

public void OnMapStart()
{
	g_bLockedButtonPressed = false;
	g_bUnlockedButtonPressed = false;
	
	char sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));
	
	int entity = -1;
	g_iElevatorButton = -1;
	g_iMapType = 0;
	
	if (g_bLeft4Dead2)
	{
		if (strcmp(sMap, "c1m1_hotel") == 0 && (entity = FindByClassTargetName("func_button", "elevator_button")) != -1)
		{
			g_iMapType = C1M1;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
		else if (strcmp(sMap, "c1m4_atrium") == 0 && (entity = FindByClassTargetName("func_button", "button_elev_3rdfloor")) != -1)
		{
			g_iMapType = C1M4;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
		else if (strcmp(sMap, "c4m2_sugarmill_a") == 0 && (entity = FindByClassTargetName("func_button", "button_inelevator")) != -1)
		{
			g_iMapType = C4M2;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
		else if (strcmp(sMap, "c4m3_sugarmill_b") == 0 && (entity = FindByClassTargetName("func_button", "button_inelevator")) != -1)
		{
			g_iMapType = C4M3;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
		else if (strcmp(sMap, "c6m3_port") == 0 && (entity = FindByClassTargetName("func_button", "generator_elevator_button")) != -1)
		{
			g_iMapType = C6M3;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
		else if (strcmp(sMap, "l4d_vs_hospital04_interior") == 0 || strcmp(sMap, "l4d_hospital04_interior") == 0
		|| strcmp(sMap, "c8m4_interior") == 0 && (entity = FindByClassTargetName("func_button", "elevator_button")) != -1)
		{
			g_iMapType = C8M4;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
	}
	else
	{
		if (strcmp(sMap, "l4d_hospital04_interior") == 0 || strcmp(sMap, "l4d_vs_hospital04_interior") == 0 && (entity = FindByClassTargetName("func_button", "elevator_button")) != -1)
		{
			g_iMapType = L4D_C8M4;
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
	}
}

//*****************************************************************************************************************

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

//*****************************************************************************************************************
// Pressing The Elevator Button While Locked
void OnElevatorLocked(const char[] output, int caller, int activator, float delay)
{
	if(!g_hPluginEnable.BoolValue) return;
	
	else if (!g_bLockedButtonPressed && !g_bUnlockedButtonPressed) 
	{
		g_bLockedButtonPressed = true;
		g_fDuration = g_hTeleportDelay.FloatValue;
		CreateTimer (1.0, Timer_CountDown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

// Pressing The Elevator Button While Unlocked
void OnElevatorUnlocked(const char[] output, int caller, int activator, float delay)
{
	if(!g_hPluginEnable.BoolValue) return;

	g_bUnlockedButtonPressed = true;
	PrintHintTextToAll("Elevator Activated");
}

//*****************************************************************************************************************
// Countdown Timer Before Teleporting
Action Timer_CountDown(Handle timer)
{
	int timeleft = RoundToNearest(g_fDuration--);
	
	if (g_bUnlockedButtonPressed || !g_bLockedButtonPressed) return Plugin_Stop;
	else if (timeleft >= 0) 
	{
		PrintHintTextToAll("Teleport Time: %d", timeleft);
		return Plugin_Continue;
	}
	else if (timeleft < 0) CreateTimer(0.1, Timer_ElevatorTeleport, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

// After Countdown Reaches 0, Teleport Survivors and Unlock Elevator
Action Timer_ElevatorTeleport(Handle timer)
{
	float pos[3];
	
	if (g_bLeft4Dead2)
	{
		if (g_iMapType == C1M1)
		{
			if( EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE )
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			pos[0] = 2171.0;
			pos[1] = 5810.0; 
			pos[2] = 2529.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR); 
		}
		
		else if (g_iMapType == C1M4)
		{
			if( EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE )
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			pos[0] = -4039.0;
			pos[1] = -3402.0; 
			pos[2] = 598.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
		}
		
		else if (g_iMapType == C4M2)
		{
			if( EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE )
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			pos[0] = -1475.0;
			pos[1] = -9558.0; 
			pos[2] = 660.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR); 
		}
			
		else if (g_iMapType == C4M3)
		{
			if( EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE )
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			pos[0] = -1479.0;
			pos[1] = -9558.0; 
			pos[2] = 175.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR); 
		}
			
		else if (g_iMapType == C6M3)
		{
			if( EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE )
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			pos[0] = -744.0;
			pos[1] = -575.0; 
			pos[2] = 360.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR); 
		}
		
		else if (g_iMapType == C8M4)
		{
			if( EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE )
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			pos[0] = 13427.0;
			pos[1] = 15225.0; 
			pos[2] = 475.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR); 
		}
	}
	else 
	{
		if (g_iMapType == L4D_C8M4)
		{
			if( EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE )
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			pos[0] = 13427.0;
			pos[1] = 15225.0; 
			pos[2] = 475.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR); 
		}
	}

	return Plugin_Continue;
}

//*****************************************************************************************************************
// Silver's Way To "FindByClassTargetName"
int FindByClassTargetName(const char[] sClass, const char[] sTarget)
{
	char sName[64];
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, sClass)) != INVALID_ENT_REFERENCE)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
		if (strcmp(sTarget, sName) == 0) return entity;
	}
	return -1;
}