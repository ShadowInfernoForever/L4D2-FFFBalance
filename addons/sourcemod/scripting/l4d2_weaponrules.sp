/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
	All trademarks are property of their respective owners.
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define DEBUG 0

int
	g_GlobalWeaponRules[WEPID_SIZE] = {-1, ...},
	g_GlobalWeaponChance[WEPID_SIZE],
	g_bRoundStartHit,
	g_bConfigsExecuted,
	g_GlobalWeaponCap[WEPID_SIZE];

// Variable global para mantener el estado del generador aleatorio
int g_iRandomSeed = 0;

public Plugin myinfo =
{
	name = "L4D2 Weapon Rules (Versus Balanced)",
	author = "ProdigySim (Modified for Melee & Versus Consistency)",
	version = "1.1.1",
	description = "Weapon rules with consistent RNG seeds for Versus rounds",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	RegServerCmd("l4d2_addweaponrule", AddWeaponRuleCb);
	RegServerCmd("l4d2_resetweaponrules", ResetWeaponRulesCb);
	
	HookEvent("round_start", RoundStartCb, EventHookMode_PostNoCopy);
	
	ResetWeaponRules();
}

Action ResetWeaponRulesCb(int args)
{
	ResetWeaponRules();
	return Plugin_Handled;
}

void ResetWeaponRules()
{
	for (int i = 0; i < WEPID_SIZE; i++) {
		g_GlobalWeaponRules[i] = -1;
		g_GlobalWeaponChance[i] = 100;
		g_GlobalWeaponCap[i] = 100;
	}
}

void RoundStartCb(Event hEvent, const char[] eName, bool dontBroadcast)
{
	CreateTimer(0.3, RoundStartDelay, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapStart()
{
	g_bRoundStartHit = false;
	g_bConfigsExecuted = false;
}

public void OnConfigsExecuted()
{
	g_bConfigsExecuted = true;
	
	if (g_bRoundStartHit) {
		WeaponSearchLoop();
	}
}

Action RoundStartDelay(Handle hTimer)
{
	g_bRoundStartHit = true;
	
	if (g_bConfigsExecuted) {
		WeaponSearchLoop();
	}

	return Plugin_Stop;
}

Action AddWeaponRuleCb(int args)
{
	if (args < 2) {
		PrintToServer("Usage: l4d2_addweaponrule <match> <replace> [chance] [cap]");
		return Plugin_Handled;
	}

	char weaponbuf[64];

	GetCmdArg(1, weaponbuf, sizeof(weaponbuf));
	int match = WeaponNameToId2(weaponbuf);

	GetCmdArg(2, weaponbuf, sizeof(weaponbuf));
	int to = WeaponNameToId2(weaponbuf);

	int chance = 100;
	int cap = 100;

	if (args >= 3) {
		char buf[8];
		GetCmdArg(3, buf, sizeof(buf));
		chance = StringToInt(buf);
	}

	if (args >= 4) {
		char buf[8];
		GetCmdArg(4, buf, sizeof(buf));
		cap = StringToInt(buf);
	}

	// clamp
	if (chance < 0) chance = 0;
	if (chance > 100) chance = 100;

	if (cap < 0) cap = 0;
	if (cap > 100) cap = 100;

	AddWeaponRule(match, to, chance, cap);

	return Plugin_Handled;
}

void AddWeaponRule(int match, int to, int chance, int cap)
{
	if (IsValidWeaponId(match) && (to == -1 || IsValidWeaponId(to))) {
		g_GlobalWeaponRules[match] = to;
		g_GlobalWeaponChance[match] = chance;
		g_GlobalWeaponCap[match] = cap;
	}
}

int WeaponNameToId2(const char[] name)
{
	if (StrEqual(name, "melee", false) || StrEqual(name, "weapon_melee", false)) {
		return WEPID_MELEE;
	}

	char namebuf[64] = "weapon_";
	int wepid = WeaponNameToId(name);
	
	if (wepid == WEPID_NONE) {
		strcopy(namebuf[7], sizeof(namebuf) - 7, name);
		wepid = WeaponNameToId(namebuf);
	}

	return wepid;
}

// Inicializa la semilla determinista basada en el mapa
void InitMapSeed()
{
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	
	int seed = 0;
	for (int i = 0; mapname[i] != '\0'; i++) {
		seed = seed * 31 + mapname[i];
	}
	g_iRandomSeed = (seed < 0) ? -seed : seed;
}

// Generador de números aleatorios consistente entre rondas
int GetCustomRandomInt(int min, int max)
{
	g_iRandomSeed = (g_iRandomSeed * 1103515245 + 12345) & 0x7fffffff;
	return min + (g_iRandomSeed % (max - min + 1));
}

void WeaponSearchLoop()
{
	// Reiniciar la semilla exactamente igual en ambas rondas del mapa
	InitMapSeed();

	int entcnt = GetEntityCount();

	int count[WEPID_SIZE];
	int replaced[WEPID_SIZE];

	// init
	for (int i = 0; i < WEPID_SIZE; i++) {
		count[i] = 0;
		replaced[i] = 0;
	}

	for (int ent = 1; ent <= entcnt; ent++) {
		int source = IdentifyWeapon(ent);

		if (source > WEPID_NONE && g_GlobalWeaponRules[source] != -1) {
			count[source]++;
		}
	}

	for (int ent = 1; ent <= entcnt; ent++) {
		int source = IdentifyWeapon(ent);

		if (source > WEPID_NONE && g_GlobalWeaponRules[source] != -1) {

			int roll = GetCustomRandomInt(1, 100);
			if (roll > g_GlobalWeaponChance[source]) {
				continue;
			}

			int maxReplace = RoundToFloor(float(count[source]) * g_GlobalWeaponCap[source] / 100.0);

			if (replaced[source] >= maxReplace) {
				continue;
			}

			if (g_GlobalWeaponRules[source] == WEPID_NONE) {
				AcceptEntityInput(ent, "kill");
			} else {
				ConvertWeaponSpawn(ent, g_GlobalWeaponRules[source]);
			}

			replaced[source]++;
		}
	}
}