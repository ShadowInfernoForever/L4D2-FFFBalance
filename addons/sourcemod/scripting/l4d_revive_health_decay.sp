#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D & 2] Revive Health Decay",
	author = "Forgetest",
	description = "Decay revive health at a percent as much as incap health.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define KEY_FUNCTION "L4DD::CTerrorPlayer::OnRevived"

ConVar 
survivor_incap_health,
revive_blackwhite_threshold,
g_hMaxRevives;

bool
g_bForceBlackWhite[MAXPLAYERS+1];

public void OnPluginStart()
{
	int bLeft4Dead2;
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead: bLeft4Dead2 = false;
		case Engine_Left4Dead2: bLeft4Dead2 = true;
		default:
		{
			SetFailState("Unsupported engine");
		}
	}
	
	char sGameData[2][] = {"left4dhooks.l4d1", "left4dhooks.l4d2"};
	GameData conf = new GameData(sGameData[bLeft4Dead2]);
	if (conf == null)
		SetFailState("Missing gamedata \"%s\"", sGameData[bLeft4Dead2]);
	
	DynamicDetour hDetour = DynamicDetour.FromConf(conf, KEY_FUNCTION);
	if (!hDetour)
		SetFailState("Missing detour setup for \""...KEY_FUNCTION..."\"");
	if (!hDetour.Enable(Hook_Pre, DTR_CTerrorPlayer_OnRevived))
		SetFailState("Failed to detour \""...KEY_FUNCTION..."\"");
	
	delete hDetour;
	delete conf;
	
	survivor_incap_health = FindConVar("survivor_incap_health");
	g_hMaxRevives = FindConVar("survivor_max_incapacitated_count");
	revive_blackwhite_threshold = CreateConVar("survivor_revive_bw_health", "100.0", "If revived health is less than or equal to this, player revives in black and white.");
}

float flHealthPercent;
MRESReturn DTR_CTerrorPlayer_OnRevived(int pThis, DHookReturn hReturn)
{
	flHealthPercent = 1.0;
	int client = pThis;

	g_bForceBlackWhite[client] = false; // Reset
	
	if (L4D_IsPlayerIncapacitated(client))
	{
		float flHealth = float(GetClientHealth(client));
		flHealthPercent = flHealth / survivor_incap_health.FloatValue;

		if ((flHealth * 1.0) <= revive_blackwhite_threshold.FloatValue)
		{
			g_bForceBlackWhite[client] = true;
		}
	}
	
	return MRES_Ignored;
}

public void L4D2_OnRevived(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	float reviveHealth = L4D_GetTempHealth(client) * flHealthPercent;
	L4D_SetTempHealth(client, reviveHealth);

	if (g_bForceBlackWhite[client])
	{
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		SetEntProp(client, Prop_Send, "m_currentReviveCount", g_hMaxRevives.IntValue);
	}
}