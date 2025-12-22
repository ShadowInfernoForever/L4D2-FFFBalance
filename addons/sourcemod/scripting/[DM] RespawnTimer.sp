#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define TEAM_SURVIVOR 2

#define MIN_DIST 300.0       // Distancia mínima del survivor más cercano
#define MAX_DIST 1200.0      // Distancia máxima permitida
#define MAX_ATTEMPTS 15      // Intentos de respawn aceptable

public Plugin myinfo =
{
    name = "[DM] RespawnTimer",
    author = "Shadow",
    description = "Deathmatch autorespawn con distancia aleatoria.",
    version = "1.6"
};

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!client || !IsClientInGame(client))
        return;

    PrintHintText(client, "[DM] Respawn en 3 segundos...");
    CreateTimer(3.0, Timer_RespawnPlayer, GetClientUserId(client));
}

public Action Timer_RespawnPlayer(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!client || !IsClientInGame(client))
        return Plugin_Stop;

    L4D_RespawnPlayer(client);

    int target = FindClosestSurvivor(client);
    if (!target)
    {
        PrintHintText(client, "[DM] No hay survivors vivos!");
        return Plugin_Stop;
    }

    float tpos[3];
    GetClientAbsOrigin(target, tpos);

    float spawnPos[3];
    float dist;

    // Distancia aleatoria en cada respawn
    float desiredDist = GetRandomFloat(MIN_DIST, MAX_DIST);

    bool ok = false;

    for (int i = 0; i < MAX_ATTEMPTS; i++)
    {
        if (L4D_GetRandomPZSpawnPosition(client, 8, 25, spawnPos))
        {
            dist = GetVectorDistance(tpos, spawnPos);

            if (dist >= MIN_DIST && dist <= desiredDist)
            {
                ok = true;
                break;
            }
        }
    }

    if (!ok)
    {
        PrintHintText(client, "[DM] No se encontró spawn ideal, usando el último intento.");
    }

    spawnPos[2] += 10.0;
    TeleportEntity(client, spawnPos, NULL_VECTOR, NULL_VECTOR);

    //# Warp them to a safety location if stuck
    L4D_WarpToValidPositionIfStuck(client);

    GiveRandomLoadout(client);

    PrintHintText(client, "[DM] Respawn completado!");

    return Plugin_Stop;
}

int FindClosestSurvivor(int client)
{
    float cpos[3];
    GetClientAbsOrigin(client, cpos);

    float bestDist = 999999.0;
    int best = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
        if (GetClientTeam(i) != TEAM_SURVIVOR) continue;

        float spos[3];
        GetClientAbsOrigin(i, spos);

        float dist = GetVectorDistance(cpos, spos);
        if (dist < bestDist)
        {
            bestDist = dist;
            best = i;
        }
    }
    return best;
}

char primaryWeapons[][] =
{
    "weapon_smg",
    "weapon_smg_silenced",
    "weapon_smg_mp5",

    "weapon_pumpshotgun",
    "weapon_shotgun_chrome",

    "weapon_rifle",
    "weapon_rifle_ak47",
    "weapon_rifle_desert",
    "weapon_rifle_sg552",

    "weapon_autoshotgun",
    "weapon_shotgun_spas",

    "weapon_hunting_rifle",
    "weapon_sniper_military",
    "weapon_sniper_scout",
    "weapon_sniper_awp"
};

char secondaryWeapons[][] =
{
    "weapon_pistol",
    "weapon_pistol_magnum",
    "chainsaw",
    "cricket_bat",
    "fireaxe",
    "knife",
    "machete",
    "katana",
    "baseball_bat",
    "crowbar",
    "golfclub",
    "frying_pan",
    "tonfa"
};

char heals[][] =
{
	"upgradepack_explosive",
	"upgradepack_incendiary",
    "first_aid_kit",
    "pain_pills",
    "adrenaline"
};

char utilities[][] =
{
	"gascan",
	"propanetank",
	"oxygentank",
	"fireworkcrate",
    "molotov",
    "pipe_bomb",
    "vomitjar"
};

void GiveRandomLoadout(int client)
{
    if (!IsClientInGame(client)) return;

    // --- Limpiar inventario ---
    StripWeapons(client);

    // --- Primaria ---
    int idx = GetRandomInt(0, sizeof(primaryWeapons) - 1);
    GivePlayerItem(client, primaryWeapons[idx]);

    // --- Secundaria ---
    idx = GetRandomInt(0, sizeof(secondaryWeapons) - 1);
    GivePlayerItem(client, secondaryWeapons[idx]);

    // --- Heal ---
    idx = GetRandomInt(0, sizeof(heals) - 1);
    GivePlayerItem(client, heals[idx]);

    // --- Utilidad ---
    idx = GetRandomInt(0, sizeof(utilities) - 1);
    GivePlayerItem(client, utilities[idx]);
}

void StripWeapons(int client)
{
    int weapon;
    for (int i = 0; i < 5; i++)
    {
        while ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
        {
            RemovePlayerItem(client, weapon);
            RemoveEdict(weapon);
        }
    }
}