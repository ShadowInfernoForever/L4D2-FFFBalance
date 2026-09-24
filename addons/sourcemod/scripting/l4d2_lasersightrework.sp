#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "5.0.0"
#define UPGRADE_LASER_SIGHT (1 << 2)
#define TEAM_SURVIVORS 2

ConVar g_hCvarAllow;
ConVar g_hCvarMultiplier;

public Plugin myinfo =
{
    name = "[L4D2] Laser Sight Box & Direct Bit Manipulation",
    author = "Shadow & little_froy",
    description = "Manages infinite laser box toggling directly via upgradeBitVec.",
    version = PLUGIN_VERSION,
    url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in Left 4 Dead 2.");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_hCvarAllow = CreateConVar("l4d2_laser_nerf_allow", "1", "Enable laser ammo nerf plugin (1=Yes, 0=No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarMultiplier = CreateConVar("l4d2_laser_ammo_multiplier", "0.5", "Max reserve ammo multiplier with laser (0.5 = 50% less)", FCVAR_NOTIFY, true, 0.1, true, 1.0);

    AutoExecConfig(true, "l4d2_laser_ammo_nerf");

    HookEvent("weapon_reload", Event_CheckLaserAmmo);
    HookEvent("player_use", Event_PlayerUse);

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            OnClientPutInServer(client);
        }
    }
    PrintToServer("[DEBUG_BOX] Plugin loaded and active.");
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (IsValidEntity(entity))
    {
        if (StrEqual(classname, "upgrade_laser_sight"))
        {
            SDKHook(entity, SDKHook_SpawnPost, OnPostLaserSpawn);
        }
    }
}

public void OnPostLaserSpawn(int entity)
{
    if (IsValidEntity(entity))
    {
        SDKHook(entity, SDKHook_Use, OnLaserBoxUse);
    }
}

public Action OnLaserBoxUse(int entity, int activator, int caller, UseType type, float value)
{
    if (!g_hCvarAllow.BoolValue) return Plugin_Continue;

    if (activator <= 0 || activator > MaxClients || !IsClientInGame(activator))
        return Plugin_Continue;

    if (GetClientTeam(activator) != TEAM_SURVIVORS)
        return Plugin_Continue;

    int weapon = GetPlayerWeaponSlot(activator, 0);
    if (weapon == -1 || !IsValidEntity(weapon) || IsExcludedWeapon(weapon))
        return Plugin_Continue;

    if (HasEntProp(entity, Prop_Data, "m_iUsedCount"))
    {
        SetEntProp(entity, Prop_Data, "m_iUsedCount", 0);
    }

    if (!HasEntProp(weapon, Prop_Send, "m_upgradeBitVec"))
        return Plugin_Continue;

    int upgradeBits = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
    bool hasLaser = (upgradeBits & UPGRADE_LASER_SIGHT) != 0;

    int maxDefaultAmmo = GetWeaponDefaultMaxAmmo(weapon);

    if (hasLaser)
    {
        SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgradeBits & ~UPGRADE_LASER_SIGHT);

        if (maxDefaultAmmo > 0)
        {
            L4D_SetReserveAmmo(activator, weapon, maxDefaultAmmo);
        }
        PrintToChat(activator, "[LaserBox] Laser removed. Ammo restored.");
    }
    else
    {
        SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgradeBits | UPGRADE_LASER_SIGHT);

        if (maxDefaultAmmo > 0)
        {
            int targetMax = RoundToFloor(maxDefaultAmmo * g_hCvarMultiplier.FloatValue);
            L4D_SetReserveAmmo(activator, weapon, targetMax);
        }
        PrintToChat(activator, "[LaserBox] Laser equipped! Ammo adjusted.");
    }

    return Plugin_Continue;
}

void OnWeaponEquipPost(int client, int weapon)
{
    if(weapon == -1 || GetClientTeam(client) != TEAM_SURVIVORS || !HasEntProp(weapon, Prop_Send, "m_upgradeBitVec"))
        return;

    if (IsExcludedWeapon(weapon)) return;

    char class_name[32];
    GetEntityClassname(weapon, class_name, sizeof(class_name));
    
    if(StrContains(class_name, "weapon_") != -1)
    {
        CheckAndApplyAmmoNerf(client, weapon);
    }
}

public void Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_hCvarAllow.BoolValue) return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    int target = event.GetInt("targetid");

    if (!client || !IsValidEntity(target)) return;

    char classname[64];
    GetEntityClassname(target, classname, sizeof(classname));

    if (StrEqual(classname, "weapon_ammo_spawn"))
    {
        RequestFrame(ApplyAmmoNerfNextFrame, GetClientUserId(client));
    }
}

public void ApplyAmmoNerfNextFrame(any userid)
{
    int client = GetClientOfUserId(userid);
    if (!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVORS) return;

    int weapon = GetPlayerWeaponSlot(client, 0);
    if (weapon != -1 && IsValidEntity(weapon))
    {
        if (!IsExcludedWeapon(weapon))
        {
            CheckAndApplyAmmoNerf(client, weapon);
        }
    }
}

public void Event_CheckLaserAmmo(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_hCvarAllow.BoolValue) return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVORS || IsFakeClient(client))
        return;

    int weapon = GetPlayerWeaponSlot(client, 0);
    if (weapon == -1 || !IsValidEntity(weapon)) return;

    if (IsExcludedWeapon(weapon)) return;

    CheckAndApplyAmmoNerf(client, weapon);
}

void CheckAndApplyAmmoNerf(int client, int weapon)
{
    if (!HasEntProp(weapon, Prop_Send, "m_upgradeBitVec")) return;

    int upgradeBits = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
    
    if (upgradeBits & UPGRADE_LASER_SIGHT)
    {
        int currentReserve = L4D_GetReserveAmmo(client, weapon);
        if (currentReserve <= 0) return;

        int maxDefaultAmmo = GetWeaponDefaultMaxAmmo(weapon);
        if (maxDefaultAmmo <= 0) maxDefaultAmmo = currentReserve;

        int targetMax = RoundToFloor(maxDefaultAmmo * g_hCvarMultiplier.FloatValue);

        if (currentReserve > targetMax)
        {
            L4D_SetReserveAmmo(client, weapon, targetMax);
        }
    }
}

bool IsExcludedWeapon(int weapon)
{
    char classname[32];
    GetEntityClassname(weapon, classname, sizeof(classname));

    if (StrEqual(classname, "weapon_rifle_m60") || StrEqual(classname, "weapon_grenade_launcher"))
        return true;

    return false;
}

stock int GetWeaponDefaultMaxAmmo(int weapon)
{
    char classname[32];
    GetEntityClassname(weapon, classname, sizeof(classname));

    ConVar hCvar = null;

    if (StrEqual(classname, "weapon_rifle") || StrEqual(classname, "weapon_rifle_sg552") || StrEqual(classname, "weapon_rifle_ak47") || StrEqual(classname, "weapon_rifle_desert"))
    {
        hCvar = FindConVar("ammo_assaultrifle_max");
    }
    else if (StrEqual(classname, "weapon_smg") || StrEqual(classname, "weapon_smg_silenced") || StrEqual(classname, "weapon_smg_mp5"))
    {
        hCvar = FindConVar("ammo_smg_max");
    }
    else if (StrEqual(classname, "weapon_autoshotgun") || StrEqual(classname, "weapon_shotgun_spas"))
    {
        hCvar = FindConVar("ammo_autoshotgun_max");
    }
    else if (StrEqual(classname, "weapon_pumpshotgun") || StrEqual(classname, "weapon_shotgun_chrome"))
    {
        hCvar = FindConVar("ammo_shotgun_max");
    }
    else if (StrEqual(classname, "weapon_sniper_military") || StrEqual(classname, "weapon_hunting_rifle"))
    {
        hCvar = FindConVar("ammo_huntingrifle_max");
    }
    else if (StrEqual(classname, "weapon_sniper_awp") || StrEqual(classname, "weapon_sniper_scout"))
    {
        hCvar = FindConVar("ammo_sniperrifle_max");
    }

    if (hCvar != null)
    {
        return hCvar.IntValue;
    }

    return 0;
}