#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.1"

#define SOUND_HEARTBEAT     "player/heartbeatloop.wav"

ConVar TIME;
Handle TIMER = INVALID_HANDLE;

ConVar  g_hCvarSlowdown , g_hCvar1Down;

public Plugin myinfo = 
{
	name = "1 HP Gamemode",
	author = "Shadow",
	description = "Makes all player have 1 HP",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
    g_hCvar1Down = FindConVar("survivor_max_incapacitated_count");
    g_hCvarSlowdown = FindConVar("survivor_limp_health");

    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("survivor_rescued", Event_SurvivorRescuedPre, EventHookMode_Pre);
    HookEvent("survivor_rescued", Event_SurvivorRescuedPost);
	HookEvent("round_start",  Event_RoundStart);

    TIME = CreateConVar("hoe_1hp_timer", "2", "How long to reset the hp of all survivors");
    TIME.AddChangeHook(OnCvarChange);
}

public Event_RoundStart(Handle:event, String:event_name[], bool:dontBroadcast) {

    CreateTimer(1.0, TimerLeftSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);    
    
}

public void OnCvarChange(ConVar convar, char[] oldValue, char[] newValue)
{
    if (convar == TIME)
    {
        KillTimer(TIMER);
        TIMER = CreateTimer(1.0 * GetConVarInt(TIME), DisplayPublicity,_, TIMER_REPEAT);
    }
}

public void OnMapStart(){

TIMER = CreateTimer(1.0 * GetConVarInt(TIME), DisplayPublicity,_, TIMER_REPEAT);

}

public void OnMapEnd(){

KillTimer(TIMER);

}

Action Event_SurvivorRescuedPre(Event event, const char[] name, bool dontBroadcast)
{
    int UserId = event.GetInt("userid");
    int client = GetClientOfUserId(UserId);
    
    if ( IsClientInGame(client) && (GetClientTeam(client) == 2) && IsPlayerAlive(client))
    {

    SetEntPropEx(client, Prop_Send, "m_iMaxHealth", 1);
    SetEntPropEx(client, Prop_Send, "m_iHealth", 1);
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0);
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", 0.0);
    SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);

    StopHeartBeat(client);
        
    }

    return Plugin_Continue;
}

Action Event_SurvivorRescuedPost(Event event, const char[] name, bool dontBroadcast)
{
    int UserId = event.GetInt("userid");
    int client = GetClientOfUserId(UserId);
    
    if ( IsClientInGame(client) && (GetClientTeam(client) == 2) && IsPlayerAlive(client))
    {

    SetEntPropEx(client, Prop_Send, "m_iMaxHealth", 1);
    SetEntPropEx(client, Prop_Send, "m_iHealth", 1);
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0);
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", 0.0);
    SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);

    StopHeartBeat(client);
        
    }

    return Plugin_Continue;
}


public Action:TimerLeftSafeRoom(Handle:timer) {

    if (LeftStartArea()) 
    { 
        SetSurvivorHealthCount();
        g_hCvar1Down.SetInt(1, true, true);
        g_hCvarSlowdown.SetInt(1, true, true);
    }
    else
    {
        CreateTimer(1.0, TimerLeftSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);
    }
    
}

public Action DisplayPublicity(Handle timer) {
    SetSurvivorHealthCount();
}

stock SetSurvivorHealthCount() {
            
for (new client = 1; client <= MaxClients; client++)
{
    if (GetClientTeam(client) == 2) {
    SetEntPropEx(client, Prop_Send, "m_iMaxHealth", 1);
    SetEntPropEx(client, Prop_Send, "m_iHealth", 1);
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0);
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", 0.0);
    SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
    StopHeartBeat(client);  
    }
}

}

stock bool:LeftStartArea() {

    new maxents = GetMaxEntities();
    
    for (new i = MaxClients + 1; i <= maxents; i++)
    {
        if (IsValidEntity(i))
        {
            decl String:netclass[64];
            
            GetEntityNetClass(i, netclass, sizeof(netclass));
            
            if (StrEqual(netclass, "CTerrorPlayerResource"))
            {
                if (GetEntProp(i, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
                {
                    return true;
                }
            }
        }
    }
    
    return false;
}

void SetEntPropEx(int entity, PropType type, const char[] prop, any value, int size = 4, int element = 0)
{
    if(HasEntProp(entity, type, prop)) SetEntProp(entity, type, prop, value, size, element);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int UserId = event.GetInt("userid");
    int client = GetClientOfUserId(UserId);
    
    if ( IsClientInGame(client) && (GetClientTeam(client) == 2) && IsPlayerAlive(client))
    {

    SetEntPropEx(client, Prop_Send, "m_iMaxHealth", 1);
    SetEntPropEx(client, Prop_Send, "m_iHealth", 1);
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0);
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", 0.0);
    SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);

    StopHeartBeat(client);
        
    }

    return Plugin_Continue;
}

void StopHeartBeat(int client) {

    StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
    StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
    StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
    StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
}