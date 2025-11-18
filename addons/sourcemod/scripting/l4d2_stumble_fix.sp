#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_shoved", Event_PlayerShoved);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("boomer_exploded", Event_BoomerExploded);
    HookEvent("charger_charge_end", Event_ChargerChargeEnd);
}

enum struct PlayerData
{
    int StagStage;
    int StagCounter;
    int StagCounter2;
}

PlayerData g_PlayerData[MAXPLAYERS + 1];

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client > 0)
    {
        g_PlayerData[client].StagStage = 3;
        g_PlayerData[client].StagCounter = 0;
        g_PlayerData[client].StagCounter2 = 0;
    }
}

public void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    if (victim > 0 && attacker > 0 && GetEntProp(victim, Prop_Send, "m_zombieClass") < 6)
    {
        if (g_PlayerData[victim].StagStage == 3)
        {
            g_PlayerData[victim].StagStage = 0;
            g_PlayerData[victim].StagCounter++;
            CreateTimer(0.03, Timer_RFFallStagger, victim, TIMER_FLAG_NO_MAPCHANGE);
            CreateTimer(GetConVarFloat(FindConVar("z_max_stagger_duration")), Timer_StagLoopFix, victim, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    if (victim > 0 && !IsPlayerAlive(victim) && GetEntPropFloat(victim, Prop_Send, "m_staggerTimer") > -1.0)
    {
        if (g_PlayerData[victim].StagStage == 3)
        {
            g_PlayerData[victim].StagStage = 0;
            g_PlayerData[victim].StagCounter++;
            CreateTimer(GetConVarFloat(FindConVar("z_max_stagger_duration")), Timer_StagLoopFix, victim, TIMER_FLAG_NO_MAPCHANGE);
            CreateTimer(0.03, Timer_RFFallStagger, attacker > 0 ? attacker : victim, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public void Event_BoomerExploded(Event event, const char[] name, bool dontBroadcast)
{
    int userid = GetEventInt(event, "userid");
    int boomer = GetClientOfUserId(userid);
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsPlayerAlive(i) && GetEntPropFloat(i, Prop_Send, "m_staggerTimer") > -1.0)
        {
            if (g_PlayerData[i].StagStage == 3)
            {
                g_PlayerData[i].StagStage = 0;
                g_PlayerData[i].StagCounter++;
                CreateTimer(0.03, Timer_RFFallStagger, boomer, TIMER_FLAG_NO_MAPCHANGE);
                CreateTimer(GetConVarFloat(FindConVar("z_max_stagger_duration")), Timer_StagLoopFix, i, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

public void Event_ChargerChargeEnd(Event event, const char[] name, bool dontBroadcast)
{
    int charger = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (charger > 0 && GetEntPropFloat(charger, Prop_Send, "m_staggerTimer") > -1.0)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (i != charger && IsClientInGame(i) && !IsPlayerAlive(i))
            {
                if (g_PlayerData[i].StagStage == 3)
                {
                    g_PlayerData[i].StagStage = 0;
                    g_PlayerData[i].StagCounter++;
                    CreateTimer(0.03, Timer_RFFallStagger, charger, TIMER_FLAG_NO_MAPCHANGE);
                    CreateTimer(GetConVarFloat(FindConVar("z_max_stagger_duration")), Timer_StagLoopFix, i, TIMER_FLAG_NO_MAPCHANGE);
                }
            }
        }
    }
}

public Action Timer_RFFallStagger(Handle timer, any client)
{
    if (client > 0 && IsClientInGame(client))
    {
        if (!IsPlayerAlive(client) || g_PlayerData[client].StagStage == 3)
        {
            g_PlayerData[client].StagStage = 3;
        }
        else if (GetEntPropFloat(client, Prop_Send, "m_staggerTimer") > -1.0)
        {
            g_PlayerData[client].StagStage = 0;
            CreateTimer(0.03, Timer_RFFallStagger, client, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    return Plugin_Continue;
}

public Action Timer_StagLoopFix(Handle timer, any client)
{
    if (client > 0 && IsClientInGame(client))
    {
        g_PlayerData[client].StagCounter2++;
        if (g_PlayerData[client].StagCounter2 == g_PlayerData[client].StagCounter)
        {
            g_PlayerData[client].StagStage = 3;
            g_PlayerData[client].StagCounter = 0;
            g_PlayerData[client].StagCounter2 = 0;
        }
    }
    return Plugin_Continue;
}
