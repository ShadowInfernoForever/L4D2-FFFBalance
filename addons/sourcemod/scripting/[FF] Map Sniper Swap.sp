#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2util_weapons>

// Define custom constants
#define WEPID_NONE -1
#define WEAPON_SCOUT 36
#define WEAPON_AWP 35

public Plugin myinfo = 
{
    name = "Weapon Swap",
    author = "Shadow",
    description = "Swaps hunting rifle and military sniper with scout and AWP respectively based on percentages",
    version = "1.2",
    url = ""
};

// CVARs for configurable percentages
ConVar g_huntingToScoutChance;
ConVar g_militaryToAwpChance;

// Initialize CVARs
public void OnPluginStart()
{
    g_huntingToScoutChance = CreateConVar("l4d2_weapon_swap_hunting_scout_chance", "50.0", "Chance to replace hunting rifle with scout (0-100)", FCVAR_PLUGIN, true, 0.0, true, 100.0);
    g_militaryToAwpChance = CreateConVar("l4d2_weapon_swap_military_awp_chance", "50.0", "Chance to replace military sniper with AWP (0-100)", FCVAR_PLUGIN, true, 0.0, true, 100.0);

    HookEvent("round_start", OnRoundStart, EventHookMode_Post);
}

// Triggered on round start
public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    CreateTimer(1.0, Timer_ReplaceWeapons);
    return Plugin_Continue;
}

// Timer callback to replace weapons
public Action Timer_ReplaceWeapons(Handle timer)
{
    ReplaceWeapons("weapon_spawn", WEAPON_SCOUT, "models/w_models/weapons/w_sniper_scout.mdl", g_huntingToScoutChance.FloatValue);
    ReplaceWeapons("weapon_hunting_rifle", WEAPON_SCOUT, "models/w_models/weapons/w_sniper_scout.mdl", g_huntingToScoutChance.FloatValue);
    ReplaceWeapons("weapon_hunting_rifle_spawn", WEAPON_SCOUT, "models/w_models/weapons/w_sniper_scout.mdl", g_huntingToScoutChance.FloatValue);
    ReplaceWeapons("weapon_spawn", WEAPON_AWP, "models/w_models/weapons/w_sniper_awp.mdl", g_militaryToAwpChance.FloatValue);
    ReplaceWeapons("weapon_military_sniper", WEAPON_AWP, "models/w_models/weapons/w_sniper_awp.mdl", g_militaryToAwpChance.FloatValue);
    ReplaceWeapons("weapon_military_sniper_spawn", WEAPON_AWP, "models/w_models/weapons/w_sniper_awp.mdl", g_militaryToAwpChance.FloatValue);
    return Plugin_Stop;
}

// Function to replace weapons using IdentifyWeapon
void ReplaceWeapons(const char[] className, int newWeaponId, const char[] newModel, float chance)
{
    int entity = -1;

    // Loop through all entities of the specified type
    while ((entity = FindEntityByClassname(entity, className)) != -1)
    {
        int weaponID = IdentifyWeapon(entity);
        if (weaponID == WEPID_NONE)
        {
            continue; // Skip invalid weapon entities
        }

        // Determine replacement criteria based on weapon type
        if ((weaponID == 6 && newWeaponId == WEAPON_SCOUT) || // Hunting Rifle to Scout
            (weaponID == 10 && newWeaponId == WEAPON_AWP))    // Military Sniper to AWP
        {
            float randValue = GetRandomFloat(0.0, 100.0);
            if (randValue <= chance)
            {
                ConvertWeaponSpawn(entity, newWeaponId, 5, newModel);
            }
        }
    }
}