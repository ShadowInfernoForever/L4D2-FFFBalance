#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "3.0 Beta"

public Plugin:myinfo = 
{
	name = "[L4D, L4D2] Less Than 4 Dead",
	author = "chinagreenelvis",
	description = "Dynamically change the number of survivors",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1330706"
}

new bool:Enabled = false;
new survivorlimit = 0;
new survivors = 0;

new NewClient[MAXPLAYERS+1];

new Handle:lt4d_survivors = INVALID_HANDLE;
new Handle:lt4d_survivorsmin = INVALID_HANDLE;
new Handle:lt4d_survivorsmax = INVALID_HANDLE;

static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;

public OnPluginStart() 
{
	
	//LoadTranslations("common.phrases");
	//hGameConf = LoadGameConfigFile("l4drespawn");
	
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("mission_lost", Event_MissionLost);
	
	StartPrepSDKCall( SDKCall_Player );
	PrepSDKCall_SetFromConf( hGameConf, SDKConf_Signature, "RoundRespawn" );
	
	hRoundRespawn = EndPrepSDKCall();
	if ( hRoundRespawn == INVALID_HANDLE ) 
		SetFailState( "L4D_SM_Respawn: RoundRespawn Signature broken" );

	lt4d_survivors = CreateConVar("lt4d_survivors", "1", "Allow dyanamic survivor numbers? 1: Yes, 0: No", FCVAR_PLUGIN);
	
	lt4d_survivorsmin = CreateConVar("l4d2_survivor_limit_min", "1", "Minimum number of survivors to allow (additional slots are filled by bots)", FCVAR_PLUGIN);
	lt4d_survivorsmax = CreateConVar("l4d2_survivor_limit_max", "8", "Maximum number of survivors to allow", FCVAR_PLUGIN);
	
}

public OnConfigsExecuted()
{
	if (GetConVarInt(lt4d_survivors) == 1)
	{
		new flags = GetConVarFlags(FindConVar("survivor_limit")); 
		if (flags & FCVAR_NOTIFY)
		{ 
			SetConVarFlags(FindConVar("survivor_limit"), flags ^ FCVAR_NOTIFY); 
		}
		
		if (GetConVarInt(lt4d_survivorsmax) < GetConVarInt(lt4d_survivorsmin))
		{
			SetConVarInt(lt4d_survivorsmax, GetConVarInt(lt4d_survivorsmin));
		}
		SetConVarInt(FindConVar("survivor_limit"), GetConVarInt(lt4d_survivorsmax));
		SetConVarInt(FindConVar("sv_visiblemaxplayers"), GetConVarInt(lt4d_survivorsmax));
		SetConVarInt(FindConVar("director_no_survivor_bots"), 1);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsFakeClient(i)) 
			{
				KickClient(i);
			}
		}
	}
}

public OnMapEnd()
{
	if (Enabled == true)
	{
		Enabled = false;
	}
}

public OnClientConnected(client)
{
	PlayerCheck();
	if (client)
	{
		NewClient[client] = 1;
	}
}

public OnClientDisconnect(client)
{
	PlayerCheck();	
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (Enabled == false)
		{
			Enabled = true;
			PlayerCheck();
			CreateTimer(5.0, Timer_DifficultySet);
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (Enabled == false)
		{
			Enabled = true;
			PlayerCheck();
			CreateTimer(5.0, Timer_DifficultySet);
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client)
	{	
		if (GetClientTeam(client) == 2)
		{
			CreateTimer(1.0, Timer_DifficultyCheck);
		}
	}
}

public Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, Timer_DifficultyCheck);
}

public Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	CreateTimer(1.0, Timer_DifficultyCheck);
	if (GetConVarInt(lt4d_survivors) != 0 && NewClient[victim] == 1)
	{
		GiveRandomWeapon(victim);
	}
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarInt(lt4d_survivors) == 1)
	{
		if (NewClient[client] == 1 && GetEventInt(event, "team") == 2)
		{
			CreateTimer(1.0, Timer_Respawn, client);
		}
		if (NewClient[client] == 1 && GetEventInt(event, "team") == 3)
		{
			NewClient[client] = 0;
		}
	}
	else
	{
		NewClient[client] = 0;
	}
}

public Event_MissionLost(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(5.0, Timer_DifficultySet);
}

PlayerCheck()
{
	if (GetConVarInt(lt4d_survivors) == 1)
	{
		if (Enabled == true)
		{
			CreateTimer(2.0, Timer_PlayerCheck);
		}
	}
}

public Action:Timer_PlayerCheck(Handle:timer)
{
	//PrintToChatAll("Performing PlayerCheck");
	new minsurvivors = GetConVarInt(lt4d_survivorsmin);
	new players = 0;
	new bots = 0;
	new survivorplayers = 0;
	new idlesurvivors = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			players++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") == 0) 
		{
			bots++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
		{
			survivorplayers++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") > 0)
		{
			idlesurvivors++;
		}
	}
	new actualsurvivorplayers = survivorplayers + idlesurvivors;
	new waitingplayers = players - actualsurvivorplayers;
	new shouldbots = minsurvivors - actualsurvivorplayers;
	//PrintToChatAll("Actual players %i", players);
	//PrintToChatAll("Actual survivor players %i", actualsurvivorplayers);
	//PrintToChatAll("Survivor bots %i", bots);
	//PrintToChatAll("Idle survivors %i", idlesurvivors);
	if (shouldbots <= 0)
	{
		shouldbots = waitingplayers;
	}
	survivorlimit = actualsurvivorplayers + shouldbots;
	//PrintToChatAll("Survivor limit %i", survivorlimit);
	if (survivorlimit > 0)
	{
		SetConVarInt(FindConVar("survivor_limit"), survivorlimit, true, false);
		if (shouldbots > bots)
		{
			new addbots = shouldbots - bots;
			for (new i = 1; i <= addbots; i++)
			{
				ServerCommand("sb_add");
			}
		}
		if (shouldbots < bots)
		{
			new subtractbots = bots - shouldbots;
			for (new i = 1; i <= subtractbots; i++)
			{
				CreateTimer(2.0, Timer_KickBot);
			}
		}
	}
}

public Action:Timer_DifficultySet(Handle:timer)
{
	//PrintToServer("Setting difficulty");
	survivors = GetConVarInt(FindConVar("survivor_limit"));
}

public Action:Timer_DifficultyCheck(Handle:timer)
{
	new alivesurvivors = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(i)
		{
			if (IsClientConnected(i) && GetClientTeam(i) == 2) 
			{
				if (IsPlayerAlive(i))
				{
					alivesurvivors++;
				}
			}
		}
	}
	PrintToServer("Alive survivors %i", alivesurvivors);
	survivors = alivesurvivors;
}

public Action:Timer_KickBot(Handle:timer)
{	
	//PrintToChatAll("A bot should be about to be kicked.")
	new bool:ABotHasBeenKicked = false;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (ABotHasBeenKicked == false)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) 
			{ 
				//PrintToChatAll("A bot is very likely about to be kicked.")
				if (IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") == 0) 
				{
					//PrintToChatAll("A bot is definitely about to be kicked.")
					if (IsPlayerAlive(i))
					{
						ForcePlayerSuicide(i);
					}
					KickClient(i);
					ABotHasBeenKicked = true;
				}
			}
		}
	}
}

public Action:Timer_Respawn(Handle:timer, any:client)
{
	if (!IsPlayerAlive(client))
	{
		RespawnPlayer(client);
		CreateTimer(3.0, Timer_DifficultySet);
	}
	else
	{
		NewClient[client] = 0;
		CreateTimer(3.0, Timer_DifficultySet);
	}
}

static RespawnPlayer(client)
{
	SDKCall(hRoundRespawn, client);
	//CheatCommand(client, "give", "first_aid_kit");
	GiveRandomWeapon(client);
	TeleportPlayer(client);
}

static GiveRandomWeapon(client)
{
	new RandomWeapon = GetRandomInt(1, 8);
	if (RandomWeapon == 1)
	{
		CheatCommand(client, "give", "pistol_magnum");
	}
	if (RandomWeapon == 2)
	{
		CheatCommand(client, "give", "pumpshotgun");
	}
	if (RandomWeapon == 3)
	{
		CheatCommand(client, "give", "shotgun_chrome");
	}
	if (RandomWeapon == 4)
	{
		CheatCommand(client, "give", "smg");
	}
	if (RandomWeapon == 5)
	{
		CheatCommand(client, "give", "smg_silenced");
	}
	if (RandomWeapon == 6)
	{
		CheatCommand(client, "give", "smg_mp5");
	}
	if (RandomWeapon == 7)
	{
		CheatCommand(client, "give", "sniper_scout");
	}
	if (RandomWeapon == 8)
	{
		CheatCommand(client, "give", "sniper_awp");
	}
}

static TeleportPlayer(client)
{
	new iClients[MAXPLAYERS+1];
	new iNumClients = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && IsPlayerAlive(i) && NewClient[i] == 0)
		{
			iClients[iNumClients++] = i;
			decl String:clientname[64];
			GetClientName(i, clientname, 64);
			//PrintToServer("%s is a valid player to teleport to.", clientname);
		}
	}
	new iRandomClient = iClients[GetRandomInt(0, iNumClients-1)];
	decl String:nameofclient[64];
	GetClientName(iRandomClient, nameofclient, 64);
	//PrintToServer("Teleporting new player to %s", nameofclient);
	new Float:coordinates[3];
	GetClientAbsOrigin(iRandomClient, coordinates);
	TeleportEntity(client, coordinates, NULL_VECTOR, NULL_VECTOR);
	NewClient[client] = 0;
}

stock CheatCommand(client, String:command[], String:arguments[]="")
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}
