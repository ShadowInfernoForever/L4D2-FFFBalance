#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <sdkhooks>

const TEAM_NONE = 0;
const TEAM_SPECTATOR = 1;
const TEAM_SURVIVOR = 2;
const TEAM_INFECTED = 3;

const PREZ_COLOR_NOCOLOR = 0;
const PREZ_COLOR_FULLHEALTH = 1;
const PREZ_COLOR_MEDHEALTH = 2;
const PREZ_COLOR_LOWHEALTH = 3;
const PREZ_COLOR_BOOMED = 4;

const WEP_SLOT_PRIMARY = 0;
const WEP_SLOT_MELEE = 1;
const WEP_SLOT_GRENADE = 2;
const WEP_SLOT_HEALTH = 3;

#define PLUGIN_VERSION "1.0.4"

#define SOUND_START "ui/survival_teamrec.wav"
#define SOUND_DEATH "ui/menu_countdown.wav"
#define sColor      "100,100,255"

public Plugin:myinfo =  {

	name        = "L4D2 -=BwA=- Protect The President",
	author      = "	",
	description = "Protect the teammate deemed 'The Prez' as when they are hit, you all are",
	version     = PLUGIN_VERSION,
	url         = ""
};

new thePrez = 0;

//new dfltGlow = 0;
//new dfltColor = 0;
//new dfltRange = 0;
//new dfltFlash = 0;

new Handle:prez_SkinColor_FullHealth;
new Handle:prez_SkinColor_MedHealth;
new Handle:prez_SkinColor_LowHealth;
new Handle:prez_GlowColor_FullHealth;
new Handle:prez_GlowColor_MedHealth;
new Handle:prez_GlowColor_LowHealth;
new Handle:prez_GlowColor_Boomed;

new skinRed[4];
new skinGreen[4];
new skinBlue[4];

new glowColor[5];

new movementOffset = -1;

new Handle:teamDmgRatio;
new Handle:normalDmgRatio;
new Handle:prezSpeedRatio;
new Handle:prezHealthRatio;
new Handle:prezCanHeal;
new Handle:prezDefibTime;
new Handle:prezSelectionType;
new Handle:prezAllowMagnum;

new deathTicks = 0;

new bool:prezRevived = false;
new bool:prezBoomed = false;

new bool:prevPrez[MAXPLAYERS + 1];

new bool:enabled = true;
new lockedDoor = 0;

new Handle:hTopMenu = INVALID_HANDLE;

public OnPluginStart() {

	decl String:ModName[64];
	GetGameFolderName(ModName, sizeof(ModName));
	
	if(!StrEqual(ModName, "left4dead2", false)) 
	{ 
		SetFailState("Use this in Left 4 Dead (2) only.");
	}

	HookEvent("player_spawn", 			Event_PlayerSpawn);
			
	CreateConVar("l4d2_bwa_protectheprez_version", PLUGIN_VERSION, "L4D2 BwA Protect the Prez Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	teamDmgRatio = CreateConVar("l4d2_bwa_ptp_team_dmg_ratio", "0.5", "Percentage of damage to president that team members take. [min = 0.0(0%)|max = 5.0(500%)]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.10, true, 5.0);
	normalDmgRatio = CreateConVar("l4d2_bwa_ptp_normal_dmg_ratio", "1.0", "Percentage of normal damage to apply to all players. [min = .10(10%)|max = 5.0(500%)]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.10, true, 5.0);
	prezHealthRatio = CreateConVar("l4d2_bwa_ptp_prez_health_ratio", "1.5", "Health Multiplier for President [min = .50(50% health)|max = 5.0(500% health)]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.10, true, 5.0);
	prezSpeedRatio = CreateConVar("l4d2_bwa_ptp_prez_speed_ratio", "1.2", "Percentage of normal movement speed to give to the president. [min = .5(50%)|max = 2.0(200%)]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.50, true, 2.0);
	prezCanHeal = CreateConVar("l4d2_bwa_ptp_prez_allow_heal", "0", "Allow the Prez to carry a health pack and heal himself. [0 = Off|1 = On]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	prezDefibTime = CreateConVar("l4d2_bwa_ptp_prez_defib_time", "30", "Number of seconds you have to defib the President when he dies before you all die. [min = 0|max = 300(5 mins)]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 300.0);
	prezSelectionType = CreateConVar("l4d2_bwa_ptp_prez_selection_type", "2", "Type of selection process for President. [Random = 1|Random excluding previous = 2]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 2.0);
	prezAllowMagnum = CreateConVar("l4d2_bwa_ptp_prez_allow_magnum", "0", "Allow/Give the Prez a magnum. [0 = No|1 = Yes]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
			
	prez_SkinColor_FullHealth = CreateConVar("l4d2_bwa_ptp_prez_SkinColor_FullHealth", "10,200,200", "<Red>,<Green>,<Blue> (0-255)");
	prez_SkinColor_MedHealth = CreateConVar("l4d2_bwa_ptp_prez_SkinColor_MedHealth", "180,100,20", "<Red>,<Green>,<Blue> (0-255)");
	prez_SkinColor_LowHealth = CreateConVar("l4d2_bwa_ptp_prez_SkinColor_LowHealth", "220,20,20", "<Red>,<Green>,<Blue> (0-255)");
		
	prez_GlowColor_FullHealth = CreateConVar("l4d2_bwa_ptp_prez_GlowColor_FullHealth", "0,0,255", "<Red> <Green> <Blue> (0-255)");
	prez_GlowColor_MedHealth = CreateConVar("l4d2_bwa_ptp_prez_GlowColor_MedHealth", "128,128,255", "<Red> <Green> <Blue> (0-255)");
	prez_GlowColor_LowHealth = CreateConVar("l4d2_bwa_ptp_prez_GlowColor_LowHealth", "255,255,255", "<Red> <Green> <Blue> (0-255)");
	prez_GlowColor_Boomed = CreateConVar("l4d2_bwa_ptp_prez_GlowColor_Boomed", "255,0,255", "<Red> <Green> <Blue> (0-255)");

	RegAdminCmd("sm_prezselect", Command_SelectPrez, ADMFLAG_GENERIC, "usage: sm_prezselect <clientid>");	
	RegAdminCmd("sm_enablevip", Command_Enable, ADMFLAG_GENERIC, "usage: sm_enablevip");	
	RegAdminCmd("sm_disablevip", Command_Disable, ADMFLAG_GENERIC, "usage: sm_disablevip");
	RegAdminCmd("sm_prezresetglows", ResetGlowColors, ADMFLAG_GENERIC, "usage: sm_prezresetglows <This to reset duplicated prez glows>");
			
	RegConsoleCmd("lock", Command_Lock);
	RegConsoleCmd("unlock", Command_Unlock);
	
	movementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	
	AutoExecConfig(true, "l4d2_bwa_protect_the_prez");
	
	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(hTopMenu);
	}
	
	Enable();
	
}

public OnConfigsExecuted() {

	// 0 is PREZ_COLOR_NOCOLOR
	skinRed[0] = 255;
	skinGreen[0] = 255;
	skinBlue[0] = 255;
	
	new String:colors[3][4];
		
	new String:color[32] = { "255,255,255" };
			
	GetConVarString(prez_SkinColor_FullHealth, color, sizeof(color));
		
	ExplodeString(color, ",", colors, 3, 4);
	
	skinRed[PREZ_COLOR_FULLHEALTH] = StringToInt(colors[0]);
	skinGreen[PREZ_COLOR_FULLHEALTH] = StringToInt(colors[1]);
	skinBlue[PREZ_COLOR_FULLHEALTH] = StringToInt(colors[2]);
	
	GetConVarString(prez_SkinColor_MedHealth, color, sizeof(color));
	
	ExplodeString(color, ",", colors, 3, 4);
	
	skinRed[PREZ_COLOR_MEDHEALTH] = StringToInt(colors[0]);
	skinGreen[PREZ_COLOR_MEDHEALTH] = StringToInt(colors[1]);
	skinBlue[PREZ_COLOR_MEDHEALTH] = StringToInt(colors[2]);
	
	GetConVarString(prez_SkinColor_LowHealth, color, sizeof(color));
		
	ExplodeString(color, ",", colors, 3, 4);
	
	skinRed[PREZ_COLOR_LOWHEALTH] = StringToInt(colors[0]);
	skinGreen[PREZ_COLOR_LOWHEALTH] = StringToInt(colors[1]);
	skinBlue[PREZ_COLOR_LOWHEALTH] = StringToInt(colors[2]);
	
	// 0 is PREZ_COLOR_NOCOLOR		
	glowColor[0] = 0;

	GetConVarString(prez_GlowColor_FullHealth, color, sizeof(color));
	ExplodeString(color, ",", colors, 3, 4);
	glowColor[PREZ_COLOR_FULLHEALTH] = RGB_TO_INT(StringToInt(colors[0]), StringToInt(colors[1]), StringToInt(colors[2]));
	
	GetConVarString(prez_GlowColor_MedHealth, color, sizeof(color));
	ExplodeString(color, ",", colors, 3, 4);
	glowColor[PREZ_COLOR_MEDHEALTH] = RGB_TO_INT(StringToInt(colors[0]), StringToInt(colors[1]), StringToInt(colors[2]));
	
	GetConVarString(prez_GlowColor_LowHealth, color, sizeof(color));
	ExplodeString(color, ",", colors, 3, 4);
	glowColor[PREZ_COLOR_LOWHEALTH] = RGB_TO_INT(StringToInt(colors[0]), StringToInt(colors[1]), StringToInt(colors[2]));
	
	GetConVarString(prez_GlowColor_Boomed, color, sizeof(color));
	ExplodeString(color, ",", colors, 3, 4);
	glowColor[PREZ_COLOR_BOOMED] = RGB_TO_INT(StringToInt(colors[0]), StringToInt(colors[1]), StringToInt(colors[2]));
		
}

stock RGB_TO_INT(red, green, blue) {

	return (blue * 65536) + (green * 256) + red;

}

public OnAdminMenuReady(Handle:topmenu) {
			
	if (topmenu == hTopMenu) return;
		
	hTopMenu = topmenu;

	// Create a new Category on the admin menu	
	new TopMenuObject:vip_menu = AddToTopMenu(hTopMenu, "BwAProtectThePrezMenu", TopMenuObject_Category, Admin_TopPrezMenu, INVALID_TOPMENUOBJECT); 
			
	// Add items to the category
	if (vip_menu != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu, "bwaselecttheprez", TopMenuObject_Item, Admin_SelectThePrez, vip_menu, "", ADMFLAG_GENERIC);
	}
}

public OnLibraryRemoved(const String:name[]) {

	if (StrEqual(name, "adminmenu")) { hTopMenu = INVALID_HANDLE; }
}

// Format very top level admin menu entry
public Admin_TopPrezMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	
	switch (action)
	{
		case TopMenuAction_DisplayTitle, TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "-=BwA=- Protect The President");
		}
	}

}

// Handle the "Select a Prez" top menu item
public Admin_SelectThePrez(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
			
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "Select a President");
		}
		case TopMenuAction_SelectOption:
		{
			Admin_ChooseThePrezMenu(param);	
		}			
	}
}

// Show the menu to select a player to be the Prez
Admin_ChooseThePrezMenu(client) {
		
	decl String:title[100];
	
	Format(title, sizeof(title), "Select a President");
	
	new Handle:menu = CreateMenu(Admin_MnuHdlr_ChooseThePrez);	
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	new String:name[MAX_NAME_LENGTH];
	new String:mnuinfo[8];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidSurvivor(i, false))
		{
			IntToString(i, mnuinfo, 8); 
			Format(name, sizeof(name),  "%N", i); 
			AddMenuItem(menu, mnuinfo, name); 
		}	
	}
		
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
}

// Select a player to be the Prez
public Admin_MnuHdlr_ChooseThePrez(Handle:menu, MenuAction:action, param1, param2) {
		
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select:
		{
			decl String:info[32];
				
			GetMenuItem(menu, param2, info, sizeof(info));
			new target = StringToInt(info);
			
			if (target == 0)
			{
				PrintToChat(param1, "[SM]", "Player no longer available");
			}
			else
			{
				if (IsValidSurvivor(target, false) && ( target != thePrez))
				{
					RemoveThePrez();
					SetThePrez(target);
				}				
			}
		}	
	}
	
}


public Action:Command_Enable(client, args) {
	
	if (!enabled)
	{
		enabled = true;
		Enable();
	}	
}

public Action:Command_Disable(client, args) {

	if (enabled)
	{
		enabled = false;
		Disable();
	}	

}

public Action:ResetGlowColors(client, args) {

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidSurvivor(client, false) && ( client != thePrez))
		{

	    SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	    SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
	    SetEntProp(client, Prop_Send, "m_nGlowRange", 0);
	    SetEntProp(client, Prop_Send, "m_bFlashing", 0);

		}
	}

}

Enable() {

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_hurt", Player_Hurt);		
	HookEvent("player_death", Player_Death);
	HookEvent("defibrillator_used", Shock_Success);
	HookEvent("player_now_it", Event_PlayerBoomed);
	HookEvent("player_no_longer_it", Event_PlayerNoLongerBoomed);
	HookEvent("player_team", Event_PlayerTeam);
	
}

Disable() {

	UnhookEvent("round_start", Event_RoundStart);
	UnhookEvent("round_end", Event_RoundEnd);
	UnhookEvent("player_hurt", Player_Hurt);		
	UnhookEvent("player_death", Player_Death);
	UnhookEvent("defibrillator_used", Shock_Success);
	UnhookEvent("player_now_it", Event_PlayerBoomed);
	UnhookEvent("player_no_longer_it", Event_PlayerNoLongerBoomed);
	UnhookEvent("player_team", Event_PlayerTeam);

}

public void OnMapStart()
{
	PrecacheSound(SOUND_START);
	PrecacheSound(SOUND_DEATH);
}

public Event_RoundStart(Handle:event, String:event_name[], bool:dontBroadcast) {
	
	thePrez = 0;
	prezBoomed = false;
		
	CreateTimer(1.0, TimerLeftSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);	
	
}

public Action:TimerLeftSafeRoom(Handle:timer) {

	if (LeftStartArea()) 
	{ 
		new prez = RandomCandidate((GetConVarInt(prezSelectionType) == 2), false);
				
		if (prez == -1)
		{
			PrintToChatAll("Unable to get random survivor. \x05Protect The Prez\x01 is disabled");
			return;
		}
					
		SetThePrez(prez);
		SetSurvivorHealthCount();

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidSurvivor(client, false) && ( client != thePrez))
		{

	    SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	    SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
	    SetEntProp(client, Prop_Send, "m_nGlowRange", 0);
	    SetEntProp(client, Prop_Send, "m_bFlashing", 0);

		}
	}
				
	}
	else
	{
		CreateTimer(1.0, TimerLeftSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
	
}

void SetEntPropEx(int entity, PropType type, const char[] prop, any value, int size = 4, int element = 0)
{
	if(HasEntProp(entity, type, prop)) SetEntProp(entity, type, prop, value, size, element);
}

stock bool:LeftStartArea() {

	new maxents = GetMaxEntities();
	
	for (new i = MaxClients + 1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			decl String:netclass[64];
			
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				if (GetEntProp(i, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
				{
					return true;
				}
			}
		}
	}
	
	return false;
}

SetThePrez(client) {
	
	ResetAll();
		
	prevPrez[client] = true;
	thePrez = client;
	SetClientColors(thePrez, GetClientHealth(thePrez));
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	StripWeapons(thePrez);
	if (!GetConVarBool(prezCanHeal)) { RemoveItemFromSlot(thePrez, WEP_SLOT_HEALTH); }
	GiveHandgun(client, GetConVarBool(prezAllowMagnum)); 
	SetEntDataFloat(thePrez, movementOffset, GetConVarFloat(prezSpeedRatio), true);
	
	//PrintHintTextToAll("➤ El VIP \x05%N\x01 ha sido seleccionado \n Los supervivientes deben protegerlo, su daño es compartido entre todo el equipo.", thePrez);

	new Handle:event = CreateEvent("instructor_server_hint_create", true);
    SetEventString(event, "hint_name", "RandomHint");
    SetEventString(event, "hint_replace_key", "RandomHint");
    SetEventInt(event, "hint_target", thePrez);
    SetEventInt(event, "hint_activator_userid", 0);
    SetEventInt(event, "hint_timeout", 14 );
    SetEventString(event, "hint_icon_onscreen", "icon_shield");
    SetEventString(event, "hint_icon_offscreen", "icon_shield");
    SetEventString(event, "hint_caption", "¡Protege al Guardian, o perderán la pártida!");
    SetEventString(event, "hint_color", sColor);
    SetEventFloat(event, "hint_icon_offset", 0.0 );
    SetEventFloat(event, "hint_range", 0.0 );
    SetEventInt(event, "hint_flags", 1);// Change it..
    SetEventString(event, "hint_binding", "");
    SetEventBool(event, "hint_allow_nodraw_target", true);
    SetEventBool(event, "hint_nooffscreen", 0);
    SetEventBool(event, "hint_forcecaption", false);
    SetEventBool(event, "hint_local_player_only", false);
    FireEvent(event);

	for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {
            EmitSoundToClient(i, SOUND_START);
        }
        
    }
		
}

public Event_PlayerBoomed(Handle:event, String:event_name[], bool:dontBroadcast) {

	if (thePrez == 0) { return; }
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client == thePrez)
	{
		prezBoomed = true;
		SetClientColors(thePrez, GetClientHealth(thePrez));
	}
	
}

public Event_PlayerNoLongerBoomed(Handle:event, String:event_name[], bool:dontBroadcast) {

	if ((thePrez == 0) || (!prezBoomed)) { return; }
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client == thePrez)
	{
		prezBoomed = false;
		SetClientColors(thePrez, GetClientHealth(thePrez));
	}
	
}

public OnClientDisconnect(client) {

	if (client == thePrez)
	{ 
		ChangeThePrez(); 
	}

}

public Event_PlayerTeam(Handle:event, String:event_name[], bool:dontBroadcast) {

	if (thePrez == 0) { return; }
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client == thePrez)
	{ 
		if (GetEventBool(event, "disconnect") || (GetClientTeam(client) != TEAM_SURVIVOR))
		{
			ChangeThePrez();
		}			
	}
	
}

RemoveThePrez() {
		
	if (thePrez == 0) { return; }
	
	if (IsValidSurvivor(thePrez, false)) 
	{ 
		SetSkinColor(thePrez, PREZ_COLOR_NOCOLOR);
		SetGlowColor(thePrez, PREZ_COLOR_NOCOLOR);
		SetEntDataFloat(thePrez, movementOffset, 1.0 , true);
	}
	
	thePrez = 0;
	
}

ResetAll() {

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidSurvivor(i, false)) 
		{ 
			SetSkinColor(i, PREZ_COLOR_NOCOLOR);
			SetGlowColor(i, PREZ_COLOR_NOCOLOR);
			SetEntDataFloat(i, movementOffset, 1.0 , true);
		}
	}
	
}

//GetGlowDefaults(client) {
//
//	dfltGlow = GetEntProp(client, Prop_Send, "m_iGlowType");
//	dfltColor = GetEntProp(client, Prop_Send, "m_glowColorOverride");
//	dfltRange = GetEntProp(client, Prop_Send, "m_nGlowRange");
//	dfltFlash = GetEntProp(client, Prop_Send, "m_bFlashing");
//		
//	PrintToChatAll("Glow = %d, Color = %d, Range = %d, Flash = %d", dfltGlow, dfltColor, dfltRange, dfltFlash);
//	
//			
//}

SetGlowDefaults(client) {

	SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
	SetEntProp(client, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(client, Prop_Send, "m_bFlashing", 0);
	
}

ChangeThePrez() {

	RemoveThePrez();
				
	new prez = RandomCandidate((GetConVarInt(prezSelectionType) == 2), false);
				 
	if (prez == -1)
	{
		thePrez = 0;
		PrintToChatAll("Unable to get random survivor. \x05Protect The Prez\x01 is disabled");
	}
	else
	{
		SetThePrez(prez);
	}	

}



public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	
	prezRevived = true;
	prezBoomed = false;
	
	RemoveThePrez();
	
	ResetAll();
	
}

public Action:OnWeaponCanUse(client, weapon) {

	if (client != thePrez) { return Plugin_Continue; }
	
	decl String:wepclassname[32];
	GetEdictClassname(weapon, wepclassname, sizeof(wepclassname));

	//PrintToChatAll("Picked up %s", 	wepclassname);
	
	if (StrEqual("weapon_pistol", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_pistol_magnum", wepclassname, false))
	{
		if(GetConVarBool(prezAllowMagnum)) { return Plugin_Continue; }
	}
	else if (StrEqual("weapon_first_aid_kit", wepclassname, false))
	{
		if (GetConVarBool(prezCanHeal)) { return Plugin_Continue; }
	}
	else if (StrEqual("weapon_pipe_bomb", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_molotov", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_shotgun_chrome", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_smg_silenced", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_pumpshotgun", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_smg", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_vomitjar", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_pain_pills", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_adrenaline", wepclassname, false))
	{
		return Plugin_Continue;
	}	
	else if (StrEqual("weapon_defibrillator", wepclassname, false))
	{
		return Plugin_Continue;
	}	
	else if (StrEqual("weapon_gascan", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_propanetank", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_oxygentank", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_fireworkcrate", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_upgradepack_explosive", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_upgradepack_incendiary", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_gnome", wepclassname, false))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("weapon_cola_bottles", wepclassname, false))
	{
		return Plugin_Continue;
	}
		
	return Plugin_Handled;

}  

StripWeapons(client) {

	RemoveItemFromSlot(client, WEP_SLOT_PRIMARY);
	RemoveItemFromSlot(client, WEP_SLOT_MELEE);	
	if (!GetConVarBool(prezCanHeal))  { RemoveItemFromSlot(client, WEP_SLOT_HEALTH); }

}

stock RemoveItemFromSlot(client, slot) {

	new ent = GetPlayerWeaponSlot(client, slot);

	if( ent != -1 )
	{
		RemovePlayerItem(client, ent);
		//AcceptEntityInput(ent, "kill");
		//RemoveEdict(ent);
	}
	
}	

GiveHandgun(client, bool:giveMagnum) {
		
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	if (giveMagnum)
	{
		FakeClientCommand(client, "give pistol_magnum");
	}
	else
	{
		FakeClientCommand(client, "give pistol");
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);

}

public Action:Command_SelectPrez(client, args) {

	decl String:arg1[4];
	
	GetCmdArg(1, arg1, 4);
	
	new prez = StringToInt(arg1);
	
	if (IsValidSurvivor(prez, false) && ( prez != thePrez))
	{
		RemoveThePrez();
		SetThePrez(prez);
	}
	
	return Plugin_Handled;


}

SetClientColors(client, health) {

	if (IsIncapped(client) || IsHangingFromLedge(client))
	{
		SetSkinColor(client, PREZ_COLOR_LOWHEALTH);
		SetGlowColor(client, PREZ_COLOR_LOWHEALTH);
		return;
	}
		
	if (health < 25) 
	{
		SetSkinColor(client, PREZ_COLOR_LOWHEALTH);
		SetGlowColor(client, PREZ_COLOR_LOWHEALTH);	
	}
	else if (health < 40)
	{
		SetSkinColor(client, PREZ_COLOR_MEDHEALTH);
		SetGlowColor(client, PREZ_COLOR_MEDHEALTH);	
	}
	else
	{	
		SetSkinColor(client, PREZ_COLOR_FULLHEALTH);
		SetGlowColor(client, PREZ_COLOR_FULLHEALTH);	
	}
	
}

SetSkinColor(client, prezcolor) {

	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, skinRed[prezcolor], skinGreen[prezcolor], skinBlue[prezcolor], 255);
			
}

SetGlowColor(client, prezcolor) {
	
	if (prezcolor == PREZ_COLOR_NOCOLOR)
	{
		SetGlowDefaults(client);
		return;
	}
		
	new gcolor = prezBoomed ? glowColor[PREZ_COLOR_BOOMED] : glowColor[prezcolor] ;
			
	SetEntProp(client, Prop_Send, "m_iGlowType", 3);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", gcolor);
	SetEntProp(client, Prop_Send, "m_nGlowRange", 2048);
	SetEntProp(client, Prop_Send, "m_bFlashing", 1);
		
}

public Action:Player_Hurt(Handle:event, String:event_name[], bool:dontBroadcast) {

	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidSurvivor(userid, true)) { return; }
	
	// Don't forward or modify damage for incapped players
	if (IsIncapped(userid) || IsHangingFromLedge(userid)) 
	{ 
		if (thePrez == userid) { SetClientColors(thePrez, GetClientHealth(thePrez)); }
		return; 
	}
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	// If damage is friendly fire, leave it alone
	if (IsValidSurvivor(attacker, true)) 
	{ 
		if (thePrez == userid) { SetClientColors(thePrez, GetClientHealth(thePrez)); }
		return; 
	}
			
	new dmg = GetEventInt(event, "dmg_health");

	new health = GetEventInt(event, "health");
	
	// Get the healthe before damage
	new totalhealth = ((health + dmg) > 100) ? 100 : (health + dmg);
	
	// The Prez was hurt, hurt everyone
	if (thePrez == userid) 
	{ 
		new team_dmg = RoundToCeil(float(dmg) * GetConVarFloat(teamDmgRatio));
		
		DamageTeam(team_dmg, thePrez); 
		
		new prezdmg = RoundToCeil(float(dmg) / GetConVarFloat(prezHealthRatio));
		
		new preztotal = ((totalhealth - prezdmg) < 1) ? 1 : (totalhealth - prezdmg);
				
		SetEntityHealth(userid, preztotal);
		
		SetClientColors(thePrez, preztotal);
	
	}
	else
	{	
		new nrmldmg = RoundToCeil(float(dmg) * GetConVarFloat(normalDmgRatio));				
		
		new total = ((totalhealth - nrmldmg) < 1) ? 1 : (totalhealth - nrmldmg);
				
		SetEntityHealth(userid, total);
	}
	

}	

DamageTeam(damage, exception) {

	if (damage == 0) { return; }
	
	new health = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidSurvivor(i, true) && (exception != i))
		{
			if (!IsIncapped(i) && !IsHangingFromLedge(i))
			{
				health = GetSurvivorPermanentHealth(i);

				new total = ((health - damage) < 1) ? 1 : (health - damage);
													
				SetEntityHealth(i, total);
			}	
		}
	}
}

public Action:Shock_Success(Handle:event, const String:name[], bool:dontBroadcast) {

	new revived = GetClientOfUserId(GetEventInt(event, "subject"));
	
	if (IsValidSurvivor(revived, false) && (revived == thePrez))
	{
		prezRevived = true;
		//PrintToChatAll("The President has been saved. Yay you!");
		PrintHintTextToAll("El VIP Resucitó, safaron de pedo!");
	}
}	

public Action:Player_Death(Handle:event, String:event_name[], bool:dontBroadcast) {

	new deadman = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidSurvivor(deadman, false) && (deadman == thePrez))
	{ 	
		OpenAndLockDoor();
		prezRevived = false;
		deathTicks = GetConVarInt(prezDefibTime);
		PrintHintTextToAll("➤ EL VIP A MUERTO, Tienes %i segundos para revivirlo.", deathTicks);
		CreateTimer(0.1, PrezDeathTimer, 0, TIMER_FLAG_NO_MAPCHANGE);
	}

}

public Action:PrezDeathTimer(Handle:timer) {
	
	if (prezRevived) 
	{ 		
		UnlockDoor(lockedDoor);
		return Plugin_Stop; 
	}
	
	if (deathTicks > 15)
	{
		PrintHintTextToAll("➤ %i Segundos, SE MUEREE", deathTicks);
		deathTicks -= 5;
		CreateTimer(5.0, PrezDeathTimer, 0, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}
	else if (deathTicks > 0)
	{   
		// Don't need to announce 13, 12, etc...
		if (deathTicks <= 10) { PrintHintTextToAll("➤ %i Segundos :d", deathTicks); }
		deathTicks--;
		CreateTimer(1.0, PrezDeathTimer, 0, TIMER_FLAG_NO_MAPCHANGE);

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {
            EmitSoundToClient(i, SOUND_DEATH);
        }
        
    }

		return Plugin_Continue;
	}
	else
	{
		KillSurvivors(thePrez);
		PrintHintTextToAll("➤ EL VIP A MUERTO, nanana kickeénlo");
		return Plugin_Stop;
	}

}

stock KillSurvivors(exclude) {
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i == exclude) { continue; }
		
		if(IsClientInGame(i) && IsClientConnected(i) && (GetClientTeam(i) == TEAM_SURVIVOR))
		{
			ForcePlayerSuicide(i);
		}	
	}

}

stock GetSurvivorPermanentHealth(client) {

	return GetEntProp(client, Prop_Send, "m_iHealth");
	
}

stock bool:IsIncapped(client) {

	return (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1);
	
}

stock bool:IsHangingFromLedge(client) {

	return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 1);

}

stock bool:IsValidSurvivor(client, bool:allowbots) {

	if ((client < 1) || (client > MaxClients)) { return false; }
	if (!IsClientInGame(client) || !IsClientConnected(client)) { return false; }
	if (GetClientTeam(client) != TEAM_SURVIVOR) { return false; }
	if (IsFakeClient(client) && !allowbots) { return false; }
	
	return true;
	
}

// Get the first survivor (player or bot, doesn't matter)
stock RandomCandidate(bool:excludeprev, bool:allowbots) {

	new numSurvs = GetSurvivorCount() - GetPrevPrezCount();

	// If no new ones left, reset
	if (numSurvs <= 0)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidSurvivor(i, allowbots) && ( GetClientTeam(i) == TEAM_SURVIVOR))
			{
				prevPrez[i] = false;
			}
		}
		numSurvs = GetSurvivorCount();
	}
	
	new rndsurv = CreateRandomInt(1, numSurvs);
	
	new curr = 1;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		// If they have already been prez, skip them if indicated
		if (excludeprev && prevPrez[i]) { continue; }
		
		if (IsValidSurvivor(i, allowbots))
		{	
			if (curr == rndsurv) { return i; }
			curr++;
		}
	}
	
	return -1;
}

GetPrevPrezCount() {
	
	new count = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidSurvivor(i, false))
		{
			if (prevPrez[i] && GetClientTeam(i) == TEAM_SURVIVOR)
			{
				count++;
			}
		}
	}
	
	return count;
	
}

stock GetSurvivorCount() {
			
	new count=0;
	
	for (new i=1; i<=MaxClients; i++)
	{	
		if (IsValidSurvivor(i, false)) { count++; }
	}
		
	return count;

}

stock SetSurvivorHealthCount() {
			
for (new i = 1; i <= MaxClients; i++)
{
if(i != thePrez){
	SetEntPropEx(i, Prop_Send, "m_iMaxHealth", 50);
	SetEntPropEx(i, Prop_Send, "m_iHealth", 50);
	SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0);
	SetEntPropFloat(i, Prop_Send, "m_healthBufferTime", 0.0);
}
else
	if(i == thePrez){
	SetEntPropEx(i, Prop_Send, "m_iMaxHealth", 100);
	SetEntPropEx(i, Prop_Send, "m_iHealth", 100);
	SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0);
	SetEntPropFloat(i, Prop_Send, "m_healthBufferTime", 0.0);
}

}

}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("userid");
	int client = GetClientOfUserId(UserId);
	
	if ( IsClientInGame(client) && (GetClientTeam(client) == 2) && IsPlayerAlive(client) && (client != thePrez) )
	{

	SetEntPropEx(client, Prop_Send, "m_iMaxHealth", 50);
	//SetEntPropEx(client, Prop_Send, "m_iHealth", 50);
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", 0.0);
		
	}
	else
	if ( IsClientInGame(client) && (GetClientTeam(client) == 2) && IsPlayerAlive(client) && (client == thePrez) )
	{
	SetEntPropEx(client, Prop_Send, "m_iMaxHealth", 100);
	//SetEntPropEx(client, Prop_Send, "m_iHealth", 100);
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", 0.0);
	}

	return Plugin_Continue;
}

stock CreateRandomInt(min, max) {

	SetRandomSeed(RoundFloat(GetEngineTime() * 1000.0 * float(max)));
	return GetRandomInt(min, max);
	
}

public Action:Command_Lock(client, args) {

	OpenAndLockDoor();

}

public Action:Command_Unlock(client, args) {

	UnlockDoor(lockedDoor);

}

// Do this upon the Prez's incap/death
OpenAndLockDoor() {

	new ent = -1;
	
	// Finishing safe room door does not have an unlock sequence by default
	while ((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1)
	{
		if (GetEntProp(ent, Prop_Data, "m_hasUnlockSequence") == 0)
		{
			lockedDoor = ent;
			AcceptEntityInput(lockedDoor, "Open");
			AcceptEntityInput(lockedDoor, "Lock");
			SetEntProp(lockedDoor, Prop_Data, "m_hasUnlockSequence", 1);
			break;
		}
	}


}

UnlockDoor(door) {

	if (door == 0) { return; }
		
	SetEntProp(door, Prop_Data, "m_hasUnlockSequence", 0);
	AcceptEntityInput(door, "Unlock");
	
}







