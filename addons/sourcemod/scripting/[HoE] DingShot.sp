#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.1.0"

ConVar g_cvHeadShot;
ConVar g_cvKillShot;
char g_HeadShot[256];
char g_KillShot[256];
char g_sB[512];

public Plugin:myinfo= {
	name = "[HoE] Dingshot",
	author = "Victor BUCKWANGS Gonzalez",
	description = "DING Headshot!",
	version = PLUGIN_VERSION,
	url = "https://gitlab.com/vbgunz/Dingshot"
}

public OnMapStart()
{
	PrecacheSound("ui/littlereward.wav");
	//PrecacheSound("insanity/killsound.mp3");

	AddFileToDownloadsTable("sound/ui/littlereward.wav");
	//AddFileToDownloadsTable("sound/insanity/killsound.mp3");
}

public OnPluginStart() {
	HookEvent("player_hurt", HeadShotHook, EventHookMode_Pre);
	HookEvent("infected_hurt", HeadShotHook, EventHookMode_Pre);
	HookEvent("infected_death", HeadShotHook, EventHookMode_Pre);

	g_cvHeadShot = CreateConVar("ds_headshot", "sound/ui/littlereward.wav", "Sound bite for head shot");
	HookConVarChange(g_cvHeadShot, UpdateConVarsHook);
	UpdateConVarsHook(g_cvHeadShot, "sound/ui/littlereward.wav", "sound/ui/littlereward.wav");

	g_cvKillShot = CreateConVar("ds_killshot", "sound/ui/littlereward.wav", "Sound bite for kill shot to the head");
	HookConVarChange(g_cvKillShot, UpdateConVarsHook);
	UpdateConVarsHook(g_cvKillShot, "sound/ui/littlereward.wav", "sound/ui/littlereward.wav");


	AutoExecConfig(true, "dingshot");
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

public UpdateConVarsHook(Handle convar, const char[] oldCv, const char[] newCv) {
	GetConVarName(convar, g_sB, sizeof(g_sB));

	if (StrEqual(g_sB, "ds_headshot")) {
		GetConVarString(g_cvHeadShot, g_HeadShot, sizeof(g_HeadShot));
	}

	else if (StrEqual(g_sB, "ds_killshot")) {
		GetConVarString(g_cvKillShot, g_KillShot, sizeof(g_KillShot));
	}
}

public HeadShotHook(Handle event, const char[] name, bool dontBroadcast) {
	int hitgroup;

	if (strcmp(name, "infected_death") == 0) {
		hitgroup = GetEventInt(event, "headshot");
		g_sB = g_KillShot;
	}

	else {
		hitgroup = GetEventInt(event, "hitgroup");
		g_sB = g_HeadShot;
	}

  
	int attacker = GetEventInt(event, "attacker");
	int type = GetEventInt(event, "type");
	int client = GetClientOfUserId(attacker);


	if (IsClientValid(client) && hitgroup == 1 && type != 8) {  // 8 == death by fire... //Add || hitgroup != 1 for all body sounds
		EmitSoundToClient(client, g_sB, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, _, _, 150);
	}
}