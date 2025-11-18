#define PLUGIN_VERSION		"1.0"
#define PLUGIN_NAME			"l4d2_tank_regen"
#define PLUGIN_NAME_FULL	"[L4D2] Tank health regen"
#define PLUGIN_DESCRIPTION	"Configurable tank health regen"
#define PLUGIN_AUTHOR		"liquidplasma"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?p=2821760"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>

/*ZombieClasses*/
#define ZOMBIECLASS_TANK 8
#define TEAM_INFECTED 3

ConVar cHealDelay; 			float g_fHealDelay;
ConVar cDivisionQuotient;	float g_fDivisionQuotient;
ConVar cOverHeal;			float g_fOverHeal;
ConVar cHealBots; 			bool g_bHealBots;

int OffsetHealth;
Handle RegenTimer = null;
static bool Once;

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

bool IsTank(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_TANK;
}

public void OnPluginStart()
{
	HookEvent("round_end", 				round_end, 				EventHookMode_PostNoCopy);

	cHealDelay = CreateConVar(PLUGIN_NAME ... "_delay", "0.4", "Time in seconds for a healing tick of 'tank MAX HP / " ... PLUGIN_NAME ... "_quotient'", FCVAR_NOTIFY);
	cDivisionQuotient = CreateConVar(PLUGIN_NAME ... "_quotient", "320.0", "Amount that the MAX HP of the tank will be divided by", FCVAR_NOTIFY);
	cOverHeal = CreateConVar(PLUGIN_NAME ... "_overheal_multiplier", "1.0", "Multiplier to heal over tank MAX HP", FCVAR_NOTIFY);
	cHealBots = CreateConVar(PLUGIN_NAME ... "_heal_bots", "0", "Wether or not tank bots should regen their hp | 0 - disabled / 1 - enabled", FCVAR_NOTIFY);
	OffsetHealth = FindSendPropInfo("CCSPlayer", "m_iHealth");

	AutoExecConfig(true, PLUGIN_NAME);

	cHealDelay.AddChangeHook(ChangeConvarDelay);
	cDivisionQuotient.AddChangeHook(ChangeConvar);
	cHealBots.AddChangeHook(ChangeConvar);
	cOverHeal.AddChangeHook(ChangeConvar);
	ChangedCvars();
}

public void ChangeConvarDelay(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ChangedCvars();
	Once = false;
	KillRegenTimer();
	CreateRegenTimer(g_fHealDelay);
}

public void ChangeConvar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ChangedCvars()
}

public void OnConfigsExecuted()
{
	ChangedCvars();
}

void ChangedCvars()
{
	g_fHealDelay = cHealDelay.FloatValue;
	g_fDivisionQuotient = cDivisionQuotient.FloatValue;
	g_fOverHeal = cOverHeal.FloatValue;
	g_bHealBots = cHealBots.BoolValue;
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	CreateRegenTimer(g_fHealDelay);
}

void Regen(int tank)
{
	int HP, MaxHP;
	HP = GetEntProp(tank, Prop_Data, "m_iHealth");
	MaxHP = GetEntProp(tank, Prop_Data, "m_iMaxHealth");
	int HPToRegen = RoundToNearest(MaxHP / g_fDivisionQuotient);
	if (HP < MaxHP * g_fOverHeal)
	{
		HP += HPToRegen;
		SetEntData(tank, OffsetHealth, HP);
	}
}

public Action RegenTank(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!L4D2_IsTankInPlay())
			break;

		if (!IsClientInGame(i))
			continue;

		if (!g_bHealBots && IsFakeClient(i))
			continue;

		if (IsTank(i) && GetClientTeam(i) == TEAM_INFECTED && IsPlayerAlive(i) && !L4D_IsPlayerIncapacitated(i))
			Regen(i);
	}
	return Plugin_Continue;
}

void CreateRegenTimer(float delay)
{
	if (!Once)
	{
		RegenTimer = CreateTimer(delay, RegenTank, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		Once = true;
	}
}
void KillRegenTimer()
{
	if (RegenTimer != INVALID_HANDLE)
	{
		KillTimer(RegenTimer);
		RegenTimer = null;
		Once = false;
	}
}
public void OnMapEnd()
{
	KillRegenTimer();
}

public void round_end(Event hEvent, const char[] name, bool DontBroadcast)
{
	KillRegenTimer();
}