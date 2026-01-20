#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_NAME_FULL   "[L4D & L4D2] One-Time Ammo Pile for M60"
#define PLUGIN_AUTHOR      "NoroHime, edit by Shadow"
#define PLUGIN_VERSION     "1.1"
#define PLUGIN_DESCRIPTION "Ammo pile can only be used once per player, only for M60."

public Plugin myinfo = 
{
    name        = PLUGIN_NAME_FULL,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION
};

// Limits
#define MAX_ENTS 2048
#define MAX_PLAYERS 32

// Ammo piles state by player
new bool:g_bUsedPile[MAX_PLAYERS+1][MAX_ENTS+1];

public void OnPluginStart()
{
    int entity = -1;
	while ((entity = FindEntityByClassname(entity, "weapon_ammo_spawn")) != -1)
	{
	    if (!IsValidEntity(entity)) continue;
	    if (entity > MAX_ENTS) continue;

	    SDKHook(entity, SDKHook_Use, OnAmmoUse);
	}

    // Reset every round
    HookEvent("round_start", OnRoundStart, EventHookMode_Post);
}

// Hook new created ammo piles
public void OnEntityCreated(int entity, const char[] classname)
{
    if (!IsValidEntity(entity)) return;
    if (!StrEqual(classname, "weapon_ammo_spawn")) return;
    if (entity > MAX_ENTS) return;

    SDKHook(entity, SDKHook_Use, OnAmmoUse);
}

// Hook of the ammo pile use
public Action OnAmmoUse(int entity, int activator, int caller, UseType type, float value)
{
    if (!IsClient(caller) || !IsValidEntity(entity)) return Plugin_Continue;
    if (entity > MAX_ENTS) return Plugin_Continue;

    // Only M60
    int weaponEnt = GetPlayerWeaponSlot(caller, 0);
    if (weaponEnt == -1 || !IsValidEntity(weaponEnt)) return Plugin_Continue;

    char wclass[64];
    GetEntityClassname(weaponEnt, wclass, sizeof(wclass));

    if (!StrEqual(wclass, "weapon_rifle_m60")) return Plugin_Continue;

    // If the player who used the ammo pile, has already used it before
    if (g_bUsedPile[caller][entity])
    {
        EmitSoundToClient(caller, "player/suit_denydevice.wav");
        return Plugin_Handled; // bloquea la entrega
    }

    // Mark as used
    g_bUsedPile[caller][entity] = true;

    return Plugin_Continue;
}

// Reset por round
public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    CreateTimer(1.0, Timer_RestartAmmo);
    return Plugin_Continue;
}

public Action Timer_RestartAmmo(Handle timer)
{
    for (int client = 1; client <= MAX_PLAYERS; client++)
    {
        if (!IsClientInGame(client)) continue;

        for (int e = 1; e <= MAX_ENTS; e++)
            g_bUsedPile[client][e] = false;
    }
    return Plugin_Stop;
}

// Reset if you disconnect
public void OnClientDisconnect(int client)
{
    if (client < 1 || client > MAX_PLAYERS) return;

    for (int e = 1; e <= MAX_ENTS; e++)
        g_bUsedPile[client][e] = false;
}

// Helper
bool IsClient(int c)
{
    return (c >= 1 && c <= MAX_PLAYERS && IsClientInGame(c));
}
