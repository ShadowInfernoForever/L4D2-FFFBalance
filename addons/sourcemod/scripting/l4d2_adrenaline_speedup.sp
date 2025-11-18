#define PLUGIN_VERSION	"1.0"
#define PLUGIN_NAME		"l4d2_adrenaline_speedup"

/**
 *	v1.0 just releases; 26-2-22
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

forward void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier);

forward void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier);

forward void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier);

forward void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier);

forward void WH_OnStartThrow(int client, int weapon, int weapontype, float &speedmodifier);

forward void WH_OnReadyingThrow(int client, int weapon, int weapontype, float &speedmodifier);

ConVar Enabled;
ConVar Speed_rate; float speed_rate;
ConVar Buff_actions;	int buff_actions;
ConVar Announce_type;	int announce_types;

static bool hasTranslations;

public Plugin myinfo = {
	name = "[L4D2] Adrenaline SpeedUp <WeaponHandling Add-On>",
	author = "NoroHime",
	description = "SpeedUp when under Adrenaline",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public void OnPluginStart() {

	CreateConVar("adrenaline_speedup_version", PLUGIN_VERSION,				"Version of 'Adrenaline SpeedUp'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enabled = 			CreateConVar("adrenaline_speedup_enabled", "1",		"Enabled 'Adrenaline SpeedUp'", FCVAR_NOTIFY);
	Speed_rate =		CreateConVar("adrenaline_speedup_speed", "1.5", 	"buff speed rate 2:double speed", FCVAR_NOTIFY);
	Buff_actions =		CreateConVar("adrenaline_speedup_actions", "-1", 	"buff actions 1=Firing 2=Deploying 4=Reloading 8=MeleeSwinging 16=Throwing", FCVAR_NOTIFY);
	Announce_type =		CreateConVar("adrenaline_speedup_announces", "2",	"1=center 2=chat 4=hint 7=all add together you want", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_NAME);

	Speed_rate.AddChangeHook(Event_ConVarChanged);
	Buff_actions.AddChangeHook(Event_ConVarChanged);
	Announce_type.AddChangeHook(Event_ConVarChanged);

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/" ... PLUGIN_NAME ... ".phrases.txt");
	hasTranslations = FileExists(path);

	if (hasTranslations)
		LoadTranslations(PLUGIN_NAME ... ".phrases");

	ApplyCvars();
}


public void ApplyCvars() {

	static bool hooked = false;
	bool enabled = Enabled.BoolValue;

	if (enabled && !hooked) {

		HookEvent("pills_used", OnPillsUsed, EventHookMode_Post);
		HookEvent("adrenaline_used", OnArenalineUsed, EventHookMode_Post);

		hooked = true;

	} else if (!enabled && hooked) {

		UnhookEvent("pills_used", OnPillsUsed, EventHookMode_Post);
		UnhookEvent("adrenaline_used", OnArenalineUsed, EventHookMode_Post);

		hooked = false;
	}

	speed_rate = Speed_rate.FloatValue;
	buff_actions = Buff_actions.IntValue;
	announce_types = Announce_type.IntValue;
}

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();

}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void OnArenalineUsed(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid"));

	if (isHumanSurvivor(healer)) {

		float adrenaline_remain = Terror_GetAdrenalineTime(healer);
		
		if (adrenaline_remain > 0)
			Announce(healer, "%t", "Used Remain", adrenaline_remain, "Adrenaline");
		else
			Announce(healer, "%t", "Used", "Adrenaline");
	}
}

public void OnPillsUsed(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid"));

	if (isHumanSurvivor(healer)) {

		float adrenaline_remain = Terror_GetAdrenalineTime(healer);

		if (adrenaline_remain > 0)
			Announce(healer, "%t", "Used Remain", adrenaline_remain, "Pills");
		else
			Announce(healer, "%t", "Used", "Pills");
	}

}

enum {
	Firing = 0,
	Deploying,
	Reloading,
	MeleeSwinging,
	Throwing
}

public void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier) {
	if (buff_actions & (1 << MeleeSwinging) && Terror_GetAdrenalineTime(client) > 0)
		speedmodifier *= speed_rate;
}

public  void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier) {
	if (buff_actions & (1 << Reloading) && Terror_GetAdrenalineTime(client) > 0)
		speedmodifier *= speed_rate;
}

public void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier) {
	if (buff_actions & (1 << Firing) && Terror_GetAdrenalineTime(client) > 0)
		speedmodifier *= speed_rate;
}

public void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier) {
	if (buff_actions & (1 << Deploying) && Terror_GetAdrenalineTime(client) > 0)
		speedmodifier *= speed_rate;
}

public void WH_OnReadyingThrow(int client, int weapon, int weapontype, float &speedmodifier) {
	if (buff_actions & (1 << Throwing) && Terror_GetAdrenalineTime(client) > 0)
		speedmodifier *= speed_rate;
}

public void WH_OnStartThrow(int client, int weapon, int weapontype, float &speedmodifier) {
	if (buff_actions & (1 << Throwing) && Terror_GetAdrenalineTime(client) > 0)
		speedmodifier *= speed_rate;
}


/*Stocks below*/

enum {
	CENTER = 0,
	CHAT,
	HINT
}

void Announce(int client, const char[] format, any ...) {

	static char buffer[254];

	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceColor(buffer, sizeof(buffer));

	if (isClient(client)) {

		if (announce_types & (1 << CHAT))
			PrintToChat(client, "%s", buffer);

		if (announce_types & (1 << HINT))
			PrintHintText(client, "%s", buffer);

		if (announce_types & (1 << CENTER))
			PrintCenterText(client, "%s", buffer);
	}
}

stock void ReplaceColor(char[] message, int maxLen) {

	ReplaceString(message, maxLen, "{white}", "\x01", false);
	ReplaceString(message, maxLen, "{default}", "\x01", false);
	ReplaceString(message, maxLen, "{cyan}", "\x03", false);
	ReplaceString(message, maxLen, "{lightgreen}", "\x03", false);
	ReplaceString(message, maxLen, "{orange}", "\x04", false);
	ReplaceString(message, maxLen, "{olive}", "\x04", false);
	ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock bool isHumanSurvivor(int client) {
	return isClient(client) && GetClientTeam(client) == 2 && !IsFakeClient(client);
}

stock bool isClient(int client) {
	return isClientIndex(client) && IsValidEntity(client) && IsClientInGame(client);
}

stock bool isClientIndex(int client) {
	return (1 <= client <= MaxClients);
}

/**
 * Returns the remaining duration of a survivor's adrenaline effect.
 *
 * @param iClient		Client index of the survivor.
 *
 * @return 			Remaining duration or -1.0 if there's no effect.
 * @error			Invalid client index.
 **/
// L4D2 only.
stock float Terror_GetAdrenalineTime(int iClient)
{
	// Get CountdownTimer address
	static int timerAddress = -1;
	if(timerAddress == -1)
	{
		timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bAdrenalineActive") - 12;
	}
	
	//timerAddress + 8 = TimeStamp
	float flGameTime = GetGameTime();
	float flTime = GetEntDataFloat(iClient, timerAddress + 8);
	if(flTime <= flGameTime)
		return -1.0;
	
	return flTime - flGameTime;
}
