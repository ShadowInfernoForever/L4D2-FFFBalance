#define PLUGIN_VERSION		"1.3 beta"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY

#define DEBUG 0

public Plugin myinfo =
{
	name = "[L4D] Custom Skybox Manager",
	author = "Dragokas",
	description = "Set and manage custom skyboxes (with partial delayed downloader support)",
	version = PLUGIN_VERSION,
	url = "http://github.com/dragokas"
}

/*
	ChangeLog:
	
	1.0 alpha (01-Jan-2020)
	 - Concept release (technical demo)
	 
	1.1 beta (26-Mar-2020)
	 - Added support for all games.
	 - No need to define default skybox anymore. It is detected automatically.
	 - No need to list all default skyboxes. They are detected automatically.
	
	1.2 beta (18-Oct-2021)
	 - No need to list the names of custom skyboxes. They can be detected automatically.
	 - Added Convar "l4d_skybox_random" - Select skybox in random order? (1 - Yes, 0 - No)
	 - Added ConVar "l4d_skybox_autoadd" - Add the list of custom skyboxes automatically? (1 - Yes, 0 - You must specify each skybox name manually)
	
	1.3 beta (20-Nov-2021)
	 - Added "sm_skylock" command to lock current skybox for using on the next map.
	 - Added menu on "sm_sky" allowing to select an arbitary skybox to load on the next map.
	
	1.4 beta (28-Jan-2022)
	 - Tidy up the code a little bit.
	
	 TODO:
	 - Transitional player is detected; timers are removed. How to send different cvar values for diff. users on very early stage ? Need testers.
*/

ConVar g_hCvarSkyName, g_hCvarSkyRandom; //, g_hCvarSkyAutoAdd;
char g_sSkyBox[64], g_sSkyBoxDefault[64], g_sMap[64];
StringMap hMapSky, hMapSkyCustom;
ArrayList g_aSky;
int g_iSky = -1;
bool g_bSkyLock, g_bLateload;
KeyValues g_kvForbidden;
//bool g_bFirstConnect[MAXPLAYERS+1] = {true, ...};
//bool g_bTransitional[MAXPLAYERS+1];
//bool g_bOverride; //[MAXPLAYERS+1];

/*
public Action OnClientPreConnect(char[] name, const char[] password, const char[] ip, const char[] steamID, char rejectReason[255])
{
	PrintToServer("Name=%s, password=%s, IP=%s, steamID=%s", name, password, ip, steamID);
	FormatEx(rejectReason, sizeof(rejectReason), "%s", "#Valve_Reject_Server_Full");
	return Plugin_Stop;
}
*/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_skybox_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	g_hCvarSkyRandom 	= CreateConVar("l4d_skybox_random", 	"0", 	"Select skybox in random order? (1 - Yes, 0 - No, change sequentially)", FCVAR_NOTIFY);
	//g_hCvarSkyAutoAdd 	= CreateConVar("l4d_skybox_autoadd", 	"1", 	"Add the list of custom skyboxes automatically? (1 - Yes, 0 - You must specify each skybox name manually)", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d_skybox");
	
	hMapSky = new StringMap();
	hMapSkyCustom = new StringMap();
	GetSkyBoxes();
	
	g_hCvarSkyName = FindConVar("sv_skyname");
	g_aSky = new ArrayList(ByteCountToCells(64));
	
	char sList[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sList, PLATFORM_MAX_PATH, "data/sky_forbidden.txt");
	g_kvForbidden = new KeyValues("forbidden");
	g_kvForbidden.ImportFromFile(sList);
	
	RegAdminCmd("sm_sky",		CmdSkyName, 	ADMFLAG_ROOT, 		"Show current sky name, and show menu to select skybox for the next map");
	RegAdminCmd("sm_skylock",	CmdSkyLock,		ADMFLAG_ROOT, 		"Make skybox to not change on the next map");
}

public Action CmdSkyName(int client, int args)
{
	if( g_sSkyBox[0] == 0 )
	{
		g_hCvarSkyName.GetString(g_sSkyBox, sizeof g_sSkyBox);
	}
	PrintToChat(client, "Current skybox name: \x05%s \x03(%i/%i)", g_sSkyBox, g_iSky, g_aSky.Length);
	ShowSkyMenu(client);
	
	return Plugin_Handled;
}

void ShowSkyMenu(int client)
{
	Menu menu = new Menu(MenuHandler_SelectSky, MENU_ACTIONS_DEFAULT);	
	menu.SetTitle("Select sky for the next map");
	
	char sSky[64];
	StringMapSnapshot hSnap = hMapSkyCustom.Snapshot();
	
	for (int i = 0; i < hSnap.Length; i++ )
	{
		hSnap.GetKey(i, sSky, sizeof sSky);
		menu.AddItem(sSky, sSky);
	}
	delete hSnap;
	menu.Display(client, MENU_TIME_FOREVER);
}


public int MenuHandler_SelectSky(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Select:
		{
			int client = param1;
			int ItemIndex = param2;
			
			char sSky[64];
			menu.GetItem(ItemIndex, sSky, sizeof(sSky));
			PrintToChat(client, "\x04%s\x01 is selected for the next map.", sSky);
			strcopy(g_sSkyBox, sizeof(g_sSkyBox), sSky);
			g_bSkyLock = true;
		}
	}
}

public Action CmdSkyLock(int client, int args)
{
	if( g_sSkyBox[0] == 0 )
	{
		g_hCvarSkyName.GetString(g_sSkyBox, sizeof g_sSkyBox);
	}
	PrintToChat(client, "Current skybox is locked for the next map: \x05%s", g_sSkyBox);
	g_bSkyLock = true;
	return Plugin_Handled;
}

/*
public Action CmdSkyOver(int client, int args)
{
	SendConVarValue(client, g_hCvarSkyName, "test_moon_hdr");
	return Plugin_Handled;
}
*/

/*
public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bFirstConnect[client] = true;
	g_bTransitional[client] = false;
}

public void OnClientConnected(int client)
{
	if( g_bFirstConnect[client] )
	{
		g_bFirstConnect[client] = false;
		g_bTransitional[client] = false;
	}
	else {
		g_bTransitional[client] = true;
	}
}

void ApplyClientSky(int client)
{
	if( client && !IsFakeClient(client) )
	{
		if( g_bTransitional[client] )
		{
			SendConVarValue(client, g_hCvarSkyName, "test_moon_hdr");
		}
		else {
			SendConVarValue(client, g_hCvarSkyName, "sky_day01_09_hdr");
		}
	}
}

void ApplyClientSkyAll()
{
	for( int i = 1; i <= MaxClients; i++)
	{
		if( IsClientConnected(i) && !IsFakeClient(i) )
		{
			ApplyClientSky(i);
		}
	}
}
*/

/*
public void OnGameFrame()
{
	
	for( int i = 1; i <= MaxClients; i++)
	{
		if( g_bOverride[i] )
		{
			ApplyClientSky(i);
		}
	}
	
	if( g_bOverride )
	{
		ApplyClientSkyAll();
	}
}
*/

void LoadSky()
{
	g_aSky.Clear();
	
	//if( g_hCvarSkyAutoAdd.BoolValue )
	{
		char sSky[64];
		StringMapSnapshot hSnap = hMapSkyCustom.Snapshot();
		
		for (int i = 0; i < hSnap.Length; i++ )
		{
			hSnap.GetKey(i, sSky, sizeof sSky);
			PrintToServer(sSky);
			g_aSky.PushString(sSky);
		}
		delete hSnap;
		return;
	}
	
	//g_aSky.PushString("galaxy_arm"); // 5+
	//g_aSky.PushString("bright_stars"); // 5
	//g_aSky.PushString("inside_forest"); // 5+
	//g_aSky.PushString("cyan_clouds"); // 5
	//g_aSky.PushString("nightocean"); // 5+
	//g_aSky.PushString("sky_l4d_rural231_hdr"); // 5+
	//g_aSky.PushString("violet_stars"); // 5
	//g_aSky.PushString("mpa112"); // 5+
	//g_aSky.PushString("sky_day231_hdr"); // 5+
	//g_aSky.PushString("sky_day01_09_hdr");
	//g_aSky.PushString("urbannightburning_hdr");
	//g_aSky.PushString("urbannightstormhdr"); 
	//g_aSky.PushString("orange_apocalypsis"); // 5- 
	//g_aSky.PushString("star_lights"); // 5 
	//g_aSky.PushString("cloudynight"); // + ??? 
	//g_aSky.PushString("white_sky"); // 5 
	//g_aSky.PushString("pink_nebula"); // 4
	//g_aSky.PushString("blue_shine"); // 4-
	//g_aSky.PushString("evening_lights");
	//g_aSky.PushString("snow_birth_forest");
	//g_aSky.PushString("snow_bridge");
	//g_aSky.PushString("snow_pine_tree");
	//g_aSky.PushString("supernova_nebula"); // 4
	//g_aSky.PushString("underwater_corals");
	//g_aSky.PushString("green_paradise");
	//g_aSky.PushString("purple_way");
	//g_aSky.PushString("blinding_stars"); // 4+
	//g_aSky.PushString("evening_lights_xmas2020");
}

public void OnMapStart()
{
	if( g_bLateload )
	{
		g_bLateload = false;
		return;
	}
	GetCurrentMap(g_sMap, sizeof(g_sMap));
	SelectSkybox();
}

void SelectSkybox()
{
	static int iCalls;
	++ iCalls;
	if( iCalls > hMapSkyCustom.Size ) // prevent infinite recursion
	{
		iCalls = 0;
		return;
	}
	
	//g_bSkyLock = true;

	if( g_bSkyLock && g_sSkyBox[0] == 0 )
	{
		g_bSkyLock = false;
	}
	if( g_bSkyLock )
	{
		g_bSkyLock = false;
	}
	else {
		if( g_iSky != -1 )
		{
			g_aSky.Erase(g_iSky);
		}
		else {
			g_iSky = 0;
		}
		if( g_aSky.Length == 0 )
		{
			LoadSky();
		}
		
		if( g_hCvarSkyRandom.BoolValue )
		{
			g_iSky = GetRandomInt(0, g_aSky.Length - 1);
		}
		
		g_aSky.GetString(g_iSky, g_sSkyBox, sizeof(g_sSkyBox));
		
		if( IsDefaultSkybox(g_sSkyBox) )
		{
			// is Sacrifice?
			if( strcmp(g_sMap, "l4d_river01_docks") == 0
			||	strcmp(g_sMap, "l4d_river02_barge") == 0
			||	strcmp(g_sMap, "l4d_river03_port") == 0 )
			{
				SelectSkybox();
				return;
			}
		}
		if( !IsMapComply(g_sSkyBox) )
		{
			SelectSkybox();
			return;
		}
	}
	
	//DownloadSkyboxes();
	
	g_hCvarSkyName.GetString(g_sSkyBoxDefault, sizeof(g_sSkyBoxDefault));
	SetSkyname(g_sSkyBox);
	iCalls = 0;
	
	// Once after all players are transitioned, load the default skybox
	// So, the newly connected players with erased string table (via DD) will see default skybox, instead of pink textures
	CreateTimer(30.0, Timer_DeafultSky, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DeafultSky(Handle timer)
{
	CreateTimer(5.0, Timer_WaitConnection, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action Timer_WaitConnection(Handle timer)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if (IsClientConnected(i) && !IsClientInGame(i))
			return Plugin_Continue;
			
		if (IsClientInGame(i) && GetClientTeam(i) == 0)
			return Plugin_Continue;
	}
	
	if( g_sSkyBoxDefault[0] )
	{
		g_hCvarSkyName.SetString(g_sSkyBoxDefault);
	}
	return Plugin_Stop;
}

void GetSkyBoxes()
{
	int iLen;
	char sSky[64];
	FileType fileType;
	DirectoryListing hDir;
	
	hDir = OpenDirectory("materials/skybox", true, NULL_STRING); // virtual + real
	if( hDir )
	{
		while( hDir.GetNext(sSky, sizeof sSky, fileType))
		{
			if( fileType == FileType_File )
			{
				iLen = strlen(sSky);
				
				if( iLen > 6 )
				{
					sSky[iLen - 6] = '\0';
					hMapSky.SetValue(sSky, 1);
				}
			}
		}
		delete hDir;
	}
	
	hDir = OpenDirectory("materials/skybox", false, NULL_STRING); // -remove real
	if( hDir )
	{
		while( hDir.GetNext(sSky, sizeof(sSky), fileType))
		{
			if( fileType == FileType_File )
			{
				iLen = strlen(sSky);
				
				if( iLen > 6 )
				{
					sSky[iLen - 6] = '\0';
					hMapSky.Remove(sSky);
					hMapSkyCustom.SetValue(sSky, 1);
					//PrintToServer("Added sky: %s", sSky);
				}
			}
		}
		delete hDir;
	}
}

stock bool IsDefaultSkybox(char[] sSky)
{
	int v;
	return hMapSky.GetValue(sSky, v);
}

void SetSkyname(char[] sSky)
{
	if( sSky[0] != '\0' )
	{
		g_hCvarSkyName.SetString(sSky);
	}
}

stock bool IsClientTransitional()
{
	// you can find out it via "player_transitioned" event.
}

bool IsMapComply(char[] sSky)
{
	g_kvForbidden.Rewind();
	if( g_kvForbidden.JumpToKey(g_sMap, false) )
	{
		int value = g_kvForbidden.GetNum(sSky);
		if( value == 1 )
		{
			return false;
		}
	}
	return true;
}
