#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "Remember Spectator Team",
	author = "B-man",
	description = "Remembers who was a spectator on map change",
	version = VERSION,
	url = "http://www.tchalo.com"
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(5.0, RoundStarting)
}

public Action:RoundStarting(Handle:timer, any:client)
{
	for (new i = 1; i <= MaxClients; i++)
        {
				new client = GetClientOfUserId(i)
				ChangeClientTeam(client, 3);
		}
}