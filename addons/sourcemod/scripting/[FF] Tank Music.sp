#define PLUGIN_VERSION "1.3.3"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS		FCVAR_NOTIFY
#define TRACKS_PER_MAP 6
#define SNDCHAN_DEFAULT SNDCHAN_AUTO // or SNDCHAN_AUTO ?
#define DEBUG 1

public Plugin myinfo = 
{
	name = "Tank Wave Sound",
	author = "Dragokas (halloween edition)",
	description = "Play sound on tank wave / last finale tank",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
	//requrements: "Left 4 Dragokas\", https://forums.alliedmods.net/showthread.php?p=2681138
}

char FILE_TANK_WAVE_SOUNDS[PLATFORM_MAX_PATH]		= "data/tank_wave_sounds.txt";
char FILE_TANK_FINALE_SOUNDS[PLATFORM_MAX_PATH]		= "data/tank_finale_sounds.txt";

int g_iTankCount;
int g_idxSndTank = -1;
int g_iSubIdxSndTank = -1;
int g_idxSndWin = -1;
ArrayList g_SoundTank;
ArrayList g_SoundFinale;
char g_sSoundPath[TRACKS_PER_MAP][PLATFORM_MAX_PATH];
bool g_bIsFinale, g_bLeft4Dead2;
ConVar 	g_hCvarEnable, g_hCvarWaveMusic, g_hCvarFinaleMusic;
int iLastPlayed;
EngineVersion g_Engine;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_Engine = GetEngineVersion();
	if( g_Engine == Engine_Left4Dead2 ) {
		g_bLeft4Dead2 = true;
	}
	else if( g_Engine != Engine_Left4Dead ) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	if( !LibraryExists("left4dragokas") )
	{
		SetFailState("You failed at installing! Required library is missing: \"Left 4 Dragokas\": https://forums.alliedmods.net/showthread.php?p=2681138");
	}

	g_hCvarEnable 			= CreateConVar(	"l4d_tank_wave_sound_enable",			"1",	"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS );
	g_hCvarWaveMusic		= CreateConVar(	"l4d_tank_wave_sound_wave_enable",		"1",	"Enable tank wave sound (1 - On / 0 - Off)", CVAR_FLAGS );
	g_hCvarFinaleMusic		= CreateConVar(	"l4d_tank_wave_sound_finale_enable",	"1",	"Enable last tank kill sound on finales (1 - On / 0 - Off)", CVAR_FLAGS );
	
	CreateConVar("l4d_tank_wave_sound_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD );
	
	AutoExecConfig(true,			"l4d_tank_wave_sound");
	
	#if DEBUG
	RegAdminCmd("sm_fin", CmdFin, ADMFLAG_ROOT);
	#endif
	
	BuildPath(Path_SM, FILE_TANK_WAVE_SOUNDS, sizeof(FILE_TANK_WAVE_SOUNDS), FILE_TANK_WAVE_SOUNDS);
	BuildPath(Path_SM, FILE_TANK_FINALE_SOUNDS, sizeof(FILE_TANK_FINALE_SOUNDS), FILE_TANK_FINALE_SOUNDS);
	
	g_SoundTank = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	g_SoundFinale = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	
	HookConVarChange(g_hCvarEnable,			ConVarChanged);
	GetCvars();
}

void ReadFileToArrayList(char[] sPath, ArrayList list, bool bClearList = true)
{
	static char str[MAX_NAME_LENGTH];
	File hFile = OpenFile(sPath, "r");
	if( hFile == null )
	{
		SetFailState("Failed to open file: \"%s\". You are missing at installing!", sPath);
	}
	else {
		if( bClearList )
		{
			list.Clear();
		}
		while( !hFile.EndOfFile() && hFile.ReadLine(str, sizeof(str)) )
		{
			TrimString(str);
			if( str[0] != 0 )
			{
				if( str[0] != '/' && str[1] != '/' )
				{
					list.PushString(str);
				}
			}
		}
		delete hFile;
	}
}

void LoadMusicTank()
{
	ReadFileToArrayList(FILE_TANK_WAVE_SOUNDS, g_SoundTank);
}

void LoadMusicFinale()
{
	ReadFileToArrayList(FILE_TANK_FINALE_SOUNDS, g_SoundFinale);
}

#if DEBUG
public Action CmdFin(int client, int args)
{
	PrintToChat(client, "Is Finale? %b", g_bIsFinale);
	for( int i = 0; i < sizeof(g_sSoundPath); i++ )
	{
		if( g_sSoundPath[i][0] != 0 )
		{
			PrintToChat(client, "sound[%i]: %s", i, g_sSoundPath[i]);
		}
	}
	Event ev = CreateEvent("finale_escape_start", false);
	ev.Fire();
	g_iTankCount = 0;
	OnTankCountChanged(1);
	return Plugin_Handled;
}
#endif

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	InitHook();
}

public void OnTankCountChanged(int iCount)
{
	if (iCount == 1 && g_iTankCount == 0 ) //&& !IsFirstMap())
		OnFirstTankSpawn();
	
	g_iTankCount = iCount;
}

public void OnMapStart()
{
	static char sDLPath[PLATFORM_MAX_PATH];
	
	static char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	
	iLastPlayed = 0;
	
	g_bIsFinale = false;
	
	if (
		StrEqual(sMap, "l4d_hospital05_rooftop") ||
		StrEqual(sMap, "l4d_garage02_lots") ||
		StrEqual(sMap, "l4d_smalltown05_houseboat") ||
		StrEqual(sMap, "l4d_airport05_runway") ||
		StrEqual(sMap, "l4d_farm05_cornfield") ||
		StrEqual(sMap, "c1m4_atrium") ||
		StrEqual(sMap, "c2m5_concert") ||
		StrEqual(sMap, "c3m4_plantation") ||
		StrEqual(sMap, "c4m5_milltown_escape") ||
		StrEqual(sMap, "c5m5_bridge") ||
		StrEqual(sMap, "c6m3_port") ||
		StrEqual(sMap, "c7m3_port") ||
		StrEqual(sMap, "c8m5_rooftop") ||
		StrEqual(sMap, "c9m2_lots") ||
		StrEqual(sMap, "c10m5_houseboat") ||
		StrEqual(sMap, "c11m5_runway") ||
		StrEqual(sMap, "C12m5_cornfield") ||
		StrEqual(sMap, "c13m4_cutthroatcreek") ||
		StrEqual(sMap, "l4d_river03_port")
		) {
		g_bIsFinale = true;
	}
	
	if( !g_bIsFinale )
	{
		g_bIsFinale = (-1 != FindEntityByClassname(-1, "trigger_finale"));
	}
	
	for( int i = 0; i < sizeof(g_sSoundPath); i++ )
	{
		g_sSoundPath[i][0] = '\0';
	}
	
	if (g_bIsFinale)
	{
		if( g_hCvarWaveMusic.BoolValue) 
		{
			if (g_idxSndWin != -1 && g_SoundFinale.Length > 0)
			{
				g_SoundFinale.Erase(g_idxSndWin);
			}
			
			if (g_SoundFinale.Length == 0)
			{
				LoadMusicFinale();
			}
			g_idxSndWin = GetRandomInt(0, g_SoundFinale.Length - 1);
			g_SoundFinale.GetString(g_idxSndWin, g_sSoundPath[0], sizeof(g_sSoundPath[]));
		}
	}
	else {
		if( g_hCvarFinaleMusic.BoolValue )
		{
			for( int i = 0; i < sizeof(g_sSoundPath); i++ )
			{
				GetNextTankSound(g_sSoundPath[i], sizeof(g_sSoundPath[]));
			}
		}
	}
	
	for( int i = 0; i < sizeof(g_sSoundPath); i++ )
	{
		if( g_sSoundPath[i][0] != 0 )
		{
			Format(sDLPath, sizeof(sDLPath), "sound/%s", g_sSoundPath[i]);
			//AddFileToDownloadsTable(sDLPath);
			PrecacheSound(g_sSoundPath[i], true);
		}
	}
}

void GetNextTankSound(char[] sound, int length)
{
	if (g_idxSndTank != -1 && g_SoundTank.Length > 0)
	{
		g_SoundTank.Erase(g_idxSndTank);
	}
	if (g_SoundTank.Length == 0)
	{
		LoadMusicTank();
	}
	g_idxSndTank = GetRandomInt(0, g_SoundTank.Length - 1);
	g_SoundTank.GetString(g_idxSndTank, sound, length);
}

void InitHook()
{
	static bool bHooked;
	
	if (g_hCvarEnable.BoolValue) {
		if (!bHooked) {
			HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
			HookEvent("finale_escape_start",	Event_EscapeStart,	EventHookMode_PostNoCopy);
			bHooked = true;
		}
	} else {
		if (bHooked) {
			UnhookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
			UnhookEvent("finale_escape_start",	Event_EscapeStart,	EventHookMode_PostNoCopy);
			bHooked = false;
		}
	}
}

public void Event_EscapeStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_bIsFinale )
	{
		if( g_hCvarFinaleMusic.BoolValue )
		{
			if( g_sSoundPath[0][0] != '\0' )
			{
				CreateTimer(1.0, Timer_PlayeFinaleSound);
			}
		}
	}
}

public Action Timer_PlayeFinaleSound(Handle timer)
{
	if( iLastPlayed == 0 || GetTime() - iLastPlayed > 60 )
	{
		#if DEBUG
		PrintToChatAll("Playing: %s", g_sSoundPath[0]);
		#endif
		EmitSoundCustomToAll(g_sSoundPath[0]);
		iLastPlayed = GetTime();
	}
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iTankCount = 0;
}

void OnFirstTankSpawn()
{
	if (!g_bIsFinale)
	{
		if( g_hCvarWaveMusic.BoolValue )
		{
			CreateTimer(0.5, Timer_PlayerTankWaveIfExist, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_PlayerTankWaveIfExist(Handle timer)
{
	if( TankExist() )
	{
		if( iLastPlayed == 0 || GetTime() - iLastPlayed > 60 )
		{
			g_iSubIdxSndTank ++;
			if( g_iSubIdxSndTank >= sizeof(g_sSoundPath) )
			{
				g_iSubIdxSndTank = 0;
			}
			if (g_sSoundPath[g_iSubIdxSndTank][0] != '\0')
			{
				#if DEBUG
				PrintToChatAll("Playing: %s", g_sSoundPath[g_iSubIdxSndTank]);
				#endif
				EmitSoundCustomToAll(g_sSoundPath[g_iSubIdxSndTank]);
			}
		}
		iLastPlayed = GetTime();
	}
	return Plugin_Continue;
}

bool TankExist()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsTank(i) )
		{
			return true;
		}
	}
	return false;
}

stock bool IsTank(int client)
{
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == (g_bLeft4Dead2 ? 8 : 5 ))
			return true;
	}
	return false;
}

void EmitSoundCustomToAll(const char[] sound, 
	int entity = SOUND_FROM_PLAYER,
	int channel = SNDCHAN_DEFAULT,
	int level = SNDLEVEL_GUNFIRE,
	int flags = SND_NOFLAGS,
	float volume = SNDVOL_NORMAL,
	int pitch = SNDPITCH_NORMAL,
	int speakerentity = -1,
	const float origin[3] = NULL_VECTOR,
	const float dir[3] = NULL_VECTOR,
	bool updatePos = true,
	float soundtime = 0.0)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			EmitSoundCustom(i, sound, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
		}
	}
}

void EmitSoundCustom(
	int client, 
	const char[] sound, 
	int entity = SOUND_FROM_PLAYER,
	int channel = SNDCHAN_DEFAULT,
	int level = SNDLEVEL_GUNFIRE,
	int flags = SND_NOFLAGS,
	float volume = SNDVOL_NORMAL,
	int pitch = SNDPITCH_NORMAL,
	int speakerentity = -1,
	const float origin[3] = NULL_VECTOR,
	const float dir[3] = NULL_VECTOR,
	bool updatePos = true,
	float soundtime = 0.0)
{
	int clients[1];
	clients[0] = client;
	
	if (g_Engine == Engine_Left4Dead || g_Engine == Engine_Left4Dead2)
		level = SNDLEVEL_GUNFIRE;
		
	EmitSoundToClient(clients, sound, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}