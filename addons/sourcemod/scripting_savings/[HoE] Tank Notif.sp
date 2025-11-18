//Tank Notification for L4D/L4d2
//Prints a message and plays a sound when a tank spawns, music is unreliable.
//2022-4-2 Weld Inclusion

#include <sourcemod>
#include <sdktools>
#include <colors>
#define VERSION "1.1"

new bool:   g_bIsTankInPlay             = false;

public Plugin:myinfo =
{
	name = "Tank Notification",
	author = "Weld Inclusion",
	description = "Prints a server-wide message and plays a sound when a tank spawns.",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2770712"
}

public void OnMapStart()
{
	PrecacheSound("ui/pickup_secret01.wav");
}

public void OnPluginStart ()
{
   g_bIsTankInPlay = false;
   HookEvent("tank_spawn", TankNotify);
   HookEvent("round_start", Event_RoundStart);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_bIsTankInPlay = false;
}

public void TankNotify(Event event, const char[] name, bool dontBroadcast)
{

if (g_bIsTankInPlay) return; // Tank passed

g_bIsTankInPlay = true;

decl String:randMelonMsg[][] = {
            {"{red}[{default}!{red}] {default}El {olive}Tank {default}ha {olive}Spawneado!"},

};

CPrintToChatAll(randMelonMsg[GetRandomInt(0, sizeof(randMelonMsg) - 1)]);   

    for (new i = 1; i <= MaxClients; i++)

    {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {
            EmitSoundToClient(i, "ui/pickup_secret01.wav");
        }
        
    }
}