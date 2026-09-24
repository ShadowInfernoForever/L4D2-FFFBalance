#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>

float g_fAccumulatedDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_bFramePending[MAXPLAYERS + 1][MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Damage Display (Real Damage)",
    author = "Shadow",
    description = "Displays the real damage dealt by weapons in chat",
    version = "1.4",
    url = ""
};

public void OnPluginStart()
{
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
}

public void OnClientDisconnect(int client)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        g_fAccumulatedDamage[client][i] = 0.0;
        g_fAccumulatedDamage[i][client] = 0.0;
        g_bFramePending[client][i] = false;
        g_bFramePending[i][client] = false;
    }
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    // Obtener el daño real aplicado a la vida
    float damage = float(event.GetInt("dmg_health")); 

    if (victim <= 0 || victim > MaxClients || attacker <= 0 || attacker > MaxClients) return;
    if (victim == attacker) return;

    // Acumular el daño real
    g_fAccumulatedDamage[attacker][victim] += damage;

    if (!g_bFramePending[attacker][victim])
    {
        g_bFramePending[attacker][victim] = true;
        
        DataPack dp;
        CreateDataTimer(0.01, Timer_PrintDamage, dp);
        dp.WriteCell(attacker);
        dp.WriteCell(victim);
    }
}

public Action Timer_PrintDamage(Handle timer, DataPack dp)
{
    dp.Reset();
    int attacker = dp.ReadCell();
    int victim = dp.ReadCell();

    g_bFramePending[attacker][victim] = false;

    if (IsClientInGame(attacker) && IsClientInGame(victim))
    {
        float totalDamage = g_fAccumulatedDamage[attacker][victim];

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
            "{default}➤ {blue}%s {default}dealt {olive}%.0f dmg {default}to %s from {olive}%.0f H/U {default}away", attackerName, totalDamage, victimName, dist
        );

        CPrintToChatAll(msg);
    }

    g_fAccumulatedDamage[attacker][victim] = 0.0;

    return Plugin_Stop;
}

float VectorDistanceHU(float vec1[3], float vec2[3])
{
    float dx = vec1[0] - vec2[0];
    float dy = vec1[1] - vec2[1];
    float dz = vec1[2] - vec2[2];
    return SquareRoot(dx*dx + dy*dy + dz*dz);
}