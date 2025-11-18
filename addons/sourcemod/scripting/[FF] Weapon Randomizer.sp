#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
    name = "[FF] Weapon Randomizer",
    author = "ShadowInferno",
    description = "Randomizes weapons in the map",
    version = "1.0",
    url = ""
}

public void OnPluginStart() {
    // Hook the round_start event
    HookEvent("round_start", OnRoundStart);
}

public Action:OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
    // Iterate through all weapon_spawn entities
    int entity = FindEntityByClassname(-1, "weapon_spawn");
    while (entity != 0) {
        // Check if the entity is not an excluded L4D2 item
        char classname[64];
        GetEntPropString(entity, Prop_Data, "m_iClassname", classname, sizeof(classname));
        
        if (StrContains(classname, "weapon_melee") != -1 || 
            StrContains(classname, "weapon_pistol") != -1 ||  // Exclude player pistol
            StrContains(classname, "weapon_primary") != -1 || // Exclude primary weapons
            StrContains(classname, "adrenaline") == -1 &&
            StrContains(classname, "pain_pills") == -1 &&
            StrContains(classname, "pipebomb") == -1 &&
            StrContains(classname, "molotov") == -1 &&
            StrContains(classname, "ammo") == -1 &&
            StrContains(classname, "first_aid_kit") == -1 &&
            StrContains(classname, "defibrillator") == -1 &&
            StrContains(classname, "gascan") == -1 &&
            StrContains(classname, "vomitjar") == -1) {
            entity = FindEntityByClassname(entity, "weapon_spawn"); // Get next weapon_spawn
            continue; // Skip this entity
        }

        // Proceed with weapon randomization
        CreateTimer(1.0, ReplaceWithRandomWeapon_Timer, entity);
        entity = FindEntityByClassname(entity, "weapon_*"); // Get next weapon
    }
    return Plugin_Continue;
}

#define MAX_WEAPONS 16

new String: weaponList[MAX_WEAPONS][64] = {
    "weapon_pistol",
    "weapon_pistol_magnum",
    "weapon_pumpshotgun",
    "weapon_shotgun_chrome",
    "weapon_shotgun_spas",
    "weapon_autoshotgun",
    "weapon_smg",
    "weapon_smg_silenced",
    "weapon_smg_mp5",
    "weapon_rifle",
    "weapon_rifle_ak47",
    "weapon_rifle_desert",
    "weapon_rifle_sg552",
    "weapon_sniper_military",
    "weapon_sniper_awp",
    "weapon_sniper_scout",
};

public Action:ReplaceWithRandomWeapon_Timer(Handle:timer, any:data) {
    int entity = data;

    // Kill the original weapon_spawn
    AcceptEntityInput(entity, "Kill");

    // Select a random weapon from the list
    int randomIndex = GetRandomInt(0, MAX_WEAPONS - 1);
    char newWeapon[64];
    strcopy(newWeapon, sizeof(newWeapon), weaponList[randomIndex]);

    // Create the weapon_spawn entity
    int newEntity = CreateEntityByName("weapon_spawn");

    // Set the weapon_selection keyvalue
    SetEntPropString(newEntity, Prop_Data, "weapon_selection", "any_primary");

    // Get the origin of the original entity
    float origin[3];
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
    TeleportEntity(newEntity, origin, NULL_VECTOR, NULL_VECTOR);
    
    DispatchSpawn(newEntity);
}