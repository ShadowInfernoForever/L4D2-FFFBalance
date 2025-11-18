#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME     "Military Sniper Fix"
#define PLUGIN_PREFIX   "SniperFix"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = "little_froy",
    description = "game play",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=345771"
};

Action on_take_damage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if (damage >= 1.0 && weapon != -1 && attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsPlayerAlive(attacker))
    {
        char weaponClass[64];
        GetEntityClassname(weapon, weaponClass, sizeof(weaponClass));
        
        if (StrEqual(weaponClass, "weapon_sniper_military")) // Sniper militar
        {
            char victimClass[64];
            GetEntityClassname(victim, victimClass, sizeof(victimClass));
            
            if (StrEqual(victimClass, "infected"))
            {
                damage = 1.0; // Infectados comunes reciben 1.0x daño
            }
            else
            {
                damage *= 0.5; // Todo lo demás recibe la mitad de daño
                if (damage < 1.0) damage = 1.0; // No permitir daño menor a 1.0
            }
            return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 1) return;
    SDKHook(entity, SDKHook_OnTakeDamage, on_take_damage);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, on_take_damage);
}