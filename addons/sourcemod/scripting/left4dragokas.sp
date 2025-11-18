#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dragokas>

/*
	===============================================================================================
		Credits:
	===============================================================================================
	
	- cravenge
	for "Lockdown System" plugin - I took the most his nice code about doors from there:
	https://forums.alliedmods.net/showthread.php?t=281305
	
	- Nuki
	helping me with fixing incorrect tank count calculation when it is get kicked.
	
	===============================================================================================
		Changelog:
	===============================================================================================
	
	0.1
		- First release
		
	0.2
		- Changed detection method to count kicked tanks
		
	0.3 (28-Jan-2020)
		- Fixed counting tanks on versus (thanks Nuki for report and detailed explanation).
		
	0.4 (05-Jun-2021)
		- Added forward "OnTankCountSpawnedPerRoundChanged" to get info about total number of tanks spawned per this round, excluding those been instantly kicked for some reason.
		- Forward "OnTankCountChanged" is 2 frames delayed to prevent it from firing when the number of tanks is not changed in case tank was instantly kicked via KickClient() command.
		- Some optimizations.
		
	0.5 (12-Jun-2021)
		- Added forward "OnDoorUsed" - Called whenever somebody used the saferoom or final door.
		- Registered library "left4dragokas" for easily identify this dependency.
		
	0.6 (Date unknown)
		- Added ConVar "left4dragokas_version"
		- Added ZOMBIECLASS, DOOR_TYPE and DOOR_STATE (as int types)
		- Added team defines: TEAM_SPECTATOR, TEAM_SURVIVOR, TEAM_INFECTED
		- Added stock IsPlayerIncapped()
		- Added stock IsClientRootAdmin()
		- Added stock IsPlayerPinned()
		- Added stock GetPwnInfected
		- Added stock ForcePanicEvent()
		- Added stock SpawnInfectedAt()
		- Added stock IsCommonInfected()
		- Added stock IsSurvivor()
		- Added stock IsWitch()
		- Added stock GetCommonsCount()
		- Added stock Chase()
		- Added stock IsTank()
		- Added stock IsBoomer()
		- Added stock IsSmoker()
		- Added stock IsHunter()
		- Added stock IsCharger()
		- Added stock IsJockey()
		- Added stock IsSpitter()
		- Added stock IsValidEntRef()
*/

#define PLUGIN_VERSION "0.6"

#define CVAR_FLAGS		FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] Left 4 Dragokas",
	author = "Alex Dragokas",
	description = "Left 4 dead helper functions and forwards",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas/"
}

enum {
	DOOR_FLAG_STARTS_OPEN = 1,
	DOOR_FLAG_STARTS_LOCKED = 2048,
	DOOR_FLAG_SILENT = 4096,
	DOOR_FLAG_USE_CLOSES = 8192,
	DOOR_FLAG_SILENT_NPC = 16384,
	DOOR_FLAG_IGNORE_USE = 32768,
	DOOR_FLAG_UNBREAKABLE = 524288
}

int 	g_iTankCount, g_iTanksCountSpawned, g_iTankCountKicked, g_iCheckpointDoor;
bool 	g_bLateload;
Handle  g_fwdTankCountChanged, g_fwdTankCountSpawnedPerRoundChanged, g_fwdDoorUsed;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateload = late;
	g_fwdTankCountChanged = 				CreateGlobalForward("OnTankCountChanged", 					ET_Ignore, Param_Cell);
	g_fwdTankCountSpawnedPerRoundChanged = 	CreateGlobalForward("OnTankCountSpawnedPerRoundChanged", 	ET_Ignore, Param_Cell);
	g_fwdDoorUsed = 						CreateGlobalForward("OnDoorUsed", 							ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	
	RegPluginLibrary("left4dragokas");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar(						"left4dragokas_version",	PLUGIN_VERSION,	"Plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	HookEvent("round_start", 			Event_RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("tank_spawn",       		Event_TankSpawn,			EventHookMode_Post);
	HookEvent("round_freeze_end", 		Event_OnRoundStartDelayed, 	EventHookMode_PostNoCopy);
	
	if( g_bLateload )
	{
		g_iTankCount = GetTanksCount();
		g_iTanksCountSpawned = g_iTankCount;
		InitDoor();
	}
}

public void Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast) 
{
	g_iTankCount = 0;
	g_iTanksCountSpawned = 0;
	g_iTankCountKicked = 0;
}

public void Event_TankSpawn(Event hEvent, const char[] name, bool dontBroadcast) 
{
	RequestFrame(OnTankSpawn_Frame1, hEvent.GetInt("userid"));
}

public void OnTankSpawn_Frame1(int userid)
{
	int client = GetClientOfUserId(userid);
	if( client && IsClientInGame(client) )
	{
		RequestFrame(OnTankSpawn_Frame2, userid);
	}
	else {
		g_iTankCountKicked ++;
	}
}

public void OnTankSpawn_Frame2(int userid)
{
	int client = GetClientOfUserId(userid);
	if( client && IsClientInGame(client) )
	{
		g_iTankCount ++;
		g_iTanksCountSpawned ++;
		
		Forward_TankCountChanged(g_iTankCount);
		Forward_TankCountSpawnedPerRoundChanged(g_iTanksCountSpawned);
	}
	else {
		g_iTankCountKicked ++;
	}
}

public void OnClientDisconnect(int client)
{
	if( client && IsTank(client) )
	{
		// KickClient is 1 frame delayed 
		// Our counter is 2 frames delayed
		// OnClientDisconnect should be 3 frames delayed to guarantee correct counter value
	
		RequestFrame(OnClientDisconnect_Frame1);
	}
}

public void OnClientDisconnect_Frame1()
{
	RequestFrame(OnClientDisconnect_Frame2);
}

public void OnClientDisconnect_Frame2()
{
	RequestFrame(OnClientDisconnect_Frame3);
}

public void OnClientDisconnect_Frame3()
{
	if( g_iTankCountKicked <= 0 )
	{
		g_iTankCount --;
		Forward_TankCountChanged(g_iTankCount);
	}
	else {
		g_iTankCountKicked --;
	}
}

public void Event_OnRoundStartDelayed(Event hEvent, const char[] name, bool dontBroadcast) 
{
	g_iCheckpointDoor = -1;
	CreateTimer(5.0, Timer_InitDoor, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_InitDoor(Handle timer)
{
	InitDoor();
	return Plugin_Continue;
}

void InitDoor()
{
	if( IsValidEnt(g_iCheckpointDoor) )
	{
		return;
	}
	
	g_iCheckpointDoor = -1;
	
	static char sEntityName[128];
	static char sEntityModel[128];
	
	int door = -1;
	while( (door = FindEntityByClassname(door, "prop_door_rotating_checkpoint")) != -1 )
	{
		if( !IsValidEnt(door) )
		{
			continue;
		}
		
		GetEntPropString(door, Prop_Data, "m_iName", sEntityName, sizeof(sEntityName));
		
		if( strcmp(sEntityName, "checkpoint_entrance") == 0 )
		{
			if( IsValidDoorFlag(door) )
			{
				HookDoor(door);
				break;
			}
		}
		else
		{
			GetEntPropString(door, Prop_Data, "m_ModelName", sEntityModel, sizeof(sEntityModel));
			
			if( strcmp(sEntityModel, "models/props_doors/checkpoint_door_02.mdl") == 0 || 
				strcmp(sEntityModel, "models/props_doors/checkpoint_door_-02.mdl") == 0 )
			{
				if (IsValidDoorFlag(door))
				{
					HookDoor(door);
					break;
				}
			}
		}
	}
}

bool IsValidDoorFlag(int door)
{
	int flags = GetEntProp(door, Prop_Send, "m_spawnflags");
	if( (flags & DOOR_FLAG_USE_CLOSES) && (flags & DOOR_FLAG_IGNORE_USE == 0) )
		return true;
	return false;
}

void HookDoor(int door)
{
	HookSingleEntityOutput(door, "OnFullyOpen", 		OnDoorFullyOpen);
	HookSingleEntityOutput(door, "OnFullyClosed", 		OnDoorFullyClosed);
	//HookSingleEntityOutput(door, "OnLockedUse", OnDoorLockedUse); //not working!
	HookSingleEntityOutput(door, "OnBlockedOpening", 	OnDoorBlocked);
	HookSingleEntityOutput(door, "OnBlockedClosing", 	OnDoorBlocked);
	g_iCheckpointDoor = door;
}

public void OnDoorFullyOpen(const char[] output, int caller, int activator, float delay)
{
	Forward_OnDoorUsed(g_iCheckpointDoor, DOOR_TYPE_FINAL, DOOR_STATE_OPENING);
}

public void OnDoorFullyClosed(const char[] output, int caller, int activator, float delay)
{
	Forward_OnDoorUsed(g_iCheckpointDoor, DOOR_TYPE_FINAL, DOOR_STATE_CLOSING);
}

public void OnDoorBlocked(const char[] output, int caller, int activator, float delay)
{
	Forward_OnDoorUsed(g_iCheckpointDoor, DOOR_TYPE_FINAL, DOOR_STATE_BLOCKED);
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity));
}

stock int GetTanksCount()
{
	int cnt;
	for( int i = 1; i <= MaxClients; i++ )
		if( IsTank(i) )
			cnt++;
	
	return cnt;
}

void Forward_TankCountChanged(int iCount)
{
	Action result;
	Call_StartForward(g_fwdTankCountChanged);
	Call_PushCell(iCount);
	Call_Finish(result);
}

void Forward_TankCountSpawnedPerRoundChanged(int iCount)
{
	Action result;
	Call_StartForward(g_fwdTankCountSpawnedPerRoundChanged);
	Call_PushCell(iCount);
	Call_Finish(result);
}

void Forward_OnDoorUsed(int doorEntity, int /* DOOR_TYPE */ doorType, int /* DOOR_STATE */ doorState)
{
	Action result;
	Call_StartForward(g_fwdDoorUsed);
	Call_PushCell(doorEntity);
	Call_PushCell(doorType);
	Call_PushCell(doorState);
	Call_Finish(result);
}
