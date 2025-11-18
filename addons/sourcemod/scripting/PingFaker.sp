#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


new String:g_szPlayerManager[50] = "";

// Entities
new g_iPlayerManager	= -1;

// Offsets
new g_iPing				= -1;

#define PLUGIN_URL "https://github.com/McDaived"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "McDaived"

public Plugin:myinfo =
{
	name = "Ping Faker",
	author = PLUGIN_AUTHOR,
	description = "Change ping for the players on scoreboard",
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	CreateConVar("fp_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	g_iPing	= FindSendPropOffs("CPlayerResource", "sm_iPing");

	decl String:szBuffer[64];
	GetGameFolderName(szBuffer, sizeof(szBuffer));

	if (StrEqual("cstrike", szBuffer))
		strcopy(g_szPlayerManager, sizeof(g_szPlayerManager), "cs_player_manager");
	else if (StrEqual("dod", szBuffer))
		strcopy(g_szPlayerManager, sizeof(g_szPlayerManager), "dod_player_manager");
	else
		strcopy(g_szPlayerManager, sizeof(g_szPlayerManager), "player_manager");
	
	CreateTimer(2.0, LoopClients, _, TIMER_REPEAT);
}

public OnMapStart()
{
	g_iPlayerManager	= FindEntityByClassname(MaxClients + 1, g_szPlayerManager);
	if (g_iPlayerManager == -1 || g_iPing == -1)
	{
		SetFailState("Something is missing!");
	}
	SDKHook(g_iPlayerManager, SDKHook_ThinkPost, OnThinkPost);
	
}

new iPing[MAXPLAYERS+1];
public Action:LoopClients(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		
		new ping = Client_GetFakePing(i, false);
		if (ping <= 30)
		{
			continue;
		}
		else if (ping <= 50)
		{
			iPing[i] = GetRandomInt(20, 25);
		}
		else if (ping <= 90)
		{
			iPing[i] = GetRandomInt(50, 55);
		}
		else
		{
			iPing[i] = GetRandomInt(70, 77);
		}
	}
}

public OnClientDisconnect(client)
{
	iPing[client] = 0;
}

public OnThinkPost(entity)
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (iPing[target] != 0)
		{
			SetEntData(g_iPlayerManager, g_iPing + (target * 4), iPing[target]);
		}
	}
}

#define TICKS_TO_TIME(%1)	( GetTickInterval() * %1 )

stock Client_GetFakePing(client, bool:goldSource=true)
{
	decl ping;
	new Float:latency = GetClientLatency(client, NetFlow_Outgoing); // in seconds
		
	// that should be the correct latency, we assume that cmdrate is higher 
	// then updaterate, what is the case for default settings
	decl String:cl_cmdrate[4];
	GetClientInfo(client, "cl_cmdrate", cl_cmdrate, sizeof(cl_cmdrate));

	new Float:tickRate = GetTickInterval();
	latency -= (0.5 / StringToInt(cl_cmdrate)) + TICKS_TO_TIME(1.0); // correct latency

	ping = RoundFloat(latency * 1000.0); // as msecs
	ping = Math_Clamp(ping, 5, 1000); // set bounds, dont show pings under 5 msecs
	
	return ping;
}

stock any:Math_Clamp(any:value, any:min, any:max)
{
	value = Math_Min(value, min);
	value = Math_Max(value, max);

	return value;
}

stock any:Math_Max(any:value, any:max)
{	
	if (value > max) {
		value = max;
	}
	
	return value;
}

stock any:Math_Min(any:value, any:min)
{
	if (value < min) {
		value = min;
	}
	
	return value;
}

public Action OnClientCommand(int client, int args)
{
	char cmd[16];
	GetCmdArg(0, cmd, sizeof(cmd));
 
	if (StrEqual(cmd, "p_faker"))
	{

		return Plugin_Handled;
	}
 
	return Plugin_Continue;
}

public void_OnPluginStart()
{
	RegConsoleCmd("iping", Command_Test);
}
 
public Action Command_Test(int client, int args)
{
	char arg[128];
	char full[256];
 
	GetCmdArgString(full, sizeof(full));
 
	if (client)
	{
		PrintToServer("Ur Ping : %N");
	} else {
		PrintToServer("done Fake ur Ping.");
	}
 
	PrintToServer("done Fake ur Ping: %s", full);
	PrintToServer("done Fake ur Ping: %d", args);
	for (int i=1; i<=args; i++)
	{
		GetCmdArg(i, arg, sizeof(arg));
		PrintToServer("Argument %d: %s", i, arg);
	}
	return Plugin_Handled;
}