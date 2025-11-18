#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>

public Plugin myinfo =
{
    name = "Damage Display",
    author = "Shadow",
    description = "Displays the final damage dealt by weapons in chat with colors and distance",
    version = "1.2",
    url = ""
};

public void OnPluginStart()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }

    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsClientInGame(client))
    {
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!IsValidEntity(victim) || !IsValidEntity(attacker)) return Plugin_Continue;
    if (victim == attacker) return Plugin_Continue;

    char victimName[64];
    char attackerName[64];
    GetClientName(attacker, attackerName, sizeof(attackerName));
    GetClientName(victim, victimName, sizeof(victimName));

    float attackerPos[3];
    float victimPos[3];
    GetClientEyePosition(attacker, attackerPos);
    GetClientEyePosition(victim, victimPos);

    float dist = VectorDistanceHU(attackerPos, victimPos);

    char msg[256];
    Format(msg, sizeof(msg),
        "{default}➤ {blue}%s {default}dealt {olive}%.1f dmg {default}to %s from {olive}%.0f H/U {default}away", attackerName, damage, victimName, dist
    );

    CPrintToChatAll(msg);

    return Plugin_Continue;
}
float VectorDistanceHU(float vec1[3], float vec2[3])
{
    float dx = vec1[0] - vec2[0];
    float dy = vec1[1] - vec2[1];
    float dz = vec1[2] - vec2[2];
    return SquareRoot(dx*dx + dy*dy + dz*dz);
}