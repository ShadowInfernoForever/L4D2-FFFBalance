#include <sourcemod>

#pragma semicolon 1

#define BHOP_WINDOW 0.007 // 30ms para permitir el bhop después de tocar el suelo

new Float:lastGroundTime[MAXPLAYERS + 1];
new bool:jumpButtonReleased[MAXPLAYERS + 1];

public Plugin myinfo = {
    name = "Bhop Extension",
    author = "ChatGPT",
    description = "Extiende el tiempo de bhop permitiendo saltar 50ms después de tocar el suelo.",
    version = "1.0",
    url = ""
};

public OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Continue;

    if (GetEntityFlags(client) & FL_ONGROUND)
    {
        lastGroundTime[client] = GetGameTime(); // Guarda el último momento en tierra
    }

    if (buttons & IN_JUMP)
    {
        if (jumpButtonReleased[client] && GetGameTime() - lastGroundTime[client] < BHOP_WINDOW)
        {
            buttons |= IN_JUMP; // Permite saltar si está dentro del tiempo permitido
            jumpButtonReleased[client] = false;
        }
        else
        {
            buttons &= ~IN_JUMP; // Evita saltos fuera del tiempo permitido
        }
    }
    else
    {
        jumpButtonReleased[client] = true; // Detecta cuando se suelta la tecla de salto
    }
    
    return Plugin_Continue;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client > 0 && client <= MaxClients)
    {
        lastGroundTime[client] = 0.0; // Resetea el tiempo al respawnear
        jumpButtonReleased[client] = true;
    }
    return Plugin_Continue;
}