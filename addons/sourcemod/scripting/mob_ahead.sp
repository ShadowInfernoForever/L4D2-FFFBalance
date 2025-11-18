#define PLUGIN_VERSION	"1.1"
#define PLUGIN_NAME		"Mob Ahead"
#define PLUGIN_PREFIX   "mob_ahead"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=347437"
};

ConVar C_ignore_in_last_check_point;
bool O_ignore_in_last_check_point;

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
    if(strcmp(key, "PreferredMobDirection") == 0)
    {
        if(O_ignore_in_last_check_point)
        {
            for(int client = 1; client <= MaxClients; client++)
            {
                if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && L4D_IsInLastCheckpoint(client))
                {
                    return Plugin_Continue;
                }
            }
        }
        retVal = 7;
        return Plugin_Handled;        
    }
    return Plugin_Continue;
}

void get_all_cvars()
{
    O_ignore_in_last_check_point = C_ignore_in_last_check_point.BoolValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_ignore_in_last_check_point)
    {
        O_ignore_in_last_check_point = C_ignore_in_last_check_point.BoolValue;
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    C_ignore_in_last_check_point = CreateConVar(PLUGIN_PREFIX ... "_ignore_in_last_check_point", "1", "1 = enable, 0 = disable. ignore if there is any survivor in the last check point to prevent mob spawn in dead corners of check point");
    C_ignore_in_last_check_point.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, PLUGIN_PREFIX);
    get_all_cvars();
}