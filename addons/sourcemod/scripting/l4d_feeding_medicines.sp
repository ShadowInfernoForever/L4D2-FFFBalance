#define PLUGIN_VERSION	"1.2.2"
#define PLUGIN_NAME		"l4d_feeding_medicines"

/**
 *	v1.0 just releases; 14-March-2022
 *	v1.1 new features:
 *		add sound effects support 'adren start', 'adren injected', 'pills start', 'pills used', 'pills ate',
 *		optional feeding self,
 *		optional reward feeder health or buff health,
 *		fix issue 'feeding to an incapped player'; 16-March-2022
 *	v1.2 new features:
 *		healing anim support
 *		wont aggresive stops unreleated progress bar
 *	v1.2.1 fix issue 'feeding_medicines_allows not work proper', support online compile; 23-March-2022
 *	v1.2.2 fix issue 'be feeding target sometime stuck on third person view', change animation work way to solve unknown performance issue; 27-April-2022
 *
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

typeset AnimHookCallback {
	function Action(int client, int &sequence);
}

native bool AnimHookEnable(int client, AnimHookCallback callback, AnimHookCallback callbackPost = INVALID_FUNCTION);
native bool AnimHookDisable(int client, AnimHookCallback callback, AnimHookCallback callbackPost = INVALID_FUNCTION);
native int AnimGetFromActivity(char[] activity);
native float L4D_GetTempHealth(int client);
native int L4D_SetTempHealth(int client, float health);
forward void OnIncapped(Event event, const char[] name, bool dontBroadcast);
forward Action L4D_OnLedgeGrabbed(int client);
forward Action L4D2_OnStagger(int target, int source);
forward Action L4D2_OnPounceOrLeapStumble(int victim, int attacker);
forward Action L4D_OnPouncedOnSurvivor(int victim, int attacker);
forward Action L4D_OnGrabWithTongue(int victim, int attacker);
forward Action L4D2_OnJockeyRide(int victim, int attacker);
forward Action L4D2_OnStartCarryingVictim(int victim, int attacker);

enum {
	Provider =		(1 << 0),
	Receiver =		(1 << 1),
}

enum {
	Other = 0,
	Pills =				(1 << 0),
	Adrenaline =		(1 << 1),
	PillsEvent =		(1 << 2),
	AdrenalineEvent =	(1 << 3),
}

#define SOUND_REJECT			"buttons/button11.wav"
#define SOUND_ADRENALINE_START	"weapons/adrenaline/adrenaline_cap_off.wav"
#define SOUND_ADRENALINE_END	"weapons/adrenaline/adrenaline_needle_in.wav"
#define SOUND_PILLS_START		"player/items/pain_pills/pills_deploy_2.wav"
#define SOUND_PILLS_END_ATE		"player/items/pain_pills/pills_use_1.wav"
#define SOUND_PILLS_END_USED	"player/items/pain_pills/pills_deploy_1.wav"

ConVar Progress_targets;	int progress_targets;
ConVar Allow_medicines;		int allow_medicines;
ConVar Actions;				int actions;
ConVar Pills_buff;			float pills_buff;
ConVar Adrenaline_buff;		float adrenaline_buff;
ConVar Health_max;			float health_max;
ConVar First_aid_cap;
ConVar Overflow_turn;		float overflow_turn;
ConVar Adrenaline_duration;	float adrenaline_duration;
ConVar Duration;			float duration;
ConVar Reward;				float reward;
ConVar Allow_self;			int allow_self;
ConVar Allow_animation;		bool allow_animation;

public Plugin myinfo = {
	name = "[L4D & L4D2] Feeding Medicines",
	author = "NoroHime",
	description = "why you guys dont eat pills",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public void OnPluginStart() {

	CreateConVar						("feeding_medicines_version", PLUGIN_VERSION,		"Version of 'Feeding Medicines'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Progress_targets = 					CreateConVar("feeding_medicines_progress", "-1",	"which targets showing feeding progress bar 1=Feeder 2=Be Feeding -1=Both 0=Disable", FCVAR_NOTIFY);
	Allow_medicines = 					CreateConVar("feeding_medicines_allows", "-1",		"which medicines allow feeding for teammate 1=Pills 2=Adrenaline -1=Both 0=why you install this plugin", FCVAR_NOTIFY);
	Actions = 							CreateConVar("feeding_medicines_actions", "-1",		"which action doing when medicine feeded 1=Pills buff 2=Adrenaline and buff 4=pills event 8=adren event -1=All 0=Disabled", FCVAR_NOTIFY);
	Health_max = 						CreateConVar("feeding_medicines_max", "-1",			"limit of health max -1=Use first_aid_kit_max_heal", FCVAR_NOTIFY);
	Overflow_turn =						CreateConVar("feeding_medicines_overflow", "0.5",	"rate of turn the overflow temp health to real health when reached max, 0.5: turn as half 0: disable 1: completely turn", FCVAR_NOTIFY);
	Duration =							CreateConVar("feeding_medicines_duration", "2.0",	"use duration of feeding a medicine", FCVAR_NOTIFY);
	Reward =							CreateConVar("feeding_medicines_reward", "-10",		"health reward of feeder -10=10 buff health 15=15 health 0=disabled", FCVAR_NOTIFY);
	Allow_self =						CreateConVar("feeding_medicines_self", "2",			"allow player feeding him self 1=allow feed self 2=also reward health", FCVAR_NOTIFY);
	Allow_animation =					CreateConVar("feeding_medicines_anim", "1",			"play healing animation on healer", FCVAR_NOTIFY);


	Pills_buff = 						FindConVar("pain_pills_health_value");
	Adrenaline_buff =					FindConVar("adrenaline_health_buffer");
	Adrenaline_duration =				FindConVar("adrenaline_duration");
	First_aid_cap = 					FindConVar("first_aid_kit_max_heal");

	AutoExecConfig(true, PLUGIN_NAME);

	HookEvent("player_incapacitated_start", OnIncapped);
	HookEvent("player_death", OnIncapped);

	PrecacheSound(SOUND_REJECT);
	PrecacheSound(SOUND_ADRENALINE_START);
	PrecacheSound(SOUND_ADRENALINE_END);
	PrecacheSound(SOUND_PILLS_START);
	PrecacheSound(SOUND_PILLS_END_ATE);
	PrecacheSound(SOUND_PILLS_END_USED);

	Progress_targets		.AddChangeHook(OnConVarChanged);
	Allow_medicines			.AddChangeHook(OnConVarChanged);
	Actions					.AddChangeHook(OnConVarChanged);
	Pills_buff				.AddChangeHook(OnConVarChanged);
	Adrenaline_buff			.AddChangeHook(OnConVarChanged);
	Health_max				.AddChangeHook(OnConVarChanged);
	Overflow_turn			.AddChangeHook(OnConVarChanged);
	First_aid_cap			.AddChangeHook(OnConVarChanged);
	Adrenaline_duration		.AddChangeHook(OnConVarChanged);
	Duration				.AddChangeHook(OnConVarChanged);
	Reward					.AddChangeHook(OnConVarChanged);
	Allow_self				.AddChangeHook(OnConVarChanged);
	Allow_animation			.AddChangeHook(OnConVarChanged);
	
	ApplyCvars();
}

public void ApplyCvars() {
	
	progress_targets = Progress_targets.IntValue;
	allow_medicines = Allow_medicines.IntValue;
	actions = Actions.IntValue;
	pills_buff = Pills_buff.FloatValue;
	adrenaline_buff = Adrenaline_buff.FloatValue;
	overflow_turn = Overflow_turn.FloatValue;
	adrenaline_duration = Adrenaline_duration.FloatValue;
	health_max = Health_max.FloatValue;
	if (health_max < 0)
		health_max = First_aid_cap.FloatValue;
	duration = Duration.FloatValue;
	reward = Reward.FloatValue;
	allow_self = Allow_self.IntValue;
	allow_animation = Allow_animation.BoolValue;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

int feeding_target[MAXPLAYERS + 1];
Handle feeding_timer[MAXPLAYERS + 1];

int CheckMedicine(int client, int weapon = 0) {

	static char name_weapon[32];

	if (!weapon)
		weapon = L4D_GetPlayerCurrentWeapon(client);

	if (IsValidEdict(weapon)) {

		GetEdictClassname(weapon, name_weapon, sizeof(name_weapon));

		if (strcmp(name_weapon, "weapon_pain_pills") == 0)
			return Pills;

		if (strcmp(name_weapon, "weapon_adrenaline") == 0)
			return Adrenaline;
		
	}
	return Other;		
}

void CancelFeeding(int client) {

	if (isSurvivor(client)) {

		if (feeding_target[client]) {

			if (progress_targets & Provider)
				SetupProgressBar(client);

			if (progress_targets & Receiver && isAliveSurvivor(feeding_target[client]))
				SetupProgressBar(feeding_target[client]);
		}

		feeding_target[client] = 0;

		if (allow_animation)
			AnimHookDisable(client, OnAnimation);

		for (int i = 1; i <= MaxClients; i++) {
			if (feeding_target[i] == client) {
				SetupProgressBar(i);
				SetupProgressBar(client);
				feeding_target[i] = 0;
			}
		}

		if (IsValidHandle(feeding_timer[client]))
			KillTimer(feeding_timer[client]);
	}	
}

void StartFeeding(int provider, int receiver) {

	if (progress_targets & Provider)
		SetupProgressBar(provider, duration, 1, receiver, provider);

	if (progress_targets & Receiver)
		SetupProgressBar(receiver, duration, 1, provider, receiver);

	feeding_target[provider] = receiver;

	feeding_timer[provider] = CreateTimer(duration, EndFeeding, provider);

	if (allow_animation)
		AnimHookEnable(provider, OnAnimation);
}

public Action EndFeeding(Handle timer, int provider) {

	switch (CheckMedicine(provider)) {

		case Pills : {

			int receiver = feeding_target[provider];

			if (allow_medicines & Pills && isAliveSurvivor(receiver) && !L4D_IsPlayerIncapacitated(receiver)) {


				if (RemovePlayerItem( provider, L4D_GetPlayerCurrentWeapon(provider) )) {

					if (actions & Pills)
						AddBuffer(receiver, pills_buff);

					if (actions & PillsEvent) {
						Event ate = CreateEvent("pills_used");

						int userid_receiver = GetClientUserId(receiver);

						if (ate) {
							ate.SetInt("userid", userid_receiver);
							ate.SetInt("subject", userid_receiver);
							ate.Fire();
						}
					}

					if ( reward && ( (provider != receiver) || (allow_self == 2) ) ) {

						if (reward < 0)
							AddBuffer(provider, -reward);
						else if (reward > 0) {
							AddHealth(provider, LuckyFloat(reward));
							AddBuffer(provider, 0.0);
						}
					}

					EmitSoundToClient(receiver, SOUND_PILLS_END_ATE);
					EmitSoundToClient(provider, SOUND_PILLS_END_USED);

				}
			}
		}
		case Adrenaline : {

			int receiver = feeding_target[provider];

			if (allow_medicines & Adrenaline && isAliveSurvivor(receiver) && !L4D_IsPlayerIncapacitated(receiver)) {

				if (RemovePlayerItem( provider, L4D_GetPlayerCurrentWeapon(provider) )) {

					if (actions & Adrenaline) {
						AddBuffer(receiver, adrenaline_buff);

						float adren_remain = Terror_GetAdrenalineTime(receiver);
						Terror_SetAdrenalineTime(receiver, adren_remain < 0 ? adrenaline_duration : adren_remain + adrenaline_duration);
					}

					if (actions & AdrenalineEvent) {
						Event ate = CreateEvent("adrenaline_used");

						int userid_receiver = GetClientUserId(receiver);

						if (ate) {
							ate.SetInt("userid", userid_receiver);
							ate.Fire();
						}
					}

					if ( reward && ( (provider != receiver) || (allow_self == 2) ) ) {

						if (reward < 0)
							AddBuffer(provider, -reward);
						else if (reward > 0) {
							AddHealth(provider, LuckyFloat(reward));
							AddBuffer(provider, 0.0);
						}
					}

					EmitSoundToClient(receiver, SOUND_ADRENALINE_END);
					EmitSoundToClient(provider, SOUND_ADRENALINE_END);
				}
			}
		}
	}

	if (progress_targets & Provider)
		SetupProgressBar(provider);

	if (progress_targets & Receiver)
		SetupProgressBar(feeding_target[provider]);

	feeding_target[provider] = 0;

	return Plugin_Continue;
}

public void OnUsePost(int entity, int activator, int caller, UseType type, float value) {

	if (entity == activator && !allow_self)
		return;

	if (isAliveSurvivor(entity) && !L4D_IsPlayerIncapacitated(entity) && isAliveHumanSurvivor(activator)) {

		switch (CheckMedicine(activator)) {

			case Pills :

				if (allow_medicines & Pills) 

					if (IsAllowedHeal(entity)) {

						StartFeeding(activator, entity);

						EmitSoundToClient(entity, SOUND_PILLS_START);
						EmitSoundToClient(activator, SOUND_PILLS_START);
					}
					else
						EmitSoundToClient(activator, SOUND_REJECT);

			case Adrenaline :

				if (allow_medicines & Adrenaline)

					if (IsAllowedHeal(entity)) {

						StartFeeding(activator, entity);

						EmitSoundToClient(entity, SOUND_ADRENALINE_START);
						EmitSoundToClient(activator, SOUND_ADRENALINE_START);
					}
					else
						EmitSoundToClient(activator, SOUND_REJECT);
		}
	}
}

bool IsAllowedHeal(int client) {

	float buffing = L4D_GetTempHealth(client);
	int healthy = GetClientHealth(client);

	if (buffing + healthy > health_max) {

		if (overflow_turn && healthy < health_max)
			return true;
		return false;
	} else
		return true;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {

	static int buttons_last[MAXPLAYERS + 1];

	bool use_released = !(buttons & IN_USE) && (buttons_last[client] & IN_USE);
	buttons_last[client] = buttons;

	if (use_released && isAliveHumanSurvivor(client)) {
		CancelFeeding(client);
	}

}

public void OnClientPutInServer(int client) {

	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	SDKHook(client, SDKHook_UsePost, OnUsePost);

}

public void OnClientDisconnect_Post(int client) {

	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	SDKUnhook(client, SDKHook_UsePost, OnUsePost);

	feeding_target[client] = 0;

	if (IsValidHandle(feeding_timer[client]))
		KillTimer(feeding_timer[client]);

	if (allow_animation)
		AnimHookDisable(client, OnAnimation);
}

public Action OnAnimation(int client, int &sequence) {

	if (feeding_target[client]) {

		if (feeding_target[client] == client)
			sequence = AnimGetFromActivity("ACT_TERROR_HEAL_SELF");
		else 
			sequence = AnimGetFromActivity("ACT_TERROR_HEAL_FRIEND");

		return Plugin_Changed;
	}
	return Plugin_Continue;
}

void SetupProgressBar(int client, float time = 0.0, int action = 0, int entity_target = -1, int entity_owner = -1) {

	SetEntPropEnt(client, Prop_Send, "m_useActionTarget", entity_target);

	SetEntPropEnt(client, Prop_Send, "m_useActionOwner", entity_owner);

	SetEntProp(client, Prop_Send, "m_iCurrentUseAction", action);

	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
}

public void OnWeaponSwitchPost(int client, int weapon) {

	if (isAliveHumanSurvivor(client))
		CancelFeeding(client);
}

void AddBuffer(int client, float buff) {

	float buffing = L4D_GetTempHealth(client);
	int health = GetClientHealth(client);

	if (health + buffing + buff > health_max) {

		if (overflow_turn > 0) {

			float overflow = FloatAbs(health_max - health - buffing - buff) * overflow_turn;

			if (health + overflow > health_max) {

				SetEntityHealth(client, RoundToFloor(health_max));
				L4D_SetTempHealth(client, 0.0);

			} else {

				SetEntityHealth(client, health + RoundToFloor(overflow));
				L4D_SetTempHealth(client, health_max - health - overflow);
			}
		} else 
			L4D_SetTempHealth(client, health_max - health);
	
		} else 
			L4D_SetTempHealth(client, buffing + buff);
}

void AddHealth(int client, int health) {

	int healthy = GetClientHealth(client);

	if (healthy + health > health_max) {

		if (healthy >= health_max) //dont change if reached max
			return;
		else
			SetEntityHealth(client, RoundToFloor(health_max));

	} else
		SetEntityHealth(client, healthy + health);
}

int LuckyFloat(float floating) {

	int floor = RoundToFloor(floating);

	int luck = (floating - floor) > GetURandomFloat();

	return floor + luck;
}

public void OnIncapped(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));
	CancelFeeding(client);
}

public Action L4D_OnLedgeGrabbed(int client) {
	CancelFeeding(client);
	return Plugin_Continue;
}

public Action L4D2_OnStagger(int target, int source) {
	CancelFeeding(target);
	return Plugin_Continue;
}

public Action L4D2_OnPounceOrLeapStumble(int victim, int attacker) {
	CancelFeeding(victim);
	return Plugin_Continue;
}

public Action L4D_OnPouncedOnSurvivor(int victim, int attacker) {
	CancelFeeding(victim);
	return Plugin_Continue;
}

public Action L4D_OnGrabWithTongue(int victim, int attacker) {
	CancelFeeding(victim);
	return Plugin_Continue;
}

public Action L4D2_OnJockeyRide(int victim, int attacker) {
	CancelFeeding(victim);
	return Plugin_Continue;
}

public Action L4D2_OnStartCarryingVictim(int victim, int attacker) {
	CancelFeeding(victim);
	return Plugin_Continue;
}


/*Stocks below*/

stock bool isAliveHumanSurvivor(int client) {
	return isSurvivor(client) && IsPlayerAlive(client) && !IsFakeClient(client);
}

stock bool isAliveSurvivor(int client) {
	return isSurvivor(client) && IsPlayerAlive(client);
}

stock bool isSurvivor(int client) {
	return isClient(client) && GetClientTeam(client) == 2;
}

stock bool isClient(int client) {
	return isClientIndex(client) && IsValidEntity(client) && IsClientInGame(client);
}

stock bool isClientIndex(int client) {
	return (1 <= client <= MaxClients);
}

// ==================================================
// ENTITY STOCKS
// ==================================================

/**
 * @brief Returns a players current weapon, or -1 if none.
 *
 * @param client			Client ID of the player to check
 *
 * @return weapon entity index or -1 if none
 */
stock int L4D_GetPlayerCurrentWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

/**
 * Returns whether player is incapacitated.
 *
 * Note: A tank player will return true when in dying animation.
 *
 * @param client		Player index.
 * @return				True if incapacitated, false otherwise.
 * @error				Invalid client index.
 */
stock bool L4D_IsPlayerIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1));
}


/**
 * Sets the adrenaline effect duration of a survivor.
 *
 * @param iClient		Client index of the survivor.
 * @param flDuration		Duration of the adrenaline effect.
 *
 * @error			Invalid client index.
 **/
// L4D2 only.
stock void Terror_SetAdrenalineTime(int iClient, float flDuration)
{
	// Get CountdownTimer address
	static int timerAddress = -1;
	if(timerAddress == -1)
	{
		timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bAdrenalineActive") - 12;
	}
	
	//timerAddress + 4 = Duration
	//timerAddress + 8 = TimeStamp
	SetEntDataFloat(iClient, timerAddress + 4, flDuration);
	SetEntDataFloat(iClient, timerAddress + 8, GetGameTime() + flDuration);
	SetEntProp(iClient, Prop_Send, "m_bAdrenalineActive", (flDuration <= 0.0 ? 0 : 1), 1);
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
