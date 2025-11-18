#define PLUGIN_VERSION  "1.16"
#define PLUGIN_NAME     "4v4 Arena"
#define PLUGIN_PREFIX	"4v4_arena"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <actions>

#define QueuedPummel_Victim		0
#define QueuedPummel_Attacker	8

#define REPRINT_TIME    0.5
#define REBUTTON_TIME_NORMAL   0.3
#define REBUTTON_TIME_PILLS    1.0

#define ARENA_TEAM_GREEN      1
#define ARENA_TEAM_YELLOW     2

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=346623"
};

static const char Holdable_weapos[][64] = 
{
    "weapon_propanetank",
    "weapon_fireworkcrate",
    "weapon_gascan",
    "weapon_oxygentank",
    "weapon_cola_bottles",
    "weapon_gnome",
};

GlobalForward Forward_OnTakePillsBack;

int Team[MAXPLAYERS+1];
float Next_print_time[MAXPLAYERS+1] = {-1.0, ...};
float Block_button_time_normal[MAXPLAYERS+1] = {-1.0, ...};
float Block_button_time_pills[MAXPLAYERS+1] = {-1.0, ...};
int Last_active_weapon[MAXPLAYERS+1] = {-1, ...};
ArrayList Witch_targets[MAXPLAYERS+1];

ConVar C_print_interval;
float O_print_interval;

Handle H_timer_print;

bool Late_load;

int Offset_QueuedPummelVictim;

public void OnEntityDestroyed(int entity)
{
    if(entity < 0)
    {
        return;
    }
    reset_witch_target(EntIndexToEntRef(entity));
}

bool is_survivor_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

void set_glow(int entity, int type = 0, const int color[3] = {0, 0, 0}, int range = 0, int range_min = 0, bool flash = false)
{
    SetEntProp(entity, Prop_Send, "m_iGlowType", type);
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", color[0] + color[1] * 256 + color[2] * 65536);
    SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", range_min);
    SetEntProp(entity, Prop_Send, "m_bFlashing", flash ? 1 : 0);
}

void get_team_by_model(int client)
{
    char model[PLATFORM_MAX_PATH];
    GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
    int team = 0;
    if(strcmp(model, "models/survivors/survivor_gambler.mdl") == 0)
    {
        team = ARENA_TEAM_YELLOW;
    }
    else if(strcmp(model, "models/survivors/survivor_producer.mdl") == 0)
    {
        team = ARENA_TEAM_YELLOW;
    }
    else if(strcmp(model, "models/survivors/survivor_coach.mdl") == 0)
    {
        team = ARENA_TEAM_YELLOW;
    }
    else if(strcmp(model, "models/survivors/survivor_mechanic.mdl") == 0)
    {
        team = ARENA_TEAM_YELLOW;
    }
    else if(strcmp(model, "models/survivors/survivor_namvet.mdl") == 0)
    {
        team = ARENA_TEAM_GREEN;
    }
    else if(strcmp(model, "models/survivors/survivor_teenangst.mdl") == 0)
    {
        team = ARENA_TEAM_GREEN;
    }
    else if(strcmp(model, "models/survivors/survivor_biker.mdl") == 0)
    {
        team = ARENA_TEAM_GREEN;
    }
    else if(strcmp(model, "models/survivors/survivor_manager.mdl") == 0)
    {
        team = ARENA_TEAM_GREEN;
    }
    Team[client] = team;
}

void check_player(int client)
{
    if(IsClientInGame(client) && GetClientTeam(client) == 2)
    {
        get_team_by_model(client);
        bool check = false;
        if(Team[client] == ARENA_TEAM_YELLOW)
        {
            if(IsPlayerAlive(client))
            {
                set_glow(client, 3, {255, 255, 0});
                check = true;
            }
            if(!IsFakeClient(client))
            {
                PrintHintText(client, "%T", "action_team_joined_yellow", client);
            }
        }
        else if(Team[client] == ARENA_TEAM_GREEN)
        {
            if(IsPlayerAlive(client))
            {
                set_glow(client, 3, {0, 255, 0});
                check = true;
            }
            if(!IsFakeClient(client))
            {
                PrintHintText(client, "%T", "action_team_joined_green", client);
            }
        }
        if(check)
        {
            int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
            if(active != -1 && !is_holdable_weapon(active))
            {
                check_weapon(client, active);
            }
        }
    }
}

public void Attachments_OnModelChanged(int client)
{
    RequestFrame(frame_model, GetClientUserId(client));
}

bool is_holdable_weapon(int weapon)
{
    char class_name[64];
    GetEntityClassname(weapon, class_name, sizeof(class_name));
    for(int i = 0; i < sizeof(Holdable_weapos); i++)
    {
        if(strcmp(class_name, "Holdable_weapos[i]") == 0)
        {
            return true;
        }
    }
    return false;
}

void check_weapon(int client, int weapon)
{
    int ref = EntIndexToEntRef(weapon);
    if(ref != Last_active_weapon[client])
    {
        int last = EntRefToEntIndex(Last_active_weapon[client]);
        if(last != -1)
        {
            set_glow(last);
        }
        Last_active_weapon[client] = ref;
        if(Team[client] == ARENA_TEAM_YELLOW)
        {
            set_glow(weapon, 3, {255, 255, 0});
        }
        else if(Team[client] == ARENA_TEAM_GREEN)
        {
            set_glow(weapon, 3, {0, 255, 0});
        }
    }
}

void on_weapon_switch_post(int client, int weapon)
{
    if(weapon == -1 || GetClientTeam(client) != 2 || Team[client] == 0 || is_holdable_weapon(weapon))
    {
        return;
    }
    int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if(active != -1 && active == weapon)
    {
        check_weapon(client, weapon);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponSwitchPost, on_weapon_switch_post);
}

public void OnClientDisconnect_Post(int client)
{
    reset_player(client);
}

public void OnActionCreated(BehaviorAction action, int actor, const char[] name)
{
	if(strncmp(name, "Survivor", 8) == 0)
	{
		if(strcmp(name[8], "HealFriend") == 0)
        {
			action.OnStartPost = on_HealFriend;
        }
		else if(strcmp(name[8], "GivePillsToFriend") == 0)
        {
			action.OnStartPost = on_GivePillsToFriend;
        }
        else if(strcmp(name[8], "ReviveFriend") == 0)
        {
            action.OnStart = on_ReviveFriend;
        }
        else if(strcmp(name[8], "LiberateBesiegedFriend") == 0)
        {
            action.OnStart = on_LiberateBesiegedFriend;
        }
        else if(strcmp(name[8], "LegsRegroup") == 0)
        {
            action.OnStart = on_LegsRegroup;
        }
        else if(strcmp(name[8], "Attack") == 0)
        {
            action.SelectTargetPoint = on_Attack;
        }
	}
    else if(strcmp(name, "WitchAttack") == 0)
    {
        action.OnStartPost = on_WitchAttack_start_post;
        action.OnEndPost = on_WitchAttack_end_post;
    }
}

Action on_ReviveFriend(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
    int target = action.Get(0x34) & 0xFFF;
    if(target > 0 && target <= MaxClients && Team[actor] != Team[target])
    {
        result.type = DONE;
        return Plugin_Changed;
    }
	return Plugin_Continue;
}

Action on_HealFriend(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
    int target = action.Get(0x34) & 0xFFF;
    if(target > 0 && target <= MaxClients && Team[actor] != Team[target])
    {
        result.type = DONE;
        return Plugin_Changed;
    }
	return Plugin_Continue;
}

Action on_GivePillsToFriend(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
    int target = action.Get(0x34) & 0xFFF;
    if(target > 0 && target <= MaxClients && Team[actor] != Team[target])
    {
        result.type = DONE;
        return Plugin_Changed;
    }
	return Plugin_Continue;
}

Action on_LiberateBesiegedFriend(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
    int target = action.Get(0x34) & 0xFFF;
    if(target > 0 && target <= MaxClients && Team[actor] != Team[target])
    {
        result.type = DONE;
        return Plugin_Changed;
    }
	return Plugin_Continue;
}

Action on_LegsRegroup(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
    int target = action.Get(0x34) & 0xFFF;
    if(target > 0 && target <= MaxClients && Team[actor] != Team[target] && (!is_survivor_alright(target) || get_si_attacker(target) != -1))
    {
        result.type = DONE;
        return Plugin_Changed;
    }
	return Plugin_Continue;
}

Action on_Attack(BehaviorAction action, Address nextbot, int entity, float vec[3])
{
    if(should_block_attack(get_entity_from_address(view_as<Address>(entity)), action.Actor))
    {
        return Plugin_Handled;
    }
	return Plugin_Continue;
}

Action on_WitchAttack_start_post(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
    int ref = EntIndexToEntRef(actor);
    reset_witch_target(ref);
    int target = action.Get(0x34) & 0xFFF;
    if(target > 0 && target <= MaxClients && Witch_targets[target].FindValue(ref) == -1)
    {
        Witch_targets[target].Push(ref);
    }
	return Plugin_Continue;
}

Action on_WitchAttack_end_post(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
    reset_witch_target(EntIndexToEntRef(actor));
	return Plugin_Continue;
}

int get_entity_from_address(Address addr)
{
    int entity = -1;
    while((entity = FindEntityByClassname(entity, "*")) != -1)
    {
        if(entity >= 0 && GetEntityAddress(entity) == addr)
        {
            return entity;
        }
    }
    return -1;
}

bool should_block_attack(int target, int actor)
{
    if(target > 0)
    {
        if(target <= MaxClients)
        {
            if(IsClientInGame(target) && IsPlayerAlive(target))
            {
                int team = GetClientTeam(target);
                if(team == 2)
                {
                    if(Team[target] != Team[actor])
                    {
                        return true;
                    }
                }
                else if(team == 3)
                {
                    int victim = get_si_victim(target);
                    if(victim != -1 && Team[victim] != Team[actor] && IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
                    {
                        return true;
                    }
                }
            }
        }
        else
        {
            char class_name[64];
            GetEntityClassname(target, class_name, sizeof(class_name));
            if(strcmp(class_name, "infected") == 0)
            {
                int player = GetEntPropEnt(target, Prop_Send, "m_clientLookatTarget");
                if(player > 0 && player <= MaxClients && Team[player] != Team[actor] && IsClientInGame(player) && GetClientTeam(player) == 2 && IsPlayerAlive(player))
                {
                    return true;
                }
            }
            else if(strcmp(class_name, "witch") == 0)
            {
                int ref = EntIndexToEntRef(target);
                for(int i = 1; i <= MaxClients; i++)
                {
                    if(Team[i] != Team[actor] && Witch_targets[i].FindValue(ref) != -1)
                    {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

int get_si_victim(int client)
{
	int victim = -1;
	victim = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
	if (victim > 0)
	{
		return victim;
	}
	victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
	if (victim > 0)
	{
		return victim;
	}
    victim = GetEntDataEnt2(client, Offset_QueuedPummelVictim + QueuedPummel_Victim);
    if(victim > 0)
    {
        return victim;
    }
	victim = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
	if (victim > 0)
	{
		return victim;
	}
	victim = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
	if (victim > 0)
	{
		return victim;
	}
	victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
	if (victim > 0)
	{
		return victim;
	}
	return -1;
}

int get_si_attacker(int client)
{
    int attacker = -1;
	attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
    attacker = GetEntDataEnt2(client, Offset_QueuedPummelVictim + QueuedPummel_Attacker);
    if(attacker > 0)
    {
        return attacker;
    }
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	return -1;
}

void check_all()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        check_player(client);
    }
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
    reset_all(false);
    check_all();
    delete H_timer_print;
    if(O_print_interval >= 0.1)
    {
        H_timer_print = CreateTimer(O_print_interval, timer_printer, _, TIMER_REPEAT);
    }
    CreateTimer(4.0, timer_model, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action timer_model(Handle timer)
{
    ServerCommand("sm_setleast");
    return Plugin_Stop;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        float time = GetGameTime();
        bool print = false;
        int revive_target = GetEntPropEnt(client, Prop_Send, "m_reviveTarget");
        if(revive_target > 0 && revive_target <= MaxClients && Team[client] != Team[revive_target])
        {
            L4D_StopReviveAction(client);
            L4D2Direct_DoAnimationEvent(client, PLAYERANIMEVENT_SPAWN);
            if(!IsFakeClient(client))
            {
                if(time >= Next_print_time[client])
                {
                    print = true;
                }
            }
        }
        if(GetEntProp(client, Prop_Send, "m_iCurrentUseAction") == 1)
        {
            int target = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");
            if(target > 0 && target <= MaxClients && Team[client] != Team[target])
            {
                L4D_StopReviveAction(client);
                L4D2Direct_DoAnimationEvent(client, PLAYERANIMEVENT_SPAWN);
                if(!IsFakeClient(client))
                {
                    if(time >= Next_print_time[client])
                    {
                        print = true;
                    }
                }
            }
        }
        if(print)
        {
            Next_print_time[client] = time + REPRINT_TIME;
            Block_button_time_normal[client] = time + REBUTTON_TIME_NORMAL;
            PrintCenterText(client, "%T", "action_through_team_cant", client);
        }
        else
        {
            Next_print_time[client] = -1.0;
        }
    }
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    bool changed = false;
    float time = GetGameTime();
    if(Block_button_time_normal[client] >= 0.0 && time < Block_button_time_normal[client])
    {
        changed = true;
        buttons &= ~(IN_ATTACK | IN_ATTACK2 | IN_USE);
    }
    if(Block_button_time_pills[client] >= 0.0 && time < Block_button_time_pills[client])
    {
        changed = true;
        buttons &= ~IN_ATTACK2;
    }
    return changed ? Plugin_Changed : Plugin_Continue;
}

void reset_witch_target(int ref)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        int index = Witch_targets[i].FindValue(ref);
        if(index != -1)
        {
            Witch_targets[i].Erase(index);
        }
    }
}

void reset_player(int client, bool extra = true)
{
    Team[client] = 0;
    if(extra)
    {
        Next_print_time[client] = -1.0;
        Block_button_time_normal[client] = -1.0;
        Block_button_time_pills[client] = -1.0;
        Last_active_weapon[client] = -1;
        Witch_targets[client].Clear();
    }
}

void reset_all(bool extra = true)
{
    for(int client = 1; client <= MaxClients; client++)
    {
        reset_player(client, extra);
    }
}

void next_frame()
{
    check_all();
}

Action on_um_PZDmgMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if(playersNum > 1)
    {
        return Plugin_Continue;
    }
    int section = BfReadByte(msg);
    int giver = GetClientOfUserId(BfReadShort(msg));
    int receiver = GetClientOfUserId(BfReadShort(msg));
    BfReadShort(msg);
    BfReadShort(msg);
    if((section == 16 || section == 17) && giver > 0 && giver <= MaxClients && receiver > 0 && receiver <= MaxClients && Team[giver] != Team[receiver])
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

void event_weapon_drop(Event event, const char[] name, bool dontBroadcast)
{
    int weapon = event.GetInt("propid");
    if(weapon > 0 && IsValidEntity(weapon) && GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity") == -1 && !is_holdable_weapon(weapon))
    {
        int ref = EntIndexToEntRef(weapon);
        for(int i = 1; i <= MaxClients; i++)
        {
            if(Last_active_weapon[i] == ref)
            {
                Last_active_weapon[i] = -1;
                set_glow(weapon);
                break;
            }
        }
    }
}

void event_weapon_given(Event event, const char[] name, bool dontBroadcast)
{
    int weapon = event.GetInt("weapon");
    if(weapon != 15 && weapon != 23)
    {
        return;
    }
    int client = GetClientOfUserId(event.GetInt("giver"));
    if(client != 0 && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        int target = GetClientOfUserId(event.GetInt("userid"));
        {
            if(target != 0 && Team[client] != Team[target] && GetClientTeam(target) == 2 && IsPlayerAlive(target))
            {
                int entity = event.GetInt("weaponentid");
                if(entity > 0 && IsValidEntity(entity))
                {
                    RemovePlayerItem(target, entity);
                    EquipPlayerWeapon(client, entity);
                    Call_StartForward(Forward_OnTakePillsBack);
                    Call_PushCell(client);
                    Call_PushCell(target);
                    Call_PushCell(entity);
                    Call_Finish();
                    PrintCenterText(client, "%T", "action_through_team_cant", client);
                    Block_button_time_pills[client] = GetGameTime() + REBUTTON_TIME_PILLS;
                }
            }
        }
    }
}

void event_defibrillator_begin(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client != 0)
    {
        int subject = GetClientOfUserId(event.GetInt("subject"));
        if(subject != 0)
        {
            if(Team[client] != Team[subject] && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_iCurrentUseAction") == 4)
            {
                int target = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");
                if(target != -1)
                {
                    char class_name[64];
                    GetEntityClassname(target, class_name, sizeof(class_name));
                    if(strcmp(class_name, "survivor_death_model") == 0)
                    {
                        RemoveEdict(target);
                        int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
                        if(active != -1)
                        {
                            GetEntityClassname(active, class_name, sizeof(class_name));
                            if(strcmp(class_name, "weapon_defibrillator") == 0)
                            {
                                RemovePlayerItem(client, active);
                                RemoveEdict(active);
                            }
                        }
                        if(!IsFakeClient(client))
                        {
                            PrintCenterText(client, "%T", "action_through_team_cant", client);
                        }
                    }
                }
            }
        }
    }
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	reset_all();
    RequestFrame(next_frame);
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
	{
        if(IsClientInGame(client) && GetClientTeam(client) == 2 && !IsPlayerAlive(client))
        {
            set_glow(client);
        }
        Next_print_time[client] = -1.0;
        Block_button_time_normal[client] = -1.0;
        Witch_targets[client].Clear();
	}
}

void event_witch_killed(Event event, const char[] name, bool dontBroadcast)
{
    int witch = event.GetInt("witchid");
    if(witch > 0 && IsValidEntity(witch))
    {
        reset_witch_target(EntIndexToEntRef(witch));
    }
}

void frame_model(int userid)
{
    int client = GetClientOfUserId(userid);
    if(client != 0)
    {
        check_player(client);
    }
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(client != 0)
	{
        if(IsClientInGame(client))
        {
            set_glow(client);
        }
		reset_player(client);
        RequestFrame(frame_model, userid);
	}
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
	{
        if(IsClientInGame(client))
        {
            set_glow(client);
        }
		if(IsFakeClient(client) && event.GetInt("team") == 1 && event.GetInt("oldteam") == 2)
		{
			return;
		}
		reset_player(client);
	}
}

void data_trans(int client, int prev)
{
    Team[client] = Team[prev];
    Last_active_weapon[client] = Last_active_weapon[prev];
    Witch_targets[client].Clear();
    for(int i = 0; i < Witch_targets[prev].Length; i++)
    {
        Witch_targets[client].Push(Witch_targets[prev].Get(i));
    }
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

Action timer_printer(Handle timer)
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
        {
            if(Team[client] == ARENA_TEAM_YELLOW)
            {
                PrintHintText(client, "%T", "action_team_joined_yellow", client);
            }
            else if(Team[client] == ARENA_TEAM_GREEN)
            {
                PrintHintText(client, "%T", "action_team_joined_green", client);
            }
        }
    }
    return Plugin_Continue;
}

void get_all_cvars()
{
    O_print_interval = C_print_interval.FloatValue;
    if(O_print_interval >= 0.1)
    {
        H_timer_print = CreateTimer(O_print_interval, timer_printer, _, TIMER_REPEAT);
    }
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_print_interval)
    {
        O_print_interval = C_print_interval.FloatValue;
        delete H_timer_print;
        if(O_print_interval >= 0.1)
        {
            H_timer_print = CreateTimer(O_print_interval, timer_printer, _, TIMER_REPEAT);
        }
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

any native_SurvivorArena_GetTeam(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return Team[client];
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    Late_load = late;
    Forward_OnTakePillsBack = new GlobalForward("SurvivorArena_OnTakePillsBack", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    CreateNative("SurvivorArena_GetTeam", native_SurvivorArena_GetTeam);
    RegPluginLibrary(PLUGIN_PREFIX);
    return APLRes_Success;
}

public void OnPluginStart()
{
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        Witch_targets[i] = new ArrayList();
    }
    Offset_QueuedPummelVictim = FindSendPropInfo("CTerrorPlayer", "m_pummelAttacker") + 4;

    LoadTranslations(PLUGIN_PREFIX ... ".phrases");

    HookEvent("weapon_drop", event_weapon_drop);
    HookEvent("weapon_given", event_weapon_given);
    HookEvent("defibrillator_begin", event_defibrillator_begin);
	HookEvent("round_start", event_round_start);
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
    HookEvent("player_death", event_player_death);
    HookEvent("witch_killed", event_witch_killed);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

    C_print_interval = CreateConVar(PLUGIN_PREFIX ... "_print_interval", "10.0", "interval to print team info. lower than 0.1 = disable");
    C_print_interval.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, PLUGIN_PREFIX);
    get_all_cvars();

    HookUserMessage(GetUserMessageId("PZDmgMsg"), on_um_PZDmgMsg, true);

    if(Late_load)
    {
        for(int client = 1; client <= MaxClients; client++)
        {
            check_player(client);
            if(IsClientInGame(client))
            {
                OnClientPutInServer(client);
            }
        }
    }
}

public void OnPluginEnd()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && Team[client] != 0)
        {
            set_glow(client);
        }
    }
}