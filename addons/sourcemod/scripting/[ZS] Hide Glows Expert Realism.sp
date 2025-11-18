#pragma semicolon 1
#include <sourcemod>
#include <sdktools>   
#include <sdkhooks>
ConVar TIME;
Handle TIMER = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[HoE] Hide Glows and keep names",
	author = "JNC",
	description = "ayyy lmao",
	version = "1.0",
	url = ""
};

public void OnPluginStart() 
{ 
    //RegAdminCmd("sm_glow", ToggleSurvivorGlow, ADMFLAG_ROOT, "Toggles the survivor glow"); 
    // hook event round start
    TIME = CreateConVar("hoe_glows_hide_timer", "15", "How long to put the glows to 0");
    TIME.AddChangeHook(OnCvarChange);
}

public void OnMapStart(){

TIMER = CreateTimer(1.0 * GetConVarInt(TIME), Glow_Timer,_, TIMER_REPEAT);

}

public void OnMapEnd(){

KillTimer(TIMER);

}

public void OnCvarChange(ConVar convar, char[] oldValue, char[] newValue)
{
    if (convar == TIME)
    {
    	KillTimer(TIMER);
        TIMER = CreateTimer(1.0 * GetConVarInt(TIME), Glow_Timer,_, TIMER_REPEAT);
    }
}

// crear un timer

public Action Glow_Timer(Handle timer) 
{
    for (new i = 1; i <= MaxClients; i++)
        {
        if (IsClientInGame(i))
        {
          SetEntProp(i, Prop_Send, "m_bSurvivorGlowEnabled", 0);
          SetEntProp(i, Prop_Send, "m_glowColorOverride", 0);
       }   
     }
} 