#pragma semicolon 1

#define PLUGIN_NAME 		"HUD Player Removal Manager"
#define PLUGIN_AUTHOR 		"gabuch2"
#define PLUGIN_DESCRIPTION 	"Removes all team hud, for survivors"
#define PLUGIN_VERSION 		"1.0.1"
#define PLUGIN_URL			"https://github.com/szGabu/L4D2HudDisplayManager"

#define DEBUG false
#define PER_PLAYER_OPTIONAL true

#define L4D_TEAM_SURVIVORS 	2
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

ConVar	g_cvarEnabled;

int		g_iTerrorPlayerManagerEnt = -1;

bool	g_bCvarEnabled;

enum struct DistData
{
    int index;
    float dist;
}

public Plugin myinfo =  
{  
	name = PLUGIN_NAME,  
	author = PLUGIN_AUTHOR,  
	description = PLUGIN_DESCRIPTION,  
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}  



public void OnPluginStart()  
{  
	g_cvarEnabled = CreateConVar("sm_l4d2_hud_display_enabled", "1", "Enables HUD Player Display Manager.", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	CreateConVar("sm_l4d2_hud_display_version", PLUGIN_VERSION, "Version of HUD Player Display Manager", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_cvarEnabled.AddChangeHook(ConVarChanged_Cvars);

	GetCvars();
	FindTerrorManager();
}

public void OnPluginEnd()
{
	for (int iClient = 1; iClient <= MaxClients; iClient++) // Loop through all clients
	{
		// Check if the client is fully in-game and connected before getting their team
		if (IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient) &&  GetClientTeam(iClient) == L4D_TEAM_SURVIVORS)
		{
			UnhookClient(iClient);
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	if(iClient)
		UnhookClient(iClient);
}

public void FindTerrorManager()
{
	g_iTerrorPlayerManagerEnt = FindEntityByClassname(g_iTerrorPlayerManagerEnt, "terror_player_manager");
	#if DEBUG
	PrintToServer("[DEBUG] terror_player_manager is %d", g_iTerrorPlayerManagerEnt);
	#endif
}

public void OnMapEnd() 
{
	g_iTerrorPlayerManagerEnt = -1;
}

public Action SurvivorTeamCallback(int iEntity, char[] propname, int &iValue, int iElement, int iClient)
{
    // Solo mostrar el HUD del propio jugador
    if (iClient != iElement)
    {
        iValue = 1; // Oculta el HUD para los compañeros de equipo
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

void HookClient(int iClient)
{
	if (IsValidEntity(iClient) && IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient) && GetClientTeam(iClient) == L4D_TEAM_SURVIVORS)
	{
		// Only proceed if the entity is valid
		if (g_iTerrorPlayerManagerEnt == -1)
			FindTerrorManager();

		// Set the m_iTeam property directly
		SetEntProp(g_iTerrorPlayerManagerEnt, Prop_Data, "m_iTeam", 1);
	}
}

void UnhookClient(int iClient)
{
	if (IsValidEntity(iClient))
	{
		// Reset the m_iTeam property directly or unhook based on your needs
		SetEntProp(g_iTerrorPlayerManagerEnt, Prop_Data, "m_iTeam", L4D_TEAM_SURVIVORS);
	}
}


void HookAllClients()
{
	for (int iTarget = 1; iTarget <= MaxClients; iTarget++) 
	{
		HookClient(iTarget);
	}
}

void UnhookAllClients()
{
	for (int iTarget = 1; iTarget <= MaxClients; iTarget++) 
	{
		UnhookClient(iTarget);
	}
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarEnabled = g_cvarEnabled.BoolValue;

	if(g_bCvarEnabled)
	{
		#if DEBUG
		PrintToServer("[DEBUG] Plugin enabled, hooking everything.");
		#endif	
		HookAllClients();
	}
	else
	{
		#if DEBUG
		PrintToServer("[DEBUG] Plugin disabled. Bye bye.");
		#endif	
		UnhookAllClients();
	}
}