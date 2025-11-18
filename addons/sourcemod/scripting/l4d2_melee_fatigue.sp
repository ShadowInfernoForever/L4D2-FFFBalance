#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
    name = "[L4D2] Melee Shove Penalty",
    author = "Adaptado por Shadow",
    description = "Quita un shove al usar melee, sin bloquear ataques.",
    version = PLUGIN_VERSION,
    url = "https://github.com/"
};

public void OnPluginStart()
{
    CreateConVar("l4d2_melee_shovepenalty_version", PLUGIN_VERSION, "Versión del plugin", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}

public void L4D_OnStartMeleeSwing_Post(int client, bool boolean)
{
	int penalty = GetEntProp(client, Prop_Send, "m_iShovePenalty");
    float shoveTime = GetEntPropFloat(client, Prop_Send, "m_flNextShoveTime");
    float gameTime = GetGameTime();

    // Mostrar el estado actual
    PrintToChat(client, "\x04[DEBUG] Shoves: %d | Cooldown: %.2f | GameTime: %.2f", penalty, shoveTime, gameTime);

    float delay = 0.4 + 5.0;
    SetEntPropFloat(client, Prop_Send, "m_flNextShoveTime", gameTime + delay);
    PrintToChat(client, "\x04[DEBUG] No quedaban shoves. Se aplicó cooldown hasta %.2f", gameTime + delay);

    if (penalty > 0)
    {
        SetEntProp(client, Prop_Send, "m_iShovePenalty", penalty - 1);
        PrintToChat(client, "\x04[DEBUG] Se restó un shove. Nuevo valor: %d", penalty - 1);
    }
}