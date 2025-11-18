#define PLUGIN_VERSION "1.4"
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

/*
 *	v1.0 just releases; 1-15-22
 *	v1.1 add option "silence volume", "silence fading time", "trigging sound"; 1-17-22
 *	v1.1.1 now volume silence and trigging sound also work with native call; 1-17-22
 *	v1.1.2 bug fix for ZedBack(); 1-19-22
 *	v1.2 add feature: survivor or survivor bot death trigger Zed Time, code clean and create event forward OnZedTime(); 2-6-22
 *	v1.3 new features:
 *		lucky mode instead threshold mode,
 *		commands 'sm_zedtime [duration] [timescale]', 'sm_zedstop' to trigger manually and permission configuable,
 *		remove ConVar threshold_survivor_death and add threshold_bot to instead,
 *		fix trigger multiple zedtime cause multi sound effects,
 *		rewrite some00 code and less performance usage; 3-March-2022
 *	v1.4 new feature 'boost weapon actions when ZedTime triggering', required '[L4D/L4D2]WeaponHandling_API'; 4-March-2022
 */


ConVar Enable;
ConVar Duration;					float duration;
ConVar Timescale;					float timescale;

ConVar Threshold_needed_base;		float threshold_needed_base;
ConVar Threshold_needed_increase;	float threshold_needed_increase;
ConVar Threshold_cooldown;			float threshold_cooldown;


ConVar Threshold_headshot_ratio;	float threshold_headshot_ratio;
ConVar Threshold_melee_ratio;		float threshold_melee_ratio;
ConVar Threshold_distance_max;		float threshold_distance_max;
ConVar Threshold_distance_ratio;	float threshold_distance_ratio;
ConVar Threshold_piped_ratio;		float threshold_piped_ratio;
ConVar Threshold_grenade_ratio;		float threshold_grenade_ratio;


ConVar Threshold_tank_ratio;		float threshold_tank_ratio;
ConVar Threshold_witch_ratio;		float threshold_witch_ratio;

ConVar Threshold_boomer_ratio;		float threshold_boomer_ratio;
ConVar Threshold_smoker_ratio;		float threshold_smoker_ratio;
ConVar Threshold_hunter_ratio;		float threshold_hunter_ratio;
ConVar Threshold_spitter_ratio;		float threshold_spitter_ratio;
ConVar Threshold_jockey_ratio;		float threshold_jockey_ratio;
ConVar Threshold_charger_ratio;		float threshold_charger_ratio;
ConVar Trigger_silence;				float trigger_silence;
ConVar Trigger_silence_fading;		float trigger_silence_fading;
ConVar Trigger_sound;				char trigger_sound[64];
ConVar Threshold_survivor_death;	float threshold_survivor_death;
ConVar Commands_access;				int commands_access;
ConVar Luckies;						bool luckies;
ConVar Threshold_bot_ratio;			float threshold_bot_ratio;
ConVar Boost_actions;				int boost_actions;
ConVar Boost_speed;					float boost_speed;

GlobalForward OnZedTime;

forward void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier);
forward void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnStartThrow(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnReadyingThrow(int client, int weapon, int weapontype, float &speedmodifier);

static Handle zeding;

static float time_kill_first[MAXPLAYERS+1];
static float thresholds[MAXPLAYERS+1];
static float threshold_required;

public Plugin myinfo = 
{
	name = "[L4D2] Zed Time Highlights System",
	author = "NoroHime",
	description = "Zed Time like Killing Floor now with highlights system",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));

	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	RegPluginLibrary("l4d2_killing_adrenaline");
	CreateNative("ZedTime", ExternalZedTime);
	return APLRes_Success; 
}

public int ExternalZedTime(Handle plugin, int numParams) {
	float durationParam = GetNativeCell(1),
		scaleParam = GetNativeCell(2);
	ZedTime(
		durationParam ? durationParam : duration, 
		scaleParam ? scaleParam : timescale);
	PrintToServer("ZedTime by native");
	return 0;
}


public void OnConfigsExecuted() {
	ApplyCvars();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
	if (convar == Trigger_sound)
		SoundCaching();
}

public void ApplyCvars() {

	static char flags[32];
	static bool hooked = false;

	if (Enable.BoolValue && !hooked) {

		HookEvent("player_death", OnPlayerDeath);
		HookEvent("round_start", OnRoundChanged, EventHookMode_PostNoCopy);
		HookEvent("mission_lost", OnRoundChanged, EventHookMode_PostNoCopy);
		HookEvent("round_end", OnRoundChanged, EventHookMode_PostNoCopy);
		HookEvent("player_team", OnHumanChanged, EventHookMode_PostNoCopy);
		HookEvent("player_bot_replace", OnHumanChanged, EventHookMode_PostNoCopy);
		HookEvent("bot_player_replace", OnHumanChanged, EventHookMode_PostNoCopy);

		hooked = true;

	} else if (!Enable.BoolValue && hooked) {

		UnhookEvent("player_death", OnPlayerDeath);
		UnhookEvent("round_start", OnRoundChanged, EventHookMode_PostNoCopy);
		UnhookEvent("mission_lost", OnRoundChanged, EventHookMode_PostNoCopy);
		UnhookEvent("round_end", OnRoundChanged, EventHookMode_PostNoCopy);
		UnhookEvent("player_team", OnHumanChanged, EventHookMode_PostNoCopy);
		UnhookEvent("player_bot_replace", OnHumanChanged, EventHookMode_PostNoCopy);
		UnhookEvent("bot_player_replace", OnHumanChanged, EventHookMode_PostNoCopy);

		hooked = false;
	}

	duration = Duration.FloatValue;
	timescale = Timescale.FloatValue;

	threshold_needed_base = Threshold_needed_base.FloatValue;
	threshold_needed_increase = Threshold_needed_base.FloatValue;
	threshold_cooldown = Threshold_cooldown.FloatValue;

	threshold_headshot_ratio = Threshold_headshot_ratio.FloatValue;
	threshold_melee_ratio = Threshold_melee_ratio.FloatValue;
	threshold_distance_max = Threshold_distance_max.FloatValue;
	threshold_distance_ratio = Threshold_distance_ratio.FloatValue;
	threshold_piped_ratio = Threshold_piped_ratio.FloatValue;
	threshold_grenade_ratio = Threshold_grenade_ratio.FloatValue;


	threshold_tank_ratio = Threshold_tank_ratio.FloatValue;
	threshold_witch_ratio = Threshold_witch_ratio.FloatValue;
	threshold_boomer_ratio = Threshold_boomer_ratio.FloatValue;
	threshold_smoker_ratio = Threshold_smoker_ratio.FloatValue;
	threshold_hunter_ratio = Threshold_hunter_ratio.FloatValue;
	threshold_spitter_ratio = Threshold_spitter_ratio.FloatValue;
	threshold_jockey_ratio = Threshold_jockey_ratio.FloatValue;
	threshold_charger_ratio = Threshold_charger_ratio.FloatValue;

	trigger_silence = Trigger_silence.FloatValue;
	trigger_silence_fading = Trigger_silence_fading.FloatValue;
	Trigger_sound.GetString(trigger_sound, sizeof(trigger_sound));
	threshold_survivor_death = Threshold_survivor_death.FloatValue;

	Commands_access.GetString(flags, sizeof(flags));
	commands_access = flags[0] ? ReadFlagString(flags) : 0;

	luckies = Luckies.BoolValue;
	threshold_bot_ratio = Threshold_bot_ratio.FloatValue;
	boost_actions = Boost_actions.IntValue;
	boost_speed = Boost_speed.FloatValue;
}

public void OnPluginStart() {
	CreateConVar("zed_time_version", PLUGIN_VERSION, "Version of Zed Time Highlights", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enable =						CreateConVar("zed_time_enable", "1", "Zed Time enable", FCVAR_NOTIFY);
	Duration =						CreateConVar("zed_time_duration", "0.5", "zed time duration", FCVAR_NOTIFY, true, 0.1);
	Timescale =						CreateConVar("zed_time_timescale", "0.2", "zed time scale of game time", FCVAR_NOTIFY, true, 0.1, true, 1.0);
	Threshold_needed_base =			CreateConVar("zed_time_threshold_needed_base", "4", "to trigger zed time you need kill many zombie on short time, 4 means you need to kill 4 worth value of zombies", FCVAR_NOTIFY, true, 1.0);
	Threshold_needed_increase =		CreateConVar("zed_time_threshold_needed_increase", "1.33", "every alive human survivor will increase zed time threshold needed, if 3 human you should kill 6.66(4+2*1.33) unit zombies to trigger", FCVAR_NOTIFY, true, 0.0);

	Threshold_cooldown =			CreateConVar("zed_time_threshold_cooldown", "0.3", "if kill threshold worth greater than needed and between this time then trigger", FCVAR_NOTIFY, true, 0.01);

	Threshold_headshot_ratio =		CreateConVar("zed_time_threshold_headshot_ratio", "1.5", "worth value multiplier of headshot", FCVAR_NOTIFY, true, 1.0);

	Threshold_distance_max =		CreateConVar("zed_time_threshold_distance_max", "1200", "max distance to apply multiplier worth value", FCVAR_NOTIFY, true, 220.0);
	Threshold_distance_ratio =		CreateConVar("zed_time_threshold_distance_ratio", "1.5", "if kill distance close to max, multiplier also close to x1.5, nearest is x1", FCVAR_NOTIFY, true, 1.0);

	Threshold_piped_ratio =			CreateConVar("zed_time_threshold_piped_ratio", "0.85", "if zombie kill by pipe bomb, the kill worth multiply this value", FCVAR_NOTIFY, true, 0.0);
	Threshold_melee_ratio =			CreateConVar("zed_time_threshold_melee_ratio", "1.16", "multiplier of melee kill", FCVAR_NOTIFY, true, 0.0);
	Threshold_grenade_ratio =		CreateConVar("zed_time_threshold_grenade_ratio", "0.75", "multiplier of grenade launcher kill", FCVAR_NOTIFY, true, 0.0);

	Threshold_tank_ratio =			CreateConVar("zed_time_threshold_tank_ratio", "32", "multiplier of tank death", FCVAR_NOTIFY, true, 0.0);
	Threshold_witch_ratio =			CreateConVar("zed_time_threshold_witch_ratio", "32", "multiplier of witch death", FCVAR_NOTIFY, true, 0.0);

	Threshold_boomer_ratio =		CreateConVar("zed_time_threshold_boomer_ratio", "1.33", "multiplier of boomer death", FCVAR_NOTIFY, true, 0.0);
	Threshold_smoker_ratio =		CreateConVar("zed_time_threshold_smoker_ratio", "1.33", "multiplier of smoker death", FCVAR_NOTIFY, true, 0.0);
	Threshold_hunter_ratio =		CreateConVar("zed_time_threshold_hunter_ratio", "1.25", "multiplier of hunter death", FCVAR_NOTIFY, true, 0.0);
	Threshold_spitter_ratio =		CreateConVar("zed_time_threshold_spitter_ratio", "1.2", "multiplier of spitter death", FCVAR_NOTIFY, true, 0.0);
	Threshold_jockey_ratio =		CreateConVar("zed_time_threshold_jockey_ratio", "1.25", "multiplier of jockey death", FCVAR_NOTIFY, true, 0.0);
	Threshold_charger_ratio =		CreateConVar("zed_time_threshold_charger_ratio", "1.5", "multiplier of charger death", FCVAR_NOTIFY, true, 0.0);
	Trigger_silence =				CreateConVar("zed_time_trigger_silence", "50", "percent of silence volume, 0: do not silence, 100: completely silence", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	Trigger_silence_fading =		CreateConVar("zed_time_trigger_silence_fading", "0.2", "silence fading time, 0: instantly silence", FCVAR_NOTIFY, true, 0.0);
	Trigger_sound =					CreateConVar("zed_time_trigger_sound", "level/countdown.wav", "trigger sound play to all client. recommanded: ui/menu_countdown.wav level/countdown.wav plats/churchbell_end.wav", FCVAR_NOTIFY);

	Threshold_survivor_death =		CreateConVar("zed_time_threshold_survivor_death", "32", "threashold value of survivor death trigger Zed Time, 0:disable", FCVAR_NOTIFY, true, 0.0);
	Commands_access =				CreateConVar("zed_time_access", "f", "admin flag to acces ZedTime commands f:slay empty:allow everyone", FCVAR_NOTIFY);
	Luckies =						CreateConVar("zed_time_lucky", "0", "use lucky mode instead threshold mode, also effect by threshold requirement", FCVAR_NOTIFY, true, 0.0);
	Threshold_bot_ratio =			CreateConVar("zed_time_threshold_bot", "0.5", "bot weight ratio, 0.5:bot cause half threshold 0:bot cant trigger", FCVAR_NOTIFY, true, 0.0);
	Boost_actions =					CreateConVar("zed_time_boost_actions", "-1", "which actions boost under ZedTime \n1=Firing 2=Deploying 4=Reloading 8=MeleeSwinging 16=Throwing -1=All.\nadd numbers together you want", FCVAR_NOTIFY);
	Boost_speed =					CreateConVar("zed_time_boost_speed", "-1", "how fast boost the actions under ZedTime\n-1:auto scaling by timescale 2:doubling speed 0:disable", FCVAR_NOTIFY);

	RegConsoleCmd("sm_zedtime", CommandZedTime, "Trigger ZedTime manually. Usage: sm_zedtime [duration] [timescale]");
	RegConsoleCmd("sm_zedstop", CommandZedStop, "stop the zedtime manually");

	Enable.AddChangeHook(OnConVarChanged);
	Duration.AddChangeHook(OnConVarChanged);
	Timescale.AddChangeHook(OnConVarChanged);
	Threshold_needed_base.AddChangeHook(OnConVarChanged);
	Threshold_needed_increase.AddChangeHook(OnConVarChanged);
	Threshold_cooldown.AddChangeHook(OnConVarChanged);
	Threshold_headshot_ratio.AddChangeHook(OnConVarChanged);
	Threshold_distance_max.AddChangeHook(OnConVarChanged);
	Threshold_distance_ratio.AddChangeHook(OnConVarChanged);
	Threshold_piped_ratio.AddChangeHook(OnConVarChanged);
	Threshold_melee_ratio.AddChangeHook(OnConVarChanged);
	Threshold_tank_ratio.AddChangeHook(OnConVarChanged);
	Threshold_witch_ratio.AddChangeHook(OnConVarChanged);
	Threshold_boomer_ratio.AddChangeHook(OnConVarChanged);
	Threshold_smoker_ratio.AddChangeHook(OnConVarChanged);
	Threshold_hunter_ratio.AddChangeHook(OnConVarChanged);
	Threshold_spitter_ratio.AddChangeHook(OnConVarChanged);
	Threshold_jockey_ratio.AddChangeHook(OnConVarChanged);
	Threshold_charger_ratio.AddChangeHook(OnConVarChanged);
	Threshold_grenade_ratio.AddChangeHook(OnConVarChanged);
	Trigger_silence.AddChangeHook(OnConVarChanged);
	Trigger_silence_fading.AddChangeHook(OnConVarChanged);
	Trigger_sound.AddChangeHook(OnConVarChanged);
	Threshold_survivor_death.AddChangeHook(OnConVarChanged);
	Commands_access.AddChangeHook(OnConVarChanged);
	Luckies.AddChangeHook(OnConVarChanged);
	Boost_actions.AddChangeHook(OnConVarChanged);
	Boost_speed.AddChangeHook(OnConVarChanged);
	ApplyCvars();

	OnZedTime = new GlobalForward("OnZedTime", ET_Ignore, Param_Cell, Param_Cell);

	AutoExecConfig(true, "l4d2_zed_time_highlights");
}

bool HasPermission(int client) {

	int flag_client = GetUserFlagBits(client);

	if (!commands_access || flag_client & ADMFLAG_ROOT) return true;

	return view_as<bool>(flag_client & commands_access);
}


public Action CommandZedTime(int client, int args) {

	static char arg1[8], arg2[8];

	if (isClient(client) && HasPermission(client)) {

		switch(args) {
			case 0 : ZedTime(duration, timescale);
			case 1 : {
				GetCmdArg(1, arg1, sizeof(arg1));
				ZedTime(StringToFloat(arg1), timescale);
			}
			case 2 : {
				GetCmdArg(1, arg1, sizeof(arg1));
				GetCmdArg(2, arg2, sizeof(arg2));
				ZedTime(StringToFloat(arg1), StringToFloat(arg2));
			}
		}
	} else {
		ReplyToCommand(client, "Permission Denied.");
	}
	
	return Plugin_Handled;
}


public Action CommandZedStop(int client, int args) {

	if (isClient(client) && HasPermission(client)) {

		ZedBack(INVALID_HANDLE, -1);

	} else
		ReplyToCommand(client, "Permission Denied.");
	
	return Plugin_Handled;
}


public void OnRoundChanged(Event event, const char[] name, bool dontBroadcast) {

	if(IsValidHandle(zeding)) {

		TriggerTimer(zeding);
		zeding = INVALID_HANDLE;

	} else {
		ZedBack(INVALID_HANDLE, -1);
	}
}
	
public void OnMapStart() {
	SoundCaching();

PrecacheSound("insanity/zedtime.mp3");
AddFileToDownloadsTable("sound/insanity/zedtime.mp3");

}

void SoundCaching() {
	if (trigger_sound[0]) {
		PrefetchSound(trigger_sound);
		PrecacheSound(trigger_sound);
	}
}

float ThresholdAdd(int attacker, float worth) {
	float time = GetEngineTime();
	bool waits = false;
	float threshold_require = threshold_required;

	if (
		worth > threshold_require ||
		time_kill_first[attacker] && 
		(time - time_kill_first[attacker]) < threshold_cooldown
	) {
		// PrintToChatAll("diff: %d, required: %d, kills: %d", aliveHumanSurvivorDiff, requireKills, CountKilled[attacker]);
		
		thresholds[attacker] += worth;

		// PrintToChat(attacker, "worth: %.1f, require: %.1f, total: %.1f, between: %.2f, cd: %.2f", worth, threshold_require, thresholds[attacker], time - time_kill_first[attacker], threshold_cooldown);

		if (thresholds[attacker] >= threshold_require) {

			time_kill_first[attacker] = time;
			thresholds[attacker] = 0.0;

			ZedTime(duration, timescale);

		}

	} else {
		waits = true;
	}

	if (IsValidHandle(zeding) || waits) {
		time_kill_first[attacker] = time;
		thresholds[attacker] = worth;
	}

	return thresholds[attacker];
}

void ThresholdLucky(float worth) {
	if (worth > GetRandomFloat(0.0, threshold_required))
		ZedTime(duration, timescale);
}


public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	static char weapon[32], victimname[32];
	static float victim_pos[3];

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	event.GetString("victimname", victimname, sizeof(victimname));
	event.GetString("weapon", weapon, sizeof(weapon));

	victim_pos[0] = event.GetFloat("victim_x");
	victim_pos[1] = event.GetFloat("victim_y");
	victim_pos[2] = event.GetFloat("victim_z");

	bool isHeadshot = event.GetBool("headshot");
	bool isPiped = strcmp(weapon, "pipe_bomb") == 0;
	bool isMelee = strcmp(weapon, "melee") == 0;
	bool isGrenade = StrContains(weapon, "projectile") != -1;

	float ratio = 1.0;

	if (isPiped)
		ratio *= threshold_piped_ratio;

	if (isHeadshot)
		ratio *= threshold_headshot_ratio;

	if (isMelee)
		ratio *= threshold_melee_ratio;

	if (isGrenade)
		ratio *= threshold_grenade_ratio;

	if (isClient(attacker)) {

		float attacker_pos[3];
		GetClientAbsOrigin(attacker, attacker_pos);
		ratio *= 1.0 + (threshold_distance_ratio - 1) * ((GetVectorDistance(attacker_pos, victim_pos, false) / threshold_distance_max));
	}

	switch (victimname[0]) {
		case 'I' : ratio *= 1.0;
		case 'S' : ratio *= victimname[1] == 'm' ? threshold_smoker_ratio : threshold_spitter_ratio;
		case 'B' : ratio *= threshold_boomer_ratio;
		case 'H' : ratio *= threshold_hunter_ratio;
		case 'J' : ratio *= threshold_jockey_ratio;
		case 'C' : ratio *= threshold_charger_ratio;
		case 'W' : ratio *= threshold_witch_ratio;
		case 'T' : ratio *= threshold_tank_ratio;
		default : {

			int victim = GetClientOfUserId(event.GetInt("userid"));

			if (isSurvivor(victim) && threshold_survivor_death > 0) { //survivor death trigger

			float threshold_value = IsFakeClient(victim) ? threshold_survivor_death * threshold_bot_ratio : threshold_survivor_death;

			if (threshold_value >= threshold_required) //threashold reached
				ZedTime(duration, timescale);
			}

			ratio = 0.0;
		}
	}

	if (ratio && isSurvivor(attacker)) {

		if (IsFakeClient(attacker))
			ratio *= threshold_bot_ratio;

		if (ratio > 0) 
			if (luckies)
				ThresholdLucky(ratio);
			else 
				ThresholdAdd(attacker, ratio);
	}

}

void ZedTime(float duration, float scale) {

	if (IsValidHandle(zeding))
		TriggerTimer(zeding);

	
	for(int client = 1; client <= MaxClients; client++)
		if (isClient(client)) {
			if (trigger_silence)
				FadeClientVolume(client, trigger_silence, trigger_silence_fading, duration - trigger_silence_fading, trigger_silence_fading);
			if (trigger_sound[0]) {
				StopSound(client, SNDCHAN_STATIC, trigger_sound);
				EmitSoundToClient(client, trigger_sound, client, SNDCHAN_STATIC);
			}
		}

	int entity = CreateEntityByName("func_timescale");

	char SCALE[8];
	FloatToString(scale, SCALE, sizeof(SCALE));
	DispatchKeyValue(entity, "desiredTimescale", SCALE);
	DispatchKeyValue(entity, "acceleration", "2.0");
	DispatchKeyValue(entity, "minBlendRate", "1.0");
	DispatchKeyValue(entity, "blendDeltaMultiplier", "2.0");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "Start");

	zeding = CreateTimer(duration, ZedBack, entity);

	Call_StartForward(OnZedTime); //event forwarding
	Call_PushCell(duration);
	Call_PushCell(scale);
	Call_Finish();

	int entitycol = CreateEntityByName("color_correction");
	if( entitycol == -1 )
	{
		LogError("Failed to create 'color_correction'");
		return;
	}
	else
	{
		//g_iInfectedMind[index][1] = EntIndexToEntRef(entity);

        DispatchKeyValue(entitycol, "filename", "materials/correction/thirdstrike.raw");
		//DispatchKeyValue(entitycol, "spawnflags", "2");
		DispatchKeyValue(entitycol, "maxweight", "20.0");
		DispatchKeyValue(entitycol, "fadeInDuration", "8");
		DispatchKeyValue(entitycol, "fadeOutDuration", "8");
		DispatchKeyValue(entitycol, "maxfalloff", "-1");
		DispatchKeyValue(entitycol, "minfalloff", "-1");
		DispatchKeyValue(entitycol, "StartDisabled", "1");
		DispatchKeyValue(entitycol, "exclusive", "1");

		DispatchSpawn(entitycol);
		ActivateEntity(entitycol);
		AcceptEntityInput(entitycol, "Enable");
		DispatchKeyValue(entitycol, "targetname", "zedcorrection");
	}
	zeding = CreateTimer(duration, ZedBackCol, entitycol);


}

public Action ZedBack(Handle Timer, int entity) {

	if(IsValidEdict(entity)) {
		AcceptEntityInput(entity, "Stop");
	} else {
		int found = -1;
		while ((found = FindEntityByClassname(found, "func_timescale")) != -1)
			if (IsValidEdict(found))
				AcceptEntityInput(found, "Stop");
	}


	zeding = INVALID_HANDLE;
	return Plugin_Continue;
}

public Action ZedBackCol(Handle Timer, int entitycol) {

    if(IsValidEdict(entitycol)) {
		AcceptEntityInput(entitycol, "Disable");
	} else {
		int found = -1;
		while ((found = FindEntityByClassname(found, "color_correction")) != -1)
			if (IsValidEdict(found))
				AcceptEntityInput(found, "Disable");
	}


	zeding = INVALID_HANDLE;
	return Plugin_Continue;
}

enum {
	Firing = 0,
	Deploying,
	Reloading,
	MeleeSwinging,
	Throwing
};

float SpeedStatus(float speedmodifier) {

	if (boost_speed == -1)

		return speedmodifier * (1.0 / timescale);

	else if (boost_speed > 0)

		return speedmodifier * boost_speed;

	return speedmodifier;
}

public void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier) {

	if (boost_actions & (1 << MeleeSwinging) && boost_speed && IsValidHandle(zeding))
		speedmodifier = SpeedStatus(speedmodifier);
}

public  void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier) {

	if (boost_actions & (1 << Reloading) && boost_speed && IsValidHandle(zeding))
		speedmodifier = SpeedStatus(speedmodifier);
}

public void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier) {

	if (boost_actions & (1 << Firing) && boost_speed && IsValidHandle(zeding))
		speedmodifier = SpeedStatus(speedmodifier);
}

public void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier) {

	if (boost_actions & (1 << Deploying) && boost_speed && IsValidHandle(zeding))
		speedmodifier = SpeedStatus(speedmodifier);

}

public void WH_OnReadyingThrow(int client, int weapon, int weapontype, float &speedmodifier) {

	if (boost_actions & (1 << Throwing) && boost_speed && IsValidHandle(zeding))
		speedmodifier = SpeedStatus(speedmodifier);
}

public void WH_OnStartThrow(int client, int weapon, int weapontype, float &speedmodifier) {

	if (boost_actions & (1 << Throwing) && boost_speed && IsValidHandle(zeding))
		speedmodifier = SpeedStatus(speedmodifier);
}

public void OnClientPutInServer(int client) {
	GetThresholdRequired();
}

public void OnClientDisconnect_Post(int client) {
	GetThresholdRequired();
}

public void OnHumanChanged(Event event, const char[] name, bool dontBroadcast) {
	GetThresholdRequired();
}

float GetThresholdRequired() {

	int alives = 0;

	for (int client = 1; client <= MaxClients; client++) {
		if (isAliveHumanSurvivor(client))
			alives++;
	}

	float threshold_require = threshold_needed_base;

	if (alives > 0)
		threshold_require += RoundToNearest((alives - 1) * threshold_needed_increase);

	return threshold_required = threshold_require;
}

bool isAliveHumanSurvivor(int client){
	return isHumanSurvivor(client) && IsPlayerAlive(client);
}

bool isHumanSurvivor(int client){
	return isSurvivor(client) && !IsFakeClient(client);
}

bool isSurvivor(int client) {
	return isClient(client) && GetClientTeam(client) == 2;
}

bool isClient(int client) {
	return isClientIndex(client) && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client);
}
bool isClientIndex(int client) {
	return (1 <= client <= MaxClients);
}
