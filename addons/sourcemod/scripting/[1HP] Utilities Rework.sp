#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define GAMEDATA_FILE "l4d2addresses"

// SDKCall handle for applying boomer bile (CTerrorPlayer_OnVomitedUpon)
Handle g_hSDKCall_OnVomitedUpon = INVALID_HANDLE;

// Configuration values
float g_fPillsInvulTime = 5.0;     // Pills give 5 seconds of invulnerability
float g_fMedkitInvulTime = 13.0;   // Medkit gives 13 seconds of invulnerability

public Plugin myinfo =
{
    name = "[1HP] Utilities Rework",
    author = "Shadow",
    description = "Pills apply bile + invulnerability, medkit provides invulnerability.",
    version = "1.0"
};

public void OnPluginStart()
{
    PrepSDKCalls();

    // Hook when pills are consumed
    HookEvent("pills_used", Event_PillsUsed);

    // Hook when a heal is successfully completed (medkit)
    HookEvent("heal_success", Event_HealSuccess);
}

//
// Prepare the SDKCall required to apply the boomer bile effect
//
void PrepSDKCalls()
{
    Handle hConfig = LoadGameConfigFile(GAMEDATA_FILE);
    if (hConfig == INVALID_HANDLE)
    {
        SetFailState("Failed to load gamedata file '%s'.", GAMEDATA_FILE);
        return;
    }

    // Setup CTerrorPlayer_OnVomitedUpon(player, attacker, bool)
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);      // attacker
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);       // unknown (usually bool)
    g_hSDKCall_OnVomitedUpon = EndPrepSDKCall();

    if (g_hSDKCall_OnVomitedUpon == INVALID_HANDLE)
        SetFailState("Failed to create SDKCall for CTerrorPlayer_OnVomitedUpon.");

    CloseHandle(hConfig);
}

//
// Apply boomer bile to a player using the SDKCall
//
void BilePlayer(int client, int attacker = 0)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    // If attacker is invalid, fallback to the player itself
    if (attacker <= 0 || !IsClientInGame(attacker))
        attacker = client;

    // Execute CTerrorPlayer_OnVomitedUpon
    SDKCall(g_hSDKCall_OnVomitedUpon, client, attacker);
}

//
// Make a player temporarily invulnerable
//
void MakeInvulnerable(int client, float duration)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    // m_takedamage = 0 makes the player immune to all damage
    SetEntProp(client, Prop_Data, "m_takedamage", 0);

    // After duration seconds, remove invulnerability
    CreateTimer(duration, Timer_RemoveInvuln, client);
}

//
// Timer callback: restore normal damage
//
public Action Timer_RemoveInvuln(Handle timer, any client)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
    {
        // 2 = normal damage mode
        SetEntProp(client, Prop_Data, "m_takedamage", 2);
    }
    return Plugin_Stop;
}

//
// EVENT: Pills used
// → Apply bile + 5 seconds of invulnerability
//
public void Event_PillsUsed(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsClientInGame(client)) return;

    BilePlayer(client);
    MakeInvulnerable(client, g_fPillsInvulTime);
}

//
// EVENT: Medkit heal success
// → Apply 13 seconds of invulnerability
//
public void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsClientInGame(client)) return;

    BilePlayer(client);
    MakeInvulnerable(client, g_fMedkitInvulTime);
}
