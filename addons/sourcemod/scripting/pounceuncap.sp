#include <sourcemod>

#define PLUGIN_VERSION "1.2"

// Globals
new Handle:hMaxPounceDmg;
new Handle:hMinPounceDist;
new Handle:hMaxPounceDist;
new Handle:hPounceDmg;

public Plugin:myinfo = 
{
    name = "PounceUncap",
    author = "n0limit",
    description = "Makes it easy to properly uncap hunter pounces",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=96546"
}

public OnPluginStart()
{
    // Get relevant cvars or Create custom ConVars if they do not exist
     hMaxPounceDmg = FindConVar("z_hunter_max_pounce_bonus_damage");
    if (hMaxPounceDmg == INVALID_HANDLE)
    {
        hMaxPounceDmg = CreateConVar("z_hunter_max_pounce_bonus_damage", "49", "Maximum hunter pounce damage.", FCVAR_ARCHIVE, true, 0.0, false, 0.0);
    }

    hMaxPounceDist = FindConVar("z_pounce_damage_range_max");
    if (hMaxPounceDist == INVALID_HANDLE)
    {
        hMaxPounceDist = CreateConVar("z_pounce_damage_range_max", "300", "Maximum range for pounce damage.", FCVAR_ARCHIVE, true, 100.0, false, 10000.0);
    }

    hMinPounceDist = FindConVar("z_pounce_damage_range_min");
    if (hMinPounceDist == INVALID_HANDLE)
    {
        hMinPounceDist = CreateConVar("z_pounce_damage_range_min", "1729.1666", "Minimum range for pounce damage.", FCVAR_ARCHIVE, true, 50.0, false, 1000.0);
    }
    
    // Ensure all ConVars are valid before proceeding
    if (hMaxPounceDmg == INVALID_HANDLE || hMaxPounceDist == INVALID_HANDLE || hMinPounceDist == INVALID_HANDLE)
    {
        PrintToServer("Error: One or more ConVars could not be found.");
        return;
    }
    
    // Create convar to set
    hPounceDmg = CreateConVar("pounceuncap_maxdamage", "25", "Sets the new maximum hunter pounce damage.", FCVAR_PLUGIN, true, 2.0);
    CreateConVar("pounceuncap_version", PLUGIN_VERSION, "Current version of the plugin", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);
    
    // Hook changes to the convar
    if (hPounceDmg != INVALID_HANDLE)
        HookConVarChange(hPounceDmg, OnMaxDamageChange);
    
    // Save to config
    AutoExecConfig(true, "pounceuncap");
    
    // Fix for reloads
    new String:newVal[10];
    GetConVarString(hPounceDmg, newVal, sizeof(newVal));
    ChangeDamage(newVal);  // Pass the string value, not the handle
}

public OnMaxDamageChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    ChangeDamage(newVal);  // Pass the string value, not the handle
}

ChangeDamage(const String:newVal[]) 
{
    new dmg = StringToInt(newVal, 10);
    new dist;
    
    // 1 pounce damage per 28 in-game units
    dist = 28 * dmg + GetConVarInt(hMinPounceDist);
    SetConVarInt(hMaxPounceDist, dist);
    
    // Always set minus 1, game adds 1 when dist >= range_max
    SetConVarInt(hMaxPounceDmg, --dmg);
}
