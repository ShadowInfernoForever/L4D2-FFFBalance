#define PLUGIN_VERSION	"1.0 Simplified"
#define PLUGIN_NAME		"Automatic Healing"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define MEDICINE_PILLS		(1 << 0)
#define MEDICINE_ADRENALINE	(1 << 1)
#define MEDICINE_MEDKIT		(1 << 2)

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=336073"
};

enum Sub_Medicine_Type
{
	Sub_Medicine_Type_Pills = 0,
	Sub_Medicine_Type_Adrenaline
}

ConVar C_buffer_decay_rate;
ConVar C_pain_pills_health_value;
ConVar C_adrenaline_health_buffer;
ConVar C_interrupt_on_hurt;
ConVar C_wait_time;
ConVar C_health;
ConVar C_max;
ConVar C_repeat_interval;
ConVar C_survivor_max_health;
ConVar C_medicine;

float O_buffer_decay_rate;
float O_pain_pills_health_value;
float O_adrenaline_health_buffer;
bool O_interrupt_on_hurt;
float O_wait_time;
float O_health;
float O_max;
float O_repeat_interval;
float O_survivor_max_health;
int O_medicine;

float O_max_round_to_floor;

float Wait_start_time[MAXPLAYERS+1];
float Wait_left_time[MAXPLAYERS+1];
bool First[MAXPLAYERS+1];
Handle H_waiting_start[MAXPLAYERS+1];
Handle H_waiting_repeat[MAXPLAYERS+1];

bool is_survivor_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

int get_max_health(int client)
{
	return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

float get_temp_health(int client)
{
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * O_buffer_decay_rate;
	return buffer < 0.0 ? 0.0 : buffer;
}

void set_temp_health(int client, float buffer)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", buffer);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

bool continue_healing_process(int client)
{
	float health = float(GetClientHealth(client));
	float buffer = get_temp_health(client);
	float all = health + buffer;
	if(all < O_max_round_to_floor)
	{
		if(all + O_health < O_max_round_to_floor)
		{
			set_temp_health(client, buffer + O_health);
			return true;
		}
		else
		{
			set_temp_health(client, O_max - health);
			return false;
		}
	}
	else
	{
		if(all < O_max)
		{
			set_temp_health(client, O_max - health);
		}
		return false;
	}	
}

bool is_invalid_client_in_timer(int client)
{
	return !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !is_survivor_alright(client);
}

Action timer_heal_wait_start(Handle timer, any client)
{
	if(is_invalid_client_in_timer(client))
	{
		H_waiting_start[client] = null;
		return Plugin_Stop;
	}
	if(continue_healing_process(client))
	{
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_repeat_interval;
		H_waiting_repeat[client] = CreateTimer(O_repeat_interval, timer_heal_wait_repeat, client, TIMER_REPEAT);
	}
	H_waiting_start[client] = null;
	return Plugin_Stop;
}
			
Action timer_heal_wait_repeat(Handle timer, any client)
{
	if(is_invalid_client_in_timer(client))
	{
		H_waiting_repeat[client] = null;
		return Plugin_Stop;
	}
	if(continue_healing_process(client))
	{
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_repeat_interval;
		return Plugin_Continue;
	}
	else
	{
		H_waiting_repeat[client] = null;
		return Plugin_Stop;
	}
}

void end_heal(int client)
{
	delete H_waiting_start[client];
	delete H_waiting_repeat[client];
}

void end_heal_with_first(int client, bool first)
{
	end_heal(client);
	First[client] = first;
}

float get_halfway_time(int client)
{
	float halfway_time = Wait_left_time[client] - (GetGameTime() - Wait_start_time[client]);
	return halfway_time < 0.1 ? 0.1 : halfway_time;
}

bool lower_than_heal_max(int client)
{
	return float(GetClientHealth(client)) + get_temp_health(client) < O_max_round_to_floor;
}

void wait_to_heal(int client, bool is_halfway = false, float halfway_time = 0.0)
{
	end_heal(client);
	float time = is_halfway ? halfway_time : O_wait_time;
	Wait_start_time[client] = GetGameTime();
	Wait_left_time[client] = time;
	H_waiting_start[client] = CreateTimer(time, timer_heal_wait_start, client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if(GetClientTeam(client) == 2)
	{
		if(IsPlayerAlive(client) && is_survivor_alright(client))
		{
			if(First[client])
			{
				end_heal(client);
				float health = float(GetClientHealth(client));
				if(health + get_temp_health(client) < O_max)
				{
					set_temp_health(client, O_max - health);
				}
				First[client] = false;
			}
			else
			{
				float health = float(GetClientHealth(client));
				float all = health + get_temp_health(client);
				if(all < O_max_round_to_floor)
				{
					if((!H_waiting_start[client] && !H_waiting_repeat[client]))
					{
						wait_to_heal(client);
					}
				}
				else
				{
					end_heal(client);
					if(all < O_max)
					{
						set_temp_health(client, O_max - health);
					}
				}
			}
		}
		else
		{
			end_heal_with_first(client, false);
		}
	}
	else
	{
		end_heal_with_first(client, true);
	}
}

public void OnClientDisconnect_Post(int client)
{
	end_heal_with_first(client, true);
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		end_heal_with_first(client, true);
	}
}

void event_player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!O_interrupt_on_hurt)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client) && lower_than_heal_max(client) && event.GetInt("dmg_health") > 0)
	{
		wait_to_heal(client);
	}
}

void sub_medicine_instantly_heal(int client, Sub_Medicine_Type type)
{
	float extra = 0.0;
	switch(type)
	{
		case Sub_Medicine_Type_Pills:
			extra = O_pain_pills_health_value;
		case Sub_Medicine_Type_Adrenaline:
			extra = O_adrenaline_health_buffer;
	}
	float expected = O_max + extra;
	float real_max_health = float(get_max_health(client));
	if(real_max_health < O_survivor_max_health)
	{
		real_max_health = O_survivor_max_health;
	}
	if(expected > real_max_health)
	{
		expected = real_max_health;
	}
	float health = float(GetClientHealth(client));
	if(health + get_temp_health(client) < expected)
	{
		set_temp_health(client, expected - health);
	}	
}

void event_pills_used(Event event, const char[] name, bool dontBroadcast)
{
	if(!(O_medicine & MEDICINE_PILLS))
	{
		return;
	}
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client != 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
    {
		sub_medicine_instantly_heal(client, Sub_Medicine_Type_Pills);
    }
}

void event_adrenaline_used(Event event, const char[] name, bool dontBroadcast)
{
	if(!(O_medicine & MEDICINE_ADRENALINE))
	{
		return;
	}
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client != 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
    {
		sub_medicine_instantly_heal(client, Sub_Medicine_Type_Adrenaline);
    }
}

void event_heal_success(Event event, const char[] name, bool dontBroadcast)
{
	if(!(O_medicine & MEDICINE_MEDKIT))
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("subject"));
    if(client != 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
    {
		float health = float(GetClientHealth(client));
		if(health + get_temp_health(client) < O_max)
		{
			set_temp_health(client, O_max - health);
		}
    }
}

void event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("bot"));
	int prev = GetClientOfUserId(event.GetInt("player"));
	if(client != 0 && GetClientTeam(client) == 2 && prev != 0)
	{
		First[client] = First[prev];
		if(IsPlayerAlive(client) && is_survivor_alright(client) && lower_than_heal_max(client) && (H_waiting_start[prev] || H_waiting_repeat[prev]))
		{
			wait_to_heal(client, true, get_halfway_time(prev));
		}
	}
}

void event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int prev = GetClientOfUserId(event.GetInt("bot"));
	if(client != 0 && GetClientTeam(client) == 2 && prev != 0)
	{
		First[client] = First[prev];
		if(IsPlayerAlive(client) && is_survivor_alright(client) && lower_than_heal_max(client) && (H_waiting_start[prev] || H_waiting_repeat[prev]))
		{
			wait_to_heal(client, true, get_halfway_time(prev));
		}
	}
}

void get_cvars()
{
	O_buffer_decay_rate = C_buffer_decay_rate.FloatValue;
	O_pain_pills_health_value = C_pain_pills_health_value.FloatValue;
	O_adrenaline_health_buffer = C_adrenaline_health_buffer.FloatValue;
	O_interrupt_on_hurt = C_interrupt_on_hurt.BoolValue;
	O_wait_time = C_wait_time.FloatValue;
	O_health = C_health.FloatValue;
	O_max = C_max.FloatValue;
	O_repeat_interval = C_repeat_interval.FloatValue;
	O_survivor_max_health = C_survivor_max_health.FloatValue;
	O_medicine = C_medicine.IntValue;

	O_max_round_to_floor = float(RoundToFloor(O_max));
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
}

public void OnPluginStart()
{
	HookEvent("round_start", event_round_start);
	HookEvent("player_hurt", event_player_hurt);
    HookEvent("pills_used", event_pills_used);
    HookEvent("adrenaline_used", event_adrenaline_used);
	HookEvent("heal_success", event_heal_success);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

	C_buffer_decay_rate = FindConVar("pain_pills_decay_rate");
	C_pain_pills_health_value = FindConVar("pain_pills_health_value");
	C_adrenaline_health_buffer = FindConVar("adrenaline_health_buffer");
	C_interrupt_on_hurt = CreateConVar("automatic_healing_interrupt_on_hurt", "1", "1 = enable, 0 = disable. interrupt healing on hurt?");
	C_wait_time = CreateConVar("automatic_healing_wait_time", "5.0", "how long time need to wait after the interruption to start healing", _, true, 0.1);
	C_health = CreateConVar("automatic_healing_health", "2.0", "how many health buffer heal once", _, true, 0.1);
	C_repeat_interval = CreateConVar("automatic_healing_repeat_interval", "1.0", "repeat interval after healing start", _, true, 0.1);
	C_max = CreateConVar("automatic_healing_max", "30.2", "max health of healing", _, true, 1.1);
	C_survivor_max_health = CreateConVar("automatic_healing_survivor_max_health", "100.0", "when \"automatic_healing_medicine\" works, health buffer more than this value will be removed. real max health can be higher than the value", _, true, 1.0);
	C_medicine = CreateConVar("automatic_healing_medicine", "7", "0 = disable, 1 = pain pills will start healing from \"automatic_healing_max\", 2 = adrenaline will start healing from \"automatic_healing_max\", 4 = after using first aid kit, instantly heal to \"automatic_healing_max\". add numbers together", _, true, 0.0, true, 7.0);

	CreateConVar("automatic_healing_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);

	C_buffer_decay_rate.AddChangeHook(convar_changed);
	C_pain_pills_health_value.AddChangeHook(convar_changed);
	C_adrenaline_health_buffer.AddChangeHook(convar_changed);
	C_interrupt_on_hurt.AddChangeHook(convar_changed);
	C_wait_time.AddChangeHook(convar_changed);
	C_health.AddChangeHook(convar_changed);
	C_repeat_interval.AddChangeHook(convar_changed);
	C_max.AddChangeHook(convar_changed);
	C_survivor_max_health.AddChangeHook(convar_changed);
	C_medicine.AddChangeHook(convar_changed);

	AutoExecConfig(true, "automatic_healing");
}