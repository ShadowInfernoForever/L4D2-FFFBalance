#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
    name = "Speed Modifier",
    author = "Shadow",
    description = "Modifies player movement speed based on input.",
    version = "1.0",
    url = "" // Replace with your plugin's URL or documentation link.
};

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post); // Reset speed when players spawn.
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    if (buttons & IN_SPEED) // Check if Shift is pressed.
    {
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.3); // Increase movement speed (1.3x normal speed).
    }
    else
    {
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 0.7); // Default walking speed.
    }
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
    {
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0); // Reset speed on spawn.
    }
    return Plugin_Continue;
}
