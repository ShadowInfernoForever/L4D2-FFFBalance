#define PLUGIN_VERSION  "1.6"
#define PLUGIN_NAME     "[HoE] ZS Survivor Sprite"
#define PLUGIN_PREFIX	"survivor_sprite"

#pragma tabsize 0
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define ENABLE_NORMAL       (1 << 0)
#define ENABLE_THIRDSTRIKE  (1 << 1)

#define FLAG_PULSE_INCAPACITATED      1
#define FLAG_PULSE_LOW_HEALTH         4

static ConVar g_hCvar_survivor_limp_health;
static ConVar g_hCvar_pain_pills_decay_rate;
static int    g_iCvar_survivor_limp_health;
static float  g_iCvar_pain_pills_decay_rate;

int    g_iCvar_FadeDistance;

ConVar TIME;
Handle TIMER = INVALID_HANDLE;
Handle pulseTimer[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2810333"
};

ConVar C_enable;
int O_enable;

ConVar g_hCvar_FadeDistance;
static char   g_sCvar_FadeDistance[5];

ConVar C_normal_model;
char O_normal_model[PLATFORM_MAX_PATH];
ConVar C_normal_pos;
float O_normal_pos[3];
ConVar C_normal_scale;
char O_normal_scale[PLATFORM_MAX_PATH];
ConVar C_normal_bone;
char O_normal_bone[PLATFORM_MAX_PATH];
ConVar C_normal_through_things;
bool O_normal_through_things;
ConVar C_normal_pulse_duration;
float O_normal_pulse_duration;
ConVar C_normal_pulse_interval;
float O_normal_pulse_interval;
ConVar C_normal_color;
int O_normal_color[3];

ConVar C_thirdstrike_model;
char O_thirdstrike_model[PLATFORM_MAX_PATH];
ConVar C_thirdstrike_pos;
float O_thirdstrike_pos[3];
ConVar C_thirdstrike_scale;
char O_thirdstrike_scale[PLATFORM_MAX_PATH];
ConVar C_thirdstrike_bone;
char O_thirdstrike_bone[PLATFORM_MAX_PATH];
ConVar C_thirdstrike_through_things;
bool O_thirdstrike_through_things;
ConVar C_thirdstrike_pulse_duration;
float O_thirdstrike_pulse_duration;
ConVar C_thirdstrike_pulse_interval;
float O_thirdstrike_pulse_interval;
ConVar C_thirdstrike_color;
int O_thirdstrike_color[3];

float Next_change_time_normal = -1.0;
float Next_change_time_thirdstrike = -1.0;
bool Should_change_normal;
bool Should_change_thirdstrike;
bool Show_normal;
bool Show_thirdstrike;
bool Set_bone_normal;
bool Set_bone_thirdstrike;

bool Late_load;

ArrayList Filter_entities;

int Sprite_normal[MAXPLAYERS+1] = {-1, ...};
int Sprite_thirdstrike[MAXPLAYERS+1] = {-1, ...};

public void OnMapEnd()
{
    Filter_entities.Clear();

    KillTimer(TIMER);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(entity < 0)
    {
        return;
    }
    if(strcmp(classname, "infected") == 0 || strcmp(classname, "witch") == 0 || strcmp(classname, "tank_rock") == 0)
    {
        Filter_entities.Push(EntIndexToEntRef(entity));
    }
}

public void OnEntityDestroyed(int entity)
{
    if(entity < 0)
    {
        return;
    }
    int index = Filter_entities.FindValue(EntIndexToEntRef(entity));
    if(index != -1)
    {
        Filter_entities.Erase(index);
    }
}

bool is_survivor_on_thirdstrike(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");
}

bool is_visible_to(int client, int target)
{
	float self_pos[3];
    float target_pos[3];
    float look_at[3];
    float vec_angles[3];
	GetClientEyePosition(client, self_pos);
	GetClientEyePosition(target, target_pos);
	MakeVectorFromPoints(self_pos, target_pos, look_at);
	GetVectorAngles(look_at, vec_angles);
	Handle trace = TR_TraceRayFilterEx(self_pos, vec_angles, CONTENTS_SOLID, RayType_Infinite, trace_entity_filter, target);
    bool result = TR_DidHit(trace) && TR_GetEntityIndex(trace) == target;
	delete trace;
	return result;
}

bool trace_entity_filter(int entity, int contentsMask, any data)
{
    if(entity == data)
    {
        return true;
    }
    if(entity > 0 && entity <= MaxClients)
    {
        return false;
    }
    return Filter_entities.FindValue(EntIndexToEntRef(entity)) == -1;
}

Action set_transmit_normal(int entity, int client)
{
    if(!Show_normal)
    {
        return Plugin_Handled;
    }
    if(GameRules_GetProp("m_bInIntro"))
    {
        return Plugin_Handled;
    }
    int ref = EntIndexToEntRef(entity);
    int owner = -1;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(Sprite_normal[i] == ref)
        {
            owner = i;
            break;
        }
    }
    if(owner == -1)
    {
        return Plugin_Handled;
    }
    if(owner == client)
    {
        return Plugin_Handled;
    }
    if(!IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 && GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == owner)
    {
        return Plugin_Handled;
    }
    if(!O_normal_through_things && !is_visible_to(client, owner))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

Action set_transmit_thirdstrike(int entity, int client)
{
    if(!Show_thirdstrike)
    {
        return Plugin_Handled;
    }
    if(GameRules_GetProp("m_bInIntro"))
    {
        return Plugin_Handled;
    }
    int ref = EntIndexToEntRef(entity);
    int owner = -1;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(Sprite_thirdstrike[i] == ref)
        {
            owner = i;
            break;
        }
    }
    if(owner == -1)
    {
        return Plugin_Handled;
    }
    if(owner == client)
    {
        return Plugin_Handled;
    }
    if(!IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 && GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == owner)
    {
        return Plugin_Handled;
    }
    if(!O_thirdstrike_through_things && !is_visible_to(client, owner))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

void set_sprite_normal(int client)
{
    if(Sprite_normal[client] == -1)
    {
        int entity = CreateEntityByName("env_sprite");
        if(entity == -1)
        {
            return;
        }

        if(!IsModelPrecached(O_normal_model))
        {
            PrecacheModel(O_normal_model, true);
        }

        bool isIncapacitated = IsPlayerIncapacitated(client);
        int currentHealth = GetClientHealth(client);
        currentHealth += GetClientTempHealth(client);

        int color[3];
        if (isIncapacitated)
        {
            color[0] = 255;
            color[1] = 0;
            color[2] = 0;
            O_normal_model = "materials/sprites/light_glow02_add_noz.vmt";
            SetEntityRenderColor(entity, color[0], color[1], color[2], 100);
        }
        else if (currentHealth >= g_iCvar_survivor_limp_health) // Green
        {
            color[0] = 0;
            color[1] = 150;
            color[2] = 0;
        }
        else if (currentHealth >= 35) // Yellow
        {
            color[0] = 30;
            color[1] = 50;
            color[2] = 0;
        }
        else 
        {
            color[0] = 255;
            color[1] = 0;
            color[2] = 0;
        }

        DispatchKeyValue(entity, "model", O_normal_model);
        DispatchKeyValue(entity, "GlowProxySize", "0.0");
        DispatchKeyValue(entity, "scale", O_normal_scale);
        DispatchKeyValue(entity, "fademindist", g_sCvar_FadeDistance);
        DispatchSpawn(entity);
        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", client);

        if(Set_bone_normal)
        {
            SetVariantString(O_normal_bone);
            AcceptEntityInput(entity, "SetParentAttachment");
        }

        TeleportEntity(entity, O_normal_pos, view_as<float>({0.0, 0.0, 0.0}));
        SetEntProp(entity, Prop_Data, "m_iEFlags", 0);
        Sprite_normal[client] = EntIndexToEntRef(entity);
        SetEntityRenderColor(entity, color[0], color[1], color[2], 255);
        SDKHook(entity, SDKHook_SetTransmit, set_transmit_normal);

        // Start the pulsating scale effect
        pulseTimer[client] = CreateTimer(0.1, PulseSpriteScale, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action PulseSpriteScale(Handle timer, int client)
{
    static bool scaleUp[MAXPLAYERS+1];
    static float pulseScale[MAXPLAYERS+1] = {0.5};

    if (Sprite_normal[client] == -1)
    {
        return Plugin_Stop;
    }

    // Toggle scale direction
    if (pulseScale[client] >= 1.0)
    {
        scaleUp[client] = false;
    }
    else if (pulseScale[client] <= 0.5)
    {
        scaleUp[client] = true;
    }

    // Adjust scale value
    pulseScale[client] += (scaleUp[client] ? 0.05 : -0.05);

    int entity = EntRefToEntIndex(Sprite_normal[client]);

    // Apply new scale for pulsating effect
    char scaleString[8];
    Format(scaleString, sizeof(scaleString), "%f", pulseScale[client]);
    DispatchKeyValue(entity, "scale", scaleString);

    return Plugin_Continue;
}

void set_sprite_thirdstrike(int client)
{
    if(Sprite_thirdstrike[client] == -1)
    {
        int entity = CreateEntityByName("env_sprite");
        if(entity == -1)
        {
            return;
        }
        if(!IsModelPrecached(O_thirdstrike_model))
        {
            PrecacheModel(O_thirdstrike_model, true);
        }

        SetEntityRenderColor(entity, O_thirdstrike_color[0], O_thirdstrike_color[1], O_thirdstrike_color[2], 100);

        DispatchKeyValue(entity, "model", O_thirdstrike_model);
        DispatchKeyValue(entity, "GlowProxySize", "0.0");
        DispatchKeyValue(entity, "scale", O_thirdstrike_scale);
        DispatchKeyValue(entity, "fademindist", g_sCvar_FadeDistance);
        DispatchSpawn(entity);
        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", client);
        if(Set_bone_thirdstrike)
        {
            SetVariantString(O_thirdstrike_bone);
            AcceptEntityInput(entity, "SetParentAttachment");
        }
        TeleportEntity(entity, O_thirdstrike_pos, view_as<float>({0.0, 0.0, 0.0}));
        SetEntProp(entity, Prop_Data, "m_iEFlags", 0);
        Sprite_thirdstrike[client] = EntIndexToEntRef(entity);
        SDKHook(entity, SDKHook_SetTransmit, set_transmit_thirdstrike);
    }
}

void remove_ref(int& ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity != -1)
    {
        RemoveEntity(entity);
    }
    ref = -1;
}

void reset_sprite_normal(int client)
{
    if(Sprite_normal[client] != -1)
    {
        remove_ref(Sprite_normal[client]);
    }
}

void reset_sprite_thirdstrike(int client)
{
    if(Sprite_thirdstrike[client] != -1)
    {
        remove_ref(Sprite_thirdstrike[client]);
    }
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        if(is_survivor_on_thirdstrike(client))
        {
            if(O_enable & ENABLE_THIRDSTRIKE)
            {
                reset_sprite_normal(client);
                set_sprite_thirdstrike(client);
            }
            else
            {
                OnClientDisconnect_Post(client);
            }
        }
        else
        {
            if(O_enable & ENABLE_NORMAL)
            {
                reset_sprite_thirdstrike(client);
                set_sprite_normal(client);
            }
            else
            {
                OnClientDisconnect_Post(client);
            }
        }
    }
    else
    {
        OnClientDisconnect_Post(client);
    }
}

public void OnGameFrame()
{
    if(Should_change_normal && GetEngineTime() >= Next_change_time_normal)
    {
        if(Show_normal)
        {
            Show_normal = false;
            Next_change_time_normal = GetEngineTime() + O_normal_pulse_interval;
        }
        else
        {
            Show_normal = true;
            Next_change_time_normal = GetEngineTime() + O_normal_pulse_duration;
        }
    }
    if(Should_change_thirdstrike && GetEngineTime() >= Next_change_time_thirdstrike)
    {
        if(Show_thirdstrike)
        {
            Show_thirdstrike = false;
            Next_change_time_thirdstrike = GetEngineTime() + O_thirdstrike_pulse_interval;
        }
        else
        {
            Show_thirdstrike = true;
            Next_change_time_thirdstrike = GetEngineTime() + O_thirdstrike_pulse_duration;
        }
    }
}

public void OnClientDisconnect_Post(int client)
{
    reset_sprite_thirdstrike(client);
    reset_sprite_normal(client);
}

void reset_all()
{
    for(int client = 1; client <= MAXPLAYERS; client++)
    {
        OnClientDisconnect_Post(client);
    }
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    reset_all();
}

void get_cvars()
{
    O_enable = C_enable.IntValue;
    char cvar_pos[48];
    char get_pos[3][16];
    char cvar_colors[13];
    char colors_get[3][4];
    C_thirdstrike_model.GetString(O_thirdstrike_model, sizeof(O_thirdstrike_model));
    C_thirdstrike_pos.GetString(cvar_pos, sizeof(cvar_pos));
    ExplodeString(cvar_pos, " ", get_pos, 3, 16);
    for(int i = 0; i < 3; i++)
    {
        O_thirdstrike_pos[i] = StringToFloat(get_pos[i]);
    }
    C_thirdstrike_scale.GetString(O_thirdstrike_scale, sizeof(O_thirdstrike_scale));
    C_thirdstrike_bone.GetString(O_thirdstrike_bone, sizeof(O_thirdstrike_bone));
    O_thirdstrike_through_things = C_thirdstrike_through_things.BoolValue;
    O_thirdstrike_pulse_duration = C_thirdstrike_pulse_duration.FloatValue;
    O_thirdstrike_pulse_interval = C_thirdstrike_pulse_interval.FloatValue;
    C_thirdstrike_color.GetString(cvar_colors, sizeof(cvar_colors));
    ExplodeString(cvar_colors, " ", colors_get, 3, 4);
    for(int i = 0; i < 3; i++)
    {
        O_thirdstrike_color[i] = StringToInt(colors_get[i]);
        if(O_thirdstrike_color[i] > 255)
        {
            O_thirdstrike_color[i] = 255;
        }
        else if(O_thirdstrike_color[i] < 0)
        {
            O_thirdstrike_color[i] = 0;
        }
    }
    C_normal_model.GetString(O_normal_model, sizeof(O_normal_model));
    C_normal_pos.GetString(cvar_pos, sizeof(cvar_pos));
    ExplodeString(cvar_pos, " ", get_pos, 3, 16);
    for(int i = 0; i < 3; i++)
    {
        O_normal_pos[i] = StringToFloat(get_pos[i]);
    }
    C_normal_scale.GetString(O_normal_scale, sizeof(O_normal_scale));
    C_normal_bone.GetString(O_normal_bone, sizeof(O_normal_bone));
    O_normal_through_things = C_normal_through_things.BoolValue;
    O_normal_pulse_duration = C_normal_pulse_duration.FloatValue;
    O_normal_pulse_interval = C_normal_pulse_interval.FloatValue;
    C_normal_color.GetString(cvar_colors, sizeof(cvar_colors));
    ExplodeString(cvar_colors, " ", colors_get, 3, 4);
    for(int i = 0; i < 3; i++)
    {
        O_normal_color[i] = StringToInt(colors_get[i]);
        if(O_normal_color[i] > 255)
        {
            O_normal_color[i] = 255;
        }
        else if(O_normal_color[i] < 0)
        {
            O_normal_color[i] = 0;
        }
    }

    Should_change_normal = O_normal_pulse_duration > 0.0 && O_normal_pulse_interval > 0.0;
    Should_change_thirdstrike = O_thirdstrike_pulse_duration > 0.0 && O_thirdstrike_pulse_interval > 0.0;
    Set_bone_normal = strlen(O_normal_bone) > 0;
    Set_bone_thirdstrike = strlen(O_thirdstrike_bone) > 0;
    Show_normal = true;
    Show_thirdstrike = true;
    Next_change_time_normal = -1.0;
    Next_change_time_thirdstrike = -1.0;

    reset_all();
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
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
    Filter_entities = new ArrayList();

    HookEvent("round_start", event_round_start); 

    C_enable = CreateConVar(PLUGIN_PREFIX ... "_enable", "3", "1 = enable normal sprite, 2 = enable thirkdstrike sprite. add numbers together", _, true, 0.0, true, 3.0);
    C_enable.AddChangeHook(convar_changed);

    C_normal_model = CreateConVar(PLUGIN_PREFIX ... "_normal_model", "materials/vgui/icon_button_friends.vmt", "model of normal sprite");
    C_normal_model.AddChangeHook(convar_changed);

    //g_hCvar_FadeDistance      = CreateConVar(PLUGIN_PREFIX ... "_normal_fadedistance", "-1", "Minimum distance that a client must be from another client to see the sprite.\n-1 = Always visible.", true, -1.0, true, 9999.0);
    g_hCvar_FadeDistance.AddChangeHook(Event_ConVarChanged);

    C_normal_pos = CreateConVar(PLUGIN_PREFIX ... "_normal_pos", "0.0 0.0 0.0", "position of normal sprite, split up with space");
    C_normal_pos.AddChangeHook(convar_changed);
    C_normal_scale = CreateConVar(PLUGIN_PREFIX ... "_normal_scale", "0.4", "scale of normal sprite");
    C_normal_scale.AddChangeHook(convar_changed);
    C_normal_bone = CreateConVar(PLUGIN_PREFIX ... "_normal_bone", "spine", "bone of normal sprite. leave empty to disable");
    C_normal_bone.AddChangeHook(convar_changed);
    C_normal_through_things = CreateConVar(PLUGIN_PREFIX ... "_normal_through_things", "0", "1 = enable, 0 = disable. can normal sprite be seen through things solid?");
    C_normal_through_things.AddChangeHook(convar_changed);
    C_normal_pulse_duration = CreateConVar(PLUGIN_PREFIX ... "_normal_pulse_duration", "0.3", "duration of pulse to show normal sprite. 0.0 or lower = disable");
    C_normal_pulse_duration.AddChangeHook(convar_changed);
    C_normal_pulse_interval = CreateConVar(PLUGIN_PREFIX ... "_normal_pulse_interval", "0.3", "interval of pulse to show normal sprite. 0.0 or lower = disable");
    C_normal_pulse_interval.AddChangeHook(convar_changed);
    C_normal_color = CreateConVar(PLUGIN_PREFIX ... "_normal_color", "255 255 255", "render color of normal sprite, split up with space");
    C_normal_color.AddChangeHook(convar_changed);

    C_thirdstrike_model = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_model", "materials/vgui/hud/icon_medkit.vmt", "model of thirkdstrike sprite");
    C_thirdstrike_model.AddChangeHook(convar_changed);
    C_thirdstrike_pos = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_pos", "0.0 0.0 0.0", "position of thirkdstrike sprite, split up with space");
    C_thirdstrike_pos.AddChangeHook(convar_changed);
    C_thirdstrike_scale = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_scale", "0.1", "scale of thirkdstrike sprite");
    C_thirdstrike_scale.AddChangeHook(convar_changed);
    C_thirdstrike_bone = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_bone", "spine", "bone of thirkdstrike sprite. leave empty to disable");
    C_thirdstrike_bone.AddChangeHook(convar_changed);
    C_thirdstrike_through_things = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_through_things", "0", "1 = enable, 0 = disable. can thirkdstrike sprite be seen through things solid?");
    C_thirdstrike_through_things.AddChangeHook(convar_changed);
    C_thirdstrike_pulse_duration = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_pulse_duration", "0.3", "duration of pulse to show thirkdstrike sprite. 0.0 or lower = disable");
    C_thirdstrike_pulse_duration.AddChangeHook(convar_changed);
    C_thirdstrike_pulse_interval = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_pulse_interval", "0.3", "interval of pulse to show thirkdstrike sprite. 0.0 or lower = disable");
    C_thirdstrike_pulse_interval.AddChangeHook(convar_changed);
    C_thirdstrike_color = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_color", "255 255 255", "render color of thirkdstrike sprite, split up with space");
    C_thirdstrike_color.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, PLUGIN_PREFIX);

    TIME = CreateConVar("hoe_zssprite_reset_timer", "0.2", "How long to reset the sprites");
    TIME.AddChangeHook(OnCvarChange);

    g_hCvar_survivor_limp_health = FindConVar("survivor_limp_health");
    g_hCvar_survivor_limp_health.AddChangeHook(Event_ConVarChanged);

    g_hCvar_pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");
    g_hCvar_pain_pills_decay_rate.AddChangeHook(Event_ConVarChanged);

    if(Late_load)
    {
        int entity = -1;
        while((entity = FindEntityByClassname(entity, "infected")) != -1)
        {
            Filter_entities.Push(EntIndexToEntRef(entity));
        }
        while((entity = FindEntityByClassname(entity, "witch")) != -1)
        {
            Filter_entities.Push(EntIndexToEntRef(entity));
        }
        while((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
        {
            Filter_entities.Push(EntIndexToEntRef(entity));
        }
    }
}

public void OnCvarChange(ConVar convar, char[] oldValue, char[] newValue)
{
    if (convar == TIME)
    {
        KillTimer(TIMER);
        TIMER = CreateTimer(1.0 * GetConVarInt(TIME), zsresetsprites,_, TIMER_REPEAT);
    }
}

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

public void GetCvars()
{
    g_iCvar_survivor_limp_health = g_hCvar_survivor_limp_health.IntValue;
    g_iCvar_pain_pills_decay_rate = g_hCvar_pain_pills_decay_rate.FloatValue;
    g_iCvar_FadeDistance = g_hCvar_FadeDistance.IntValue;
    FormatEx(g_sCvar_FadeDistance, sizeof(g_sCvar_FadeDistance), "%i", g_iCvar_FadeDistance);
}

public void OnPluginEnd()
{
    reset_all();

    KillTimer(TIMER);
}

public void OnMapStart(){

TIMER = CreateTimer(1.0 * GetConVarInt(TIME), zsresetsprites,_, TIMER_REPEAT);

}

public Action zsresetsprites(Handle timer) 
{
   for(int client = 1; client <= MAXPLAYERS; client++)
    {
        reset_sprite_normal(client);
        reset_sprite_thirdstrike(client);
    }
} 

bool IsPlayerIncapacitated(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1);
}

int GetClientTempHealth(int client)
{
    int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_iCvar_pain_pills_decay_rate));
    return tempHealth < 0 ? 0 : tempHealth;
}