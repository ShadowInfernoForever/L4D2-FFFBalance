#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <l4d_sm_respawn>

bool g_bRespawnAvail;

public void OnPluginStart()
{
	RegConsoleCmd("sm_respawn_saferoom", CmdRes1, "Respawn youself at saferoom"); //1 
	RegConsoleCmd("sm_respawn_crosshair", CmdRes2, "<target index> Respawn the target at your crosshair"); // 2
	RegConsoleCmd("sm_respawn_vector", CmdRes3, "<vector> Respawn yourself at position"); // 3
	RegConsoleCmd("sm_respawn_infected", CmdRes4, "<target name> Respawn player as infected next to you"); // 4
	
	/*
		Alternatives, using "sm_respawnex" command:
		
		sm_res1 = sm_respawnex @me 0 8
		sm_res2 = sm_respawnex TargetName @me 1
		sm_res3 = sm_respawnex @me 0 4 -1 "33.0 1200.5 970.6"
		sm_res4 = sm_respawnex TargetName @me 2 3
	*/
}

public Action CmdRes1(int client, int args)
{
	/*
		Example 1: Respawning at spawn point
	*/

	if( !g_bRespawnAvail )
	{
		ReplyToCommand(client, "Respawn is unavailable!");
		return Plugin_Handled;
	}
	
	int target = client;
	
	SM_Respawn(target, _, SPAWN_POSITION_SAFEROOM);
	
	ReplyToCommand(client, "You respawned yourself at spawn point");
	
	return Plugin_Handled;
}
	
public Action CmdRes2(int client, int args)
{
	/*
		Example 2: Respawning target at client's crosshair
	*/
	
	if( !g_bRespawnAvail )
	{
		ReplyToCommand(client, "Respawn is unavailable!");
		return Plugin_Handled;
	}
	
	char sArg[4];
	GetCmdArg(1, sArg, sizeof sArg);
	int target = StringToInt(sArg);
	
	if( target && IsClientInGame(target) )
	{
		SM_Respawn(target, client, SPAWN_POSITION_CROSSHAIR);
	
		ReplyToCommand(client, "You respawned client %N at your crosshair", target);
	}
	else {
		ReplyToCommand(client, "Target %i is invalid", target);
	}
	return Plugin_Handled;
}

public Action CmdRes3(int client, int args)
{
	/*
		Example 3: Respawning yourself at specified coordinates
	*/

	if( !g_bRespawnAvail )
	{
		ReplyToCommand(client, "Respawn is unavailable!");
		return Plugin_Handled;
	}
	
	int target = client;
	
	float vec[3];
	char arg[MAX_TARGET_LENGTH];
	
	GetCmdArg(1, arg, sizeof(arg));
	char axis[3][16];
	ExplodeString(arg, " ", axis, sizeof(axis), sizeof(axis[]));
	vec[0] = StringToFloat(axis[0]);
	vec[1] = StringToFloat(axis[1]);
	vec[2] = StringToFloat(axis[2]);
	
	SM_Respawn(target, client, SPAWN_POSITION_VECTOR, SPAWN_IN_TEAM_DEFAULT, vec);

	ReplyToCommand(client, "You respawned yourself at position: %f %f %f", vec[0], vec[1], vec[2]);

	return Plugin_Handled;
}

public Action CmdRes4(int client, int args)
{
	/*
		Example 4: Respawning player at infected team next to you. Player can be defined by name.
	*/
	
	if( !g_bRespawnAvail )
	{
		ReplyToCommand(client, "Respawn is unavailable!");
		return Plugin_Handled;
	}
	
	char arg[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	GetCmdArg(2, arg, sizeof(arg));
	
	if( (target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0 )
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	int target = target_list[0];
	
	SM_Respawn(target, client, SPAWN_POSITION_ORIGIN, SPAWN_IN_TEAM_INFECTED);
	
	ReplyToCommand(client, "You respawned %N at infected team next to you", target);
	
	return Plugin_Handled;
}

public void OnAllPluginsLoaded()
{
	g_bRespawnAvail = (GetFeatureStatus(FeatureType_Native, "SM_Respawn") == FeatureStatus_Available);
}
