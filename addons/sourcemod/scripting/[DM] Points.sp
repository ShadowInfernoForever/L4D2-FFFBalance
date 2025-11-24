#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>

int g_Points[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "[DM] Points",
    author = "Shadow",
    description = "Sistema de puntaje tipo Zonemod con phrases y colores",
    version = "1.1"
};

// ------------------ PHRASES ------------------
public void OnPluginStart()
{
    // Registrar phrases
    RegAdminMsg("DM_KILL", "{olive}%N mató a %N {gold}+%d puntos {default}(Total: {blue}%d{default})");
    RegAdminMsg("DM_DAMAGE", "{olive}Daño: {gold}+%d {default}punto(s) (Total: {blue}%d{default})");

    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
}

// ------------------ CONEXIÓN ------------------
public void OnClientConnected(int client)
{
    g_Points[client] = 0;
}

// ------------------ KILL ------------------
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!attacker || attacker == victim || !IsClientInGame(attacker)) return;

    g_Points[attacker] += 5;

    // Mostrar mensaje con colors + phrases
    char message[128];
    Format(message, sizeof(message), "%N mató a %N +5 puntos (Total: %d)", attacker, victim, g_Points[attacker]);
    PrintToChatAll(message);
}

// ------------------ DAÑO ------------------
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim   = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!attacker || attacker == victim || !IsClientInGame(attacker)) return;

    int damage = event.GetInt("dmg_health");
    int gained = damage / 10;
    if (gained <= 0) return;

    g_Points[attacker] += gained;

    char msg[128];
    Format(msg, sizeof(msg), "Daño: +%d punto(s) (Total: %d)", gained, g_Points[attacker]);
    PrintToChat(attacker, msg);
}
