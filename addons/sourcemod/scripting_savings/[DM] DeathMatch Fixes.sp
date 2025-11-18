#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
 
new Handle:l4d_cs_granade_power= INVALID_HANDLE;
new Handle:l4d_cs_granade_radius= INVALID_HANDLE;

public Plugin myinfo =
{
	name = "Grenade Damage Changer",
	author = "Shadow",
	description = "",
	version = "1.0.0.0",
	url = ""
}

public OnPluginStart()
{	
    HookEvent("player_ledge_grab", Event_PlayerIncapped);

	l4d_cs_granade_power = CreateConVar("l4d_cs_granade_power", "5.0", "Power of the granade. Default: 1.0", FCVAR_NOTIFY);
	l4d_cs_granade_radius = CreateConVar("l4d_cs_granade_radius", "2.0", "Radius of the granade.  Default: 1.0", FCVAR_NOTIFY);
}

public OnEntityCreated(iEnt, const String:szClassname[])
{
	if(StrEqual(szClassname, "pipe_bomb_projectile"))
	{
		SDKHook(iEnt, SDKHook_SpawnPost, OnGrenadeSpawn);
	}
}

public OnGrenadeSpawn(iGrenade)
{
	CreateTimer(0.01, ChangeGrenadeDamage, iGrenade, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:ChangeGrenadeDamage(Handle:hTimer, any:iEnt)
{
	new Float:flGrenadePower = GetEntPropFloat(iEnt, Prop_Send, "m_flDamage");
	new Float:flGrenadeRadius = GetEntPropFloat(iEnt, Prop_Send, "m_DmgRadius");
	
	SetEntPropFloat(iEnt, Prop_Send, "m_flDamage", (flGrenadePower*GetConVarFloat(l4d_cs_granade_power)));
	SetEntPropFloat(iEnt, Prop_Send, "m_DmgRadius", (flGrenadeRadius*GetConVarFloat(l4d_cs_granade_radius)));
}

public IsValidClient(client)
{
	if (client == 0)
		return false;

	if (!IsClientConnected(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsValidEntity(client))
		return false;

	return true;
}

public Event_PlayerIncapped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
		ForcePlayerSuicide(client);
	}
}