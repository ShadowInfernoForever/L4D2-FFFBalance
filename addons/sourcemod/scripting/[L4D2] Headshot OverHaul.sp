#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.1.0"

char g_sB[512];

#define headshot1 "npc/infected/gore/bullets/bullet_impact_01.wav"
#define headshot2 "npc/infected/gore/bullets/bullet_impact_02.wav"
#define headshot3 "npc/infected/gore/bullets/bullet_impact_03.wav"
#define headshot4 "npc/infected/gore/bullets/bullet_impact_04.wav"
#define headshot5 "npc/infected/gore/bullets/bullet_impact_05.wav"
#define headshot6 "npc/infected/gore/bullets/bullet_impact_06.wav"
#define headshot7 "npc/infected/gore/bullets/bullet_impact_07.wav"
#define headshot8 "npc/infected/gore/bullets/bullet_impact_08.wav"

#define NUM_SOUNDS 8

public Plugin:myinfo= {
	name = "Headshot Overhaul",
	author = "Shadow",
	description = "Killing Floor 1 / Counter-Strike Styled Headshot Sounds",
	version = PLUGIN_VERSION,
	url = "https://gitlab.com/vbgunz/Dingshot"
}

public void OnMapStart(){

PrecacheSound(headshot1);
PrecacheSound(headshot2);
PrecacheSound(headshot3);
PrecacheSound(headshot4);
PrecacheSound(headshot5);
PrecacheSound(headshot6);
PrecacheSound(headshot7);
PrecacheSound(headshot8);

}

public OnPluginStart() {
	HookEvent("player_hurt", HeadShotHook, EventHookMode_Pre);
	HookEvent("infected_hurt", HeadShotHook, EventHookMode_Pre);
	HookEvent("infected_death", HeadShotHook, EventHookMode_Pre);
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

public HeadShotHook(Handle event, const char[] name, bool dontBroadcast) {

    // Array of headshot sounds
    char headshotSounds[][256] = {
    "headshot1",
    "headshot2",
    "headshot3",
    "headshot4",
    "headshot5",
    "headshot6",
    "headshot7",
    "headshot8"
    };

    int numHeadshotSounds = sizeof(headshotSounds) / sizeof(headshotSounds[0]);

	int hitgroup;

	if (strcmp(name, "infected_death") == 0) {
		hitgroup = GetEventInt(event, "headshot");
        // sound for headshot kill
        int randomHeadshotIndex = GetRandomInt(0, numHeadshotSounds - 1);
        char headshotSoundFile[256];
        strcopy(headshotSoundFile, sizeof(headshotSoundFile), headshotSounds[randomHeadshotIndex]);
        g_sB = headshotSoundFile;
	}

	else {
		hitgroup = GetEventInt(event, "hitgroup");
		// sound for headshot hit
        int randomHeadshotIndex = GetRandomInt(0, numHeadshotSounds - 1);
        char headshotSoundFile[256];
        strcopy(headshotSoundFile, sizeof(headshotSoundFile), headshotSounds[randomHeadshotIndex]);
        g_sB = headshotSoundFile;
	}

    int victim = GetEventInt(event, "entityid");
	int attacker = GetEventInt(event, "attacker");
	int type = GetEventInt(event, "type");
	int client = GetClientOfUserId(attacker);

	float positionVector[3];
        GetEntPropVector(victim, Prop_Send, "m_vecOrigin", positionVector);

	if (isRiotCop(victim)) {
        return; // Skip processing if the entity is a riot cop
    }

	if (IsClientValid(client) && hitgroup == 1 && type != 8) {  // 8 == death by fire...
		EmitSoundToClient(client, g_sB, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	}
}

stock bool:isRiotCop(entity)
{
	if (entity <= 0 || entity > 2048 || !IsValidEntity(entity)) return false;
	decl String:model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	return StrContains(model, "riot") != -1; // Common is a riot uncommon
}
