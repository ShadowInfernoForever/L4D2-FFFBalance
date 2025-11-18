#define PLUGIN_VERSION "1.3"

#include <sourcemod>
#pragma newdecls required

/**
 * v1.0 just released;
 * v1.0.1 check entity validates for button status;
 * v1.2 turn to new syntax and less performance usage, add binary check now compatible for other flag change plugins;
 * v1.3 support show on specifies teams or difficulties, 
 * 		change work way to GameFrame and hide_hud_interval change to frames unit,
 * 		add key detection instead +speed;
 * 		death also regarded as incapped; 7-April-2022
 */

ConVar Hide_hud_interval;		int hide_hud_interval;
ConVar Show_on_key;				int show_on_key;
ConVar Show_on_menuing;			bool show_on_menuing;
ConVar Show_on_incapped;		bool show_on_incapped;
ConVar Hide_flag;				int hide_flag;
ConVar Show_on_difficulties;	int show_on_difficulties;
ConVar Show_on_teams;			int show_on_teams;
ConVar Difficulty;				int difficulty;

enum {
	Easy = 1,
	Normal = 2,
	Hard = 4,
	Expert = 8
}


public Plugin myinfo = {
	name = "[L4D & L4D2] HUD Hiddens",
	author = "NoroHime",
	description = "make players HUD hidden automatically.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public void OnPluginStart() {

	CreateConVar("hide_hud_version", PLUGIN_VERSION, "Version of HUD Hiddens", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Hide_hud_interval =		CreateConVar("hide_hud_interval", "10", "game frames skips of hidden action, 10=every 10 frames, higher value detect slower and less performance", FCVAR_NOTIFY);
	Show_on_key =			CreateConVar("hide_hud_show_on_key", "131072", "show hud if press these key, 131072=speed(shift) 4=crouch ", FCVAR_NOTIFY);
	Show_on_menuing =		CreateConVar("hide_hud_show_on_menuing", "1", "show hud if menu open", FCVAR_NOTIFY);
	Show_on_incapped =		CreateConVar("hide_hud_show_on_incapped", "1", "show hud if incapped", FCVAR_NOTIFY);
	Hide_flag =				CreateConVar("hide_hud_hideflag", "64", "hidd these HUDs, 1=weapon selection, 2=flashlight, 4=all, 8=health\n16=player dead, 32=needssuit, 64=misc, 128=chat, 256=crosshair, 512=vehicle crosshair, 1024=in vehicle\nnot all available", FCVAR_NOTIFY);
	Show_on_difficulties =	CreateConVar("hide_hud_show_on_difficulties", "1", "show hud on these difficulties. 1=easy 2=normal 4=hard 8=expert -1=All 7=excluded expert. add numbers together you want.", FCVAR_NOTIFY);
	Show_on_teams =			CreateConVar("hide_hud_show_on_teams", "11", "show hud on these teams. 1=idle 2=spectator 4=survivors 8=infected 11=excluded survivors. add numbers together you want.", FCVAR_NOTIFY);
	Difficulty =			FindConVar("z_difficulty");

	Hide_hud_interval.AddChangeHook(Event_ConVarChanged);
	Show_on_key.AddChangeHook(Event_ConVarChanged);
	Show_on_menuing.AddChangeHook(Event_ConVarChanged);
	Show_on_incapped.AddChangeHook(Event_ConVarChanged);
	Hide_flag.AddChangeHook(Event_ConVarChanged);
	Show_on_difficulties.AddChangeHook(Event_ConVarChanged);
	Show_on_teams.AddChangeHook(Event_ConVarChanged);
	Difficulty.AddChangeHook(Event_ConVarChanged);

	AutoExecConfig(true, "hide_hud");
}


public void OnConfigsExecuted() {
	ApplyCvars();
}


public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void ApplyCvars() {
	hide_hud_interval =  Hide_hud_interval.IntValue;
	show_on_key = Show_on_key.IntValue;
	show_on_menuing = Show_on_menuing.BoolValue;
	show_on_incapped = Show_on_incapped.BoolValue;
	hide_flag = Hide_flag.IntValue;
	show_on_difficulties = Show_on_difficulties.IntValue;
	show_on_teams = Show_on_teams.IntValue;

	static char diffi[32];
	Difficulty.GetString(diffi, sizeof(diffi));

	switch (diffi[0]) {
		case 'E', 'e' : difficulty = Easy;
		case 'N', 'n' : difficulty = Normal;
		case 'H', 'h' : difficulty = Hard;
		case 'I', 'i' : difficulty = Expert;
		default : difficulty = Normal;
	}
}

stock bool isPlayerDown(int client) {
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || !IsPlayerAlive(client);
}

public void OnGameFrame() {

	static int skipped = 0;

	if (++skipped >= hide_hud_interval) {

		skipped = 0;

		for (int client = 1; client <= MaxClients; client++) {

			if (IsValidEntity(client) && IsClientInGame(client) && !IsFakeClient(client)) {

				int buttons = GetClientButtons(client),
					flags = GetEntProp(client, Prop_Send, "m_iHideHUD"),
					team = GetClientTeam(client);

				if ( 
					(show_on_menuing && GetClientMenu(client) != MenuSource_None) ||  
					(buttons & show_on_key) || 
					(show_on_incapped && isPlayerDown(client)) ||
					(show_on_difficulties & difficulty) ||
					(show_on_teams & (1 << team))
				) {
					if(flags & hide_flag)
						SetEntProp(client, Prop_Send, "m_iHideHUD",  flags & ~hide_flag); //shown

				} else if ( !(flags & hide_flag) )
					SetEntProp(client, Prop_Send, "m_iHideHUD", flags | hide_flag); //hidden
			}
		}
	}
}
