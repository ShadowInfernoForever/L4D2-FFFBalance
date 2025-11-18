//This plugin requires that Sourcemod be modify to hide the print text when players get kicked as it will spam it.

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <l4d_stocks>

#define L4D2_MAXPLAYERS 32

//UL4D2 Teams
#define TEAM_UNKNOWN 0
#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

//UL4D2 ZombieClasses
#define ZC_UNKNOWN 0
#define ZC_SMOKER 1
#define ZC_BOOMER 2
#define ZC_HUNTER 3
#define ZC_SPITTER 4
#define ZC_JOCKEY 5
#define ZC_CHARGER 6
#define ZC_WITCH 7
#define ZC_TANK 8
#define ZC_NOT_INFECTED 9     //survivor

public OnPluginStart()
{
	HookEvent("player_hurt",Player_Got_Hurt, EventHookMode_Pre);
}

public Action:Player_Got_Hurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new player_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));		//This will return ClientID
	new player_victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon))
	PrintToChatAll("You were shot by %s", weapon);
	//PrintToChatAll("Attacker Client Id is %i and Victim Client id is %i", player_attacker, player_victim);
	if (	(IsValidClient(player_attacker)) && (GetClientTeam(player_attacker) == TEAM_SURVIVOR) && (IsPlayerAlive(player_attacker)) && (!IsFakeClient(player_attacker)) )
	{
		if (IsPlayerAlive(player_victim))
		{
			new victim_health = GetClientHealth(player_victim);
			new Float:victim_temp_health = GetEntPropFloat(player_victim, Prop_Send, "m_healthBuffer");
			if (victim_health >= 1)
			{
				SetEntityHealth(player_victim, 100);
			}
			
			if (victim_temp_health > 1)
			{
				SetEntPropFloat(player_victim, Prop_Send, "m_healthBuffer", 100.0);
			}
		}
	}
}


stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	return true;
} 
