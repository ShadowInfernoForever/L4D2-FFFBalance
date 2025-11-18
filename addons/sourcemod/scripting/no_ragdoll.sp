#define PLUGIN_VERSION  "1.0"
#define PLUGIN_NAME     "No Ragdoll"
#define PLUGIN_PREFIX	"no_ragdoll"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=346535"
};

bool Map_started;
int Fader = -1;

void remove_ref(int& ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity != -1)
    {
        RemoveEdict(entity);
    }
    ref = -1;
}

void create_fader()
{
    int fader = CreateEntityByName("func_ragdoll_fader");
    if(fader != -1)
    {
        Fader = EntIndexToEntRef(fader);
        DispatchSpawn(fader);
		SetEntPropVector(fader, Prop_Send, "m_vecMaxs", view_as<float>({999999.0, 999999.0, 999999.0}));
		SetEntPropVector(fader, Prop_Send, "m_vecMins", view_as<float>({-999999.0, -999999.0, -999999.0}));
		SetEntProp(fader, Prop_Send, "m_nSolidType", 2);
    }
}

public void OnMapStart()
{
    Map_started = true;
    remove_ref(Fader);
    create_fader();
}

public void OnMapEnd()
{
    Map_started = false;
    remove_ref(Fader);
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    remove_ref(Fader);
    if(Map_started)
    {
        create_fader();
    }
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
    HookEvent("round_start", event_round_start); 

    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
}

public void OnPluginEnd()
{
    remove_ref(Fader);
}