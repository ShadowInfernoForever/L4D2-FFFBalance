#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo =
{
    name = "[L4D/L4D2] Common Infected Damage by Difficulty",
    author = "Lux (modificado por Shadow)",
    description = "Modifica el daño de los infectados comunes según la dificultad.",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/id/ArmonicJourney"
};

new Handle:hCvar_DmgEnable;
new Handle:hCvar_DmgEasy;
new Handle:hCvar_DmgNormal;
new Handle:hCvar_DmgHard;
new Handle:hCvar_DmgExpert;
new Handle:hCvar_IncapMulti;

new bool:g_DmgEnable;
new Float:g_iDamage;
new Float:g_iImultiplyer;

public OnPluginStart()
{
    hCvar_DmgEnable = CreateConVar("nb_damage_enable", "1", "Modificar el dmg de los infectados comunes", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    hCvar_DmgEasy = CreateConVar("nb_damage_easy", "1.0", "dmg en dificultad Easy", FCVAR_NOTIFY);
    hCvar_DmgNormal = CreateConVar("nb_damage_normal", "2.0", "dmg en dificultad Normal", FCVAR_NOTIFY);
    hCvar_DmgHard = CreateConVar("nb_damage_hard", "5.0", "dmg en dificultad Advanced", FCVAR_NOTIFY);
    hCvar_DmgExpert = CreateConVar("nb_damage_expert", "9.0", "dmg en dificultad Expert", FCVAR_NOTIFY);

    hCvar_IncapMulti = CreateConVar("nb_damage_modifier", "1.0", "Multiplicador de dmg si el survivor esta incapacitado", FCVAR_NOTIFY, true, 0.0, true, 9999.0);

    HookConVarChange(hCvar_DmgEnable, eConvarChanged);
    HookConVarChange(hCvar_IncapMulti, eConvarChanged);
    HookConVarChange(hCvar_DmgEasy, eConvarChanged);
    HookConVarChange(hCvar_DmgNormal, eConvarChanged);
    HookConVarChange(hCvar_DmgHard, eConvarChanged);
    HookConVarChange(hCvar_DmgExpert, eConvarChanged);
    HookConVarChange(FindConVar("z_difficulty"), eConvarChanged);

    HookPlayersDamage();
}

public OnMapStart()
{
	HookPlayersDamage();
    CvarsChanged();
}

public eConvarChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
    CvarsChanged();
}

void CvarsChanged()
{
    g_DmgEnable = GetConVarInt(hCvar_DmgEnable) > 0;
    g_iImultiplyer = GetConVarFloat(hCvar_IncapMulti);

    char sDifficulty[16];
    GetConVarString(FindConVar("z_difficulty"), sDifficulty, sizeof(sDifficulty));

    if (StrEqual(sDifficulty, "Easy", false))
        g_iDamage = GetConVarFloat(hCvar_DmgEasy);
    else if (StrEqual(sDifficulty, "Normal", false))
        g_iDamage = GetConVarFloat(hCvar_DmgNormal);
    else if (StrEqual(sDifficulty, "Hard", false))
        g_iDamage = GetConVarFloat(hCvar_DmgHard);
    else if (StrEqual(sDifficulty, "Impossible", false)) // Expert = Impossible
        g_iDamage = GetConVarFloat(hCvar_DmgExpert);
    else
        g_iDamage = 2.0; // Fallback
}

void HookPlayersDamage()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_OnTakeDamage, eOnTakeDamage);
        }
    }
}

public OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, eOnTakeDamage);
}

public Action:eOnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
    if (!g_DmgEnable)
        return Plugin_Continue;

    if (!IsClientInGame(iVictim) || GetClientTeam(iVictim) != 2)
        return Plugin_Continue;

    char sClassName[32];
    if (!IsValidEntity(iAttacker)) return Plugin_Continue;

    GetEntityClassname(iAttacker, sClassName, sizeof(sClassName));
    if (sClassName[0] != 'i' || !StrEqual(sClassName, "infected"))
        return Plugin_Continue;

    if (IsSurvivorIncapacitated(iVictim))
    {
        fDamage = (g_iDamage * g_iImultiplyer);
        return Plugin_Changed;
    }
    else
    {
        fDamage = g_iDamage;
        return Plugin_Changed;
    }
}

bool IsSurvivorIncapacitated(int client)
{
    return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0;
}
