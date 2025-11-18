/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-12-18 20:06:26
 * @Last Modified time: 2023-12-18 21:00:52
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1

#include <sdktools>
#include <sourcemod>

#define VERSION "2023.12.18"

#define DEBUG 0
#define MAXSIZE MAXPLAYERS + 1

#define SOUND_ACTIVATE "player/laser_on.wav"
#define SOUND_DEACTIVATE "player/suit_denydevice.wav"

float
    g_iFlashPressTime[MAXSIZE];
    g_fLastHintTime[MAXSIZE];

public Plugin myinfo =
{
    name = "Nightvision",
    author = "Shadow",
    description = "CS:S NightVision when double tapping F",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

public void OnMapStart()
{
    PrecacheSound(SOUND_ACTIVATE, true);
    PrecacheSound(SOUND_DEACTIVATE, true);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse)
{
    if (impulse != 100) return;

    float currentTime = GetEngineTime();

    // Limit the hint message to once every 120 seconds
    if (currentTime - g_fLastHintTime[client] > 120.0)
    {
        g_fLastHintTime[client] = currentTime;
    }

    // Double-press detection for toggling night vision
    if (currentTime - g_iFlashPressTime[client] > 0.2)
    {
        // If more than 0.3 seconds have passed, reset the time to detect the next press
        g_iFlashPressTime[client] = currentTime;
    }
    else
    {
        // If within the 0.3 second window, activate/deactivate the night vision
        ToggleNightVision(client);
    }
}

void ToggleNightVision(int client)
{
    int status = GetEntProp(client, Prop_Send, "m_bNightVisionOn");
    SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1 - status);


    // Play sound and show feedback
    if (status)
    {
        EmitSoundToClient(client, SOUND_DEACTIVATE);
    }
    else
    {
        EmitSoundToClient(client, SOUND_ACTIVATE);
    }
}

public Action DestroyInstructor(Handle timer, int iEntity)
{
    if (IsValidEdict(iEntity))
    {
        AcceptEntityInput(iEntity, "Disable");
        AcceptEntityInput(iEntity, "Kill");
    }

    return Plugin_Continue;
}