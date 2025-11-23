#include <sourcemod>
#include <colors>
#include <sdktools>
#include <sdkhooks>

Handle ClientTimer[MAXPLAYERS + 1];
int PlayerResourceEntity;

ConVar g_hFakePingEnable;

public Plugin myinfo = 
{
    name = "FakeAdminPing", 
    author = "pa4H / Shadow edit", 
    description = "", 
    version = "1.1", 
    url = "https://t.me/pa4H232"
}

public void OnPluginStart()
{
    g_hFakePingEnable = CreateConVar("sm_fakeping_enable", "1",
        "Enable or disable FakeAdminPing (1=on, 0=off)");
}

public void OnClientPostAdminCheck(int client)
{
    if (!g_hFakePingEnable.BoolValue)
        return;

    if (isAdmin(client))
    {
        PlayerResourceEntity = GetPlayerResourceEntity();
        ClientTimer[client] = CreateTimer(5.0, Timer_SetPing, client, TIMER_REPEAT);
    }
}

public void OnClientDisconnect(int client)
{
    delete ClientTimer[client];
}

public Action Timer_SetPing(Handle timer, int client)
{
    if (!g_hFakePingEnable.BoolValue)
        return Plugin_Stop;

    if (IsValidClient(client))
    {
        int avg = GetAveragePing();

        int min = avg - 10;
        int max = avg + 10;
        if (min < 5) min = 5;

        int rndPing = GetRandomInt(min, max);

        SetEntProp(PlayerResourceEntity, Prop_Send, "m_iPing", 0, _, client);
        SetEntProp(PlayerResourceEntity, Prop_Send, "m_iPing", rndPing, _, client);
    }

    return Plugin_Continue;
}

/* ===========================
        UTIL FUNCTIONS
=========================== */

bool isAdmin(int client)
{
    return (GetUserFlagBits(client) == ADMFLAG_ROOT);
}

bool IsValidClient(int client)
{
    return (client > 0 &&
            client <= MaxClients &&
            IsClientConnected(client) &&
            IsClientInGame(client) &&
            !IsFakeClient(client));
}

int GetAveragePing()
{
    int total = 0;
    int count = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            int ping = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iPing", _, i);
            total += ping;
            count++;
        }
    }

    if (count == 0)
        return 50; // fallback

    return total / count;
}
