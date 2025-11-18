#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "[FF] Versus Kill Sound",
	author = "AK978",
	version = "1.2"
}

public void OnPluginStart() {
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
    HookEvent("infected_death", OnCommonDeath, EventHookMode_Pre);

    PrecacheSound("ui/littlereward.wav");
}

void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{

    int victim = GetClientOfUserId( event.GetInt("userid") );
	if( victim < 1 || victim > MaxClients || !IsClientInGame(victim) )
		return;

	int attacker = GetClientOfUserId( event.GetInt("attacker") );
	if( (attacker != 0 && attacker < 1) || attacker > MaxClients || !IsClientInGame(victim) )
		return;

    // Check if the killer is a survivor and the victim is a special infected
    if (IsClientValid(attacker) && (GetClientTeam(victim) == 3)) {
        // Play sound to the killer
        EmitSoundToClient(attacker, "ui/littlereward.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
    }
}

void OnCommonDeath(Event event, const char[] name, bool dontBroadcast)
{

	int attacker = GetEventInt(event, "attacker");
    int client = GetClientOfUserId(attacker);

    // Check if the killer is a survivor and the victim is a special infected
    if (IsClientValid(attacker)) {
        // Play sound to the killer
        EmitSoundToClient(attacker, "ui/littlereward.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, 0, 100, 150);
    }
}



bool IsClientValid(int client) {
	if (client >= 1 && client <= MaxClients) {
		if (IsClientConnected(client)) {
			 if (IsClientInGame(client)) {
				return true;
			 }
		}
	}

	return false;
}