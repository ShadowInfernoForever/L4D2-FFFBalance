#define PLUGIN_VERSION  "1.4"
#define PLUGIN_NAME     "Survival"
#define PLUGIN_PREFIX	"survival"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>
#include <4v4_arena>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=346636"
};

GlobalForward Forward_OnWin;

ConVar C_defend_by_attack_tank_threshold;
int O_defend_by_attack_tank_threshold;
ConVar C_defend_by_attack_tank_value;
float O_defend_by_attack_tank_value;
ConVar C_defend_by_attack_tank_duration;
float O_defend_by_attack_tank_duration;

int O_defend_by_attack_tank_value_round_to_floor;

bool Started;
bool Swapped[MAXPLAYERS+1];
int Damage_to_tank[MAXPLAYERS+1];
float Defend_end_time[MAXPLAYERS+1] = {-1.0, ...};

bool Late_load;

int get_idled_of_bot(int bot)
{
    if(!HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
    {
        return -1;
    }
	return GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
}

public void OnMapStart()
{
    Started = false;
    reset_all();
}

public void OnMapEnd()
{
    Started = false;
    reset_all();
}

void reset_player(int client, bool swap_reset = false)
{
    if(swap_reset)
    {
        Swapped[client] = false;
    }
    Damage_to_tank[client] = 0;
    Defend_end_time[client] = -1.0;
}

void reset_all()
{
    for(int client = 1; client <= MAXPLAYERS; client++)
    {
        reset_player(client, true);
    }
}

public void OnClientDisconnect_Post(int client)
{
    reset_player(client, true);
}

void end_round()
{
    int flags = GetCommandFlags("scenario_end");
    SetCommandFlags("scenario_end", flags & ~(FCVAR_CHEAT | FCVAR_DEVELOPMENTONLY));
    ServerCommand("scenario_end");
    ServerExecute();
    SetCommandFlags("scenario_end", flags);
}

bool is_survivor_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, on_take_damage_unstarted);
    SDKHook(client, SDKHook_OnTakeDamage, on_take_damage_defend);
}

bool is_trigger_hurt(int entity)
{
    if(entity == -1)
    {
        return false;
    }
    char class_name[PLATFORM_MAX_PATH];
    GetEntityClassname(entity, class_name, sizeof(class_name));
    return strncmp(class_name, "trigger_hurt", 12) == 0;
}

public Action L4D2_OnJockeyRide(int victim, int attacker)
{
    if(!Started)
    {
        if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
        {
            ForcePlayerSuicide(attacker);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action L4D_OnPouncedOnSurvivor(int victim, int attacker)
{
    if(!Started)
    {
        if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
        {
            ForcePlayerSuicide(attacker);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action L4D2_OnStartCarryingVictim(int victim, int attacker)
{
    if(!Started)
    {
        if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
        {
            ForcePlayerSuicide(attacker);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action L4D2_OnPummelVictim(int attacker, int victim)
{
    if(!Started)
    {
        if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
        {
            ForcePlayerSuicide(attacker);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion)
{
    if(!Started)
    {
        if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
        {
            ForcePlayerSuicide(attacker);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action L4D_OnGrabWithTongue(int victim, int attacker)
{
    if(!Started)
    {
        if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
        {
            ForcePlayerSuicide(attacker);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

Action on_take_damage_unstarted(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(Started)
    {
        return Plugin_Continue;
    }
    if(GetClientTeam(victim) == 2 && !(damagetype & DMG_DROWN) && !(damagetype & DMG_FALL) && !is_trigger_hurt(attacker))
    {
        damage = 0.0;
        return Plugin_Handled;
    }
	return Plugin_Continue;
}

Action on_take_damage_defend(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(damage >= 1.0 && Defend_end_time[victim] > GetGameTime() && GetClientTeam(victim) == 2 && IsPlayerAlive(victim) && !(damagetype & DMG_DROWN) && !(damagetype & DMG_FALL) && !is_trigger_hurt(attacker))
    {
        damage *= O_defend_by_attack_tank_value;
        if(damage < 1.0)
        {
            damage = 1.0;
        }
        return Plugin_Changed;
    }
	return Plugin_Continue;
}

void check_alive()
{
    bool yellow_alive = false;
    bool green_alive = false;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && is_survivor_alright(i))
        {
            switch(SurvivorArena_GetTeam(i))
            {
                case 1:
                {
                    green_alive = true;
                }
                case 2:
                {
                    yellow_alive = true;
                }
            }
        }
    }
    int win_team = 0;
    if(yellow_alive && !green_alive)
    {
        PrintToChatAll("%t", "survival_win_yellow");
        win_team = 2;
    }
    else if(green_alive && !yellow_alive)
    {
        PrintToChatAll("%t", "survival_win_green");
        win_team = 1;
    }
    if(win_team != 0)
    {
        end_round();
        Started = false;
        Call_StartForward(Forward_OnWin);
        Call_PushCell(win_team);
        Call_Finish();
    }
}

void event_player_hurt(Event event, const char[] name, bool dontBroadcast)
{
    if(!Started || O_defend_by_attack_tank_threshold < 1)
    {
        return;
    }
    int dmg = event.GetInt("dmg_health");
    if(dmg < 1)
    {
        return;
    }
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client != 0 && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
    {
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        if(attacker != 0 && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsPlayerAlive(attacker))
        {
            Damage_to_tank[attacker] += dmg;
            if(Damage_to_tank[attacker] >= O_defend_by_attack_tank_threshold)
            {
                Damage_to_tank[attacker] -= O_defend_by_attack_tank_threshold;
                Defend_end_time[attacker] = GetGameTime() + O_defend_by_attack_tank_duration;
                if(!IsFakeClient(attacker))
                {
                    PrintToChat(attacker, "%T", "survival_defend_buff_get", client, O_defend_by_attack_tank_threshold, O_defend_by_attack_tank_duration, O_defend_by_attack_tank_value_round_to_floor);
                }
            }
        }
    }
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    reset_all();
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client != 0)
    {
        reset_player(client);
    }
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client != 0)
    {
        reset_player(client);
    }
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client != 0)
    {
        reset_player(client);
    }
    check_alive();
}

void data_trans(int client, int prev)
{
    Damage_to_tank[client] = Damage_to_tank[prev];
    Defend_end_time[client] = Defend_end_time[prev];
}

void event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("bot"));
	if(client != 0)
	{
		int prev = GetClientOfUserId(event.GetInt("player"));
		if(prev != 0)
		{
			data_trans(client, prev);
		}
	}
}

void event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client != 0)
	{
		int prev = GetClientOfUserId(event.GetInt("bot"));
		if(prev != 0)
		{
			data_trans(client, prev);
		}
	}
}

void event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
    check_alive();
}

void event_player_ledge_grab(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
    check_alive();
}

void event_survival_round_start(Event event, const char[] name, bool dontBroadcast)
{
    Started = true;
}

void event_round_end(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
}

void event_mission_lost(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
}

Action cmd_arenateam(int client, int args)
{
    if(client == 0 || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2)
    {
        ReplyToCommand(client, "%T", "survival_swap_invalid", client);
        return Plugin_Handled;
    }
    int self_team = SurvivorArena_GetTeam(client);
    if(self_team == 0)
    {
        ReplyToCommand(client, "%T", "survival_swap_invalid", client);
        return Plugin_Handled;
    }
    if(Swapped[client])
    {
        ReplyToCommand(client, "%T", "survival_swap_used", client);
        return Plugin_Handled;
    }
    ArrayList ar = new ArrayList();
    for(int i = 1; i <= MaxClients; i++)
    {
        if(i != client)
        {
            int team = SurvivorArena_GetTeam(i);
            if(team != 0 && team != self_team && IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && get_idled_of_bot(i) == 0 && IsPlayerAlive(i))
            {
                ar.Push(i);
            }
        }
    }
    if(ar.Length == 0)
    {
        ReplyToCommand(client, "%T", "survival_swap_lack", client);
    }
    else
    {
        Swapped[client] = true;
        int target = ar.Get(GetRandomInt(0, ar.Length -1));
        ChangeClientTeam(client, 0);
        L4D_SetHumanSpec(target, client);
        L4D_TakeOverBot(client);
        self_team = SurvivorArena_GetTeam(client);
        if(self_team == 1)
        {
            ReplyToCommand(client, "%T", "survival_swap_to_green", client);
            for(int i = 1; i <= MaxClients; i++)
            {
                if(i != client && IsClientInGame(i) && !IsFakeClient(i))
                {
                    PrintToChat(i, "%T", "survival_swap_to_green_public", i, client);
                }
            }
        }
        else if(self_team == 2)
        {
            ReplyToCommand(client, "%T", "survival_swap_to_yellow", client);
            for(int i = 1; i <= MaxClients; i++)
            {
                if(i != client && IsClientInGame(i) && !IsFakeClient(i))
                {
                    PrintToChat(i, "%T", "survival_swap_to_yellow_public", i, client);
                }
            }
        }
    }
    delete ar;
    return Plugin_Handled;
}

void get_all_cvars()
{
    O_defend_by_attack_tank_threshold = C_defend_by_attack_tank_threshold.IntValue;
    O_defend_by_attack_tank_value = C_defend_by_attack_tank_value.FloatValue;
    O_defend_by_attack_tank_duration = C_defend_by_attack_tank_duration.FloatValue;

    O_defend_by_attack_tank_value_round_to_floor = RoundToFloor(O_defend_by_attack_tank_value * 100);
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_defend_by_attack_tank_threshold)
    {
        O_defend_by_attack_tank_threshold = C_defend_by_attack_tank_threshold.IntValue;
    }
    else if(convar == C_defend_by_attack_tank_value)
    {
        O_defend_by_attack_tank_value = C_defend_by_attack_tank_value.FloatValue;
        O_defend_by_attack_tank_value_round_to_floor = RoundToFloor(O_defend_by_attack_tank_value * 100);
    }
    else if(convar == C_defend_by_attack_tank_duration)
    {
        O_defend_by_attack_tank_duration = C_defend_by_attack_tank_duration.FloatValue;
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

any native_Survival_HasSwapTeam(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return Swapped[client];
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    Late_load = late;
    Forward_OnWin = new GlobalForward("Survival_OnWin", ET_Ignore, Param_Cell);
    CreateNative("Survival_HasSwapTeam", native_Survival_HasSwapTeam);
    RegPluginLibrary(PLUGIN_PREFIX);
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations(PLUGIN_PREFIX ... ".phrases");

    HookEvent("player_hurt", event_player_hurt);
    HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
    HookEvent("player_death", event_player_death);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);
    HookEvent("survival_round_start", event_survival_round_start);
    HookEvent("round_start", event_round_start);
    HookEvent("round_end", event_round_end);
	HookEvent("mission_lost", event_mission_lost);
    HookEvent("player_death", event_player_death);
	HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("player_ledge_grab", event_player_ledge_grab);

    C_defend_by_attack_tank_threshold = CreateConVar(PLUGIN_PREFIX ... "_defend_by_attack_tank_threshold", "1500", "keep hurt tank damage reaches this value, will get defend buff for a period of time. 0 or lower = disable");
    C_defend_by_attack_tank_threshold.AddChangeHook(convar_changed);
    C_defend_by_attack_tank_value = CreateConVar(PLUGIN_PREFIX ... "_defend_by_attack_tank_value", "0.4", "take damage reduce to this value in defend buff", _, true, 0.001);
    C_defend_by_attack_tank_value.AddChangeHook(convar_changed);
    C_defend_by_attack_tank_duration = CreateConVar(PLUGIN_PREFIX ... "_defend_by_attack_tank_duration", "15.0", "defend buff duration", _, true, 0.1);
    C_defend_by_attack_tank_duration.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, PLUGIN_PREFIX);
    get_all_cvars();

    RegConsoleCmd("sm_arenateam", cmd_arenateam);

    if(Late_load)
    {
        for(int client = 1; client <= MaxClients; client++)
        {
            if(IsClientInGame(client))
            {
                OnClientPutInServer(client);
            }
        }
    }
}