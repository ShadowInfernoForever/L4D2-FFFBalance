// Plugins taken from 
// https://forums.alliedmods.net/showthread.php?p=2753486 special infected spawn on survivor death

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0.0"

#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

#define DAMAGE_EVENTS_ONLY      1       // Call damage functions, but don't modify health
#define DAMAGE_YES              2

public Plugin myinfo =
{
    name = "[L4D2] Infection Gamemode Core",
    author = "Shadow",
    description = "Infection Gamemode Core",
    version = PLUGIN_VERSION,
    url = ""
}

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_incapacitated", Event_PlayerIncapacitated);
    HookEvent("round_start", ResetPlayers);
    HookEvent("round_end", ResetPlayers);
    HookEvent("mission_lost", ResetPlayers);
    
    AutoExecConfig(true, "SpawnSpecialOnSurvivorDeath");
}

public void Event_PlayerIncapacitated(Event event, const char[] szName, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if(!IsValidEntity(victim))
        return;
    if(victim < 1 || victim > MaxClients)
        return;

    if(GetClientTeam(victim) != TEAM_SURVIVORS)
        return;

    if(GetEntProp(victim, Prop_Send, "m_isHangingFromLedge") == 1)
        return;
    
    int damageType = event.GetInt("type");

    // Not drowning and not falling.
    // This is done to prevent special infected from spawning in insta kill areas
    if(damageType != DMG_DROWN && damageType != DMG_FALL)
    {
            float Pos[3];
            GetClientAbsOrigin(victim, Pos);
            SpawnSpecialinfected(Pos, victim);
    }
}

public void Event_PlayerDeath(Event event, const char[] szName, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if(!IsValidEntity(victim))
        return;
    if(victim < 1 || victim > MaxClients)
        return;

    if(GetClientTeam(victim) != TEAM_SURVIVORS)
        return;

    int damageType = event.GetInt("type");

    // Not drowning and not falling
    // This is done to prevent special infected from spawning in insta kill areas
    if(damageType != DMG_DROWN && damageType != DMG_FALL)
    {
            float Pos[3];
            GetClientAbsOrigin(victim, Pos);
            SpawnSpecialinfected(Pos, victim);
    }
}

void SpawnSpecialinfected(float Pos[3], int victim)
{
    float Angle[3];
    int infectedType = GetRandomInt(1, 2); // Only 1 or 2

    switch
    case 1: 
    {
      infectedType = 1;
    }
    case 2: 
    {
      infectedType = 3;
    }

        //1 smoker
        //2 boomer
        //3 ?
    
    // Spawn the special infected
    int spawnedInfected = L4D2_SpawnSpecial(infectedType, Pos, Angle);
    if(IsValidEntity(spawnedInfected))
    {
        // Change the team of the dead player to infected
        ChangeClientTeam(victim, TEAM_INFECTED);
    }
}

public void OnMapStart()
{
    // Reset all players to survivors at the start of the map
    ResetPlayersToSurvivors();
}

public void ResetPlayers(Event event, const char[] szName, bool dontBroadcast)
{
    // Reset all players to survivors at the start of a new round
    ResetPlayersToSurvivors();
}

void ResetPlayersToSurvivors()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            ChangeClientTeam(i, TEAM_SURVIVORS);
        }
    }
}