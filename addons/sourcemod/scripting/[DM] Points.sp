#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>

int g_Points[MAXPLAYERS + 1];

ConVar g_hWinScore;

bool g_HasWinner = false;

public Plugin myinfo =
{
    name = "[DM] Points",
    author = "Shadow",
    description = "Sistema de puntaje tipo Zonemod con phrases y colores",
    version = "1.2"
};

public void OnPluginStart()
{
    LoadTranslations("DM.phrases");

    g_hWinScore = CreateConVar("dm_win_score", "50", "Puntos necesarios para ganar", FCVAR_NOTIFY);

    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
}

public void OnClientConnected(int client)
{
    g_Points[client] = 0;
}

// --------------------------------
//           KILL
// --------------------------------
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!attacker || attacker == victim || !IsClientInGame(attacker)) return;

    g_Points[attacker] += 5;

    // Traducción de frases con colores
    CPrintToChatAll("%T", "DM_Kill", LANG_SERVER, attacker, victim, g_Points[attacker]);

    CheckWin(attacker);
}

// --------------------------------
//           DAMAGE
// --------------------------------
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim   = GetClientOfUserId(event.GetInt("userid"));

    if (!attacker || attacker == victim || !IsClientInGame(attacker)) return;

    int damage = event.GetInt("dmg_health");
    int gained = damage / 10;
    if (gained <= 0) return;

    g_Points[attacker] += gained;

    CPrintToChat(attacker, "%T", "DM_Damage", attacker, gained, g_Points[attacker]);
}

public Action Timer_RestartMap(Handle timer)
{
    char map[64];
    GetCurrentMap(map, sizeof(map));
    ServerCommand("changelevel %s", map);
    return Plugin_Stop;
}

void CheckWin(int client)
{
    if (g_HasWinner)
        return;

    int winScore = g_hWinScore.IntValue;

    if (g_Points[client] >= winScore)
    {
        g_HasWinner = true;

        CPrintToChatAll("%T", "DM_Win", LANG_SERVER, client, g_Points[client]);

        // Esperar 3 segundos y reiniciar mapa
        CreateTimer(5.0, Timer_RestartMap, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}
