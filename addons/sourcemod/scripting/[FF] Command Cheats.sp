#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "1.0"

ConVar g_cvChaos;

bool g_bChaosHeal[MAXPLAYERS+1];
int g_iHealing[MAXPLAYERS+1];
int g_iClone[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

char g_sAnimations[47][64] = 
{
    "incap_crawl", 
    "Idle_Standing_SniperZoomed",
    "CalmRun_Elites",
    "CalmRunN_PumpShotgun_layer",
    "CalmWalk_Elites",
    "Collapse_to_Hanging",
    "CrouchWalk_GasCan",
    "deathpose_back",
    "deathpose_front",
    "drag",
    "Fall",
    "Flinch_01",
    "Flinch_Ledge_01",
    "Heal_Self_Crouching_01",
    "Idle_Crouching_Elites",
    "Idle_Crouching_Grenade_Ready",
    "Idle_Fall_From_TankPunch",
    "Idle_Falling",
    "Idle_Incap_Hanging2",
    "Idle_Incap_Standing_SmokerChoke_germany",
    "Idle_Rescue_01c",
    "Idle_Standing_Minigun",
    "Idle_Tongued_choking_ground",
    "Jump_GasCan_01",
    "Ladder_Ascend",
    "Ladder_Descend",
    "Land_Injured",
    "Melee_Shove_Running_Rifle",
    "Melee_Stomp_Standing_Rifle",
    "Melee_Straight_Standing_Rifle",
    "melee_sweep_o2",
    "Pickup_Standing_M4",
    "Pickup_Standing_M4_layer",
    "Pills_Swallow",
    "Pulled_Running_Rifle",
    "Push_Pull",
    "Run_Elites",
    "Run_FirstAidKit",
    "Run_Grenade_Ready",
    "Shoot_Running_Grenade2",
    "shoot_standing_gascan2",
    "Shoved_Backward",
    "Shoved_Forward",
    "Shoved_Leftward",
    "Shoved_Rightward",
    "Unholster_Standing_Elites",
    "Walk_Grenade_Ready"
};

public Plugin myinfo =
{
    name = "[L4D2] Fun Chaos Cheat Commands",
    author = "Shadow",
    description = "Fun Chaotic Commands with netprops",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    g_cvChaos = CreateConVar("sm_chaos_enable", "1", "Habilita el caos", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    RegConsoleCmd("sm_fakeincap", Cmd_FakeIncap);

    RegConsoleCmd("sm_render", Cmd_CPUGPU);
    RegConsoleCmd("sm_fade", Cmd_Fade);
    RegConsoleCmd("sm_collision", Cmd_Collision);
    RegConsoleCmd("sm_lagmove", Cmd_LagMove);
    RegConsoleCmd("sm_teamchange", Cmd_TeamChange);
    RegConsoleCmd("sm_teamset", Cmd_TeamSet);
    RegConsoleCmd("sm_zclass", Cmd_ZClassChaos);
    RegConsoleCmd("sm_scale", Cmd_Scale);

    RegConsoleCmd("sm_healchaos", Cmd_HealChaos);

    HookEvent("heal_begin", event_heal_started);
    HookEvent("heal_success", event_heal_stopped);
    HookEvent("heal_end", event_heal_stopped);
    HookEvent("heal_interrupted", event_heal_stopped);
    HookEvent("player_death", event_heal_stopped);
    HookEvent("player_team", event_heal_stopped);
}

public void event_heal_started(Handle event, const char[] name, bool dontBroadcast)
{
    int client1 = GetClientOfUserId(GetEventInt(event, "userid"));
    int client2 = GetClientOfUserId(GetEventInt(event, "subject"));

    switch ( 3 )
    {
        case 1:
        {
            if (g_bChaosHeal[client1])
                CreateClone(client1);
        }
        case 2:
        {
            if (g_bChaosHeal[client2])
                CreateClone(client2);
        }
        case 3:
        {
            if (g_bChaosHeal[client1])
                CreateClone(client1);

            if (g_bChaosHeal[client2])
                CreateClone(client2);
        }
    }
}

public void event_heal_stopped(Handle event, const char[] name, bool dontBroadcast)
{
    int client1 = GetClientOfUserId(GetEventInt(event, "userid"));
    int client2 = GetClientOfUserId(GetEventInt(event, "subject"));
    if ( IsValidClientIndex(client1) )
    {
        g_iHealing[client1] = 0;
        RemoveClone(client1);
    }
    if ( IsValidClientIndex(client2) )
    {
        g_iHealing[client2] = 0;
        RemoveClone(client2);
    }
}

public Action Cmd_CPUGPU(int client, int args)
{
    if (!g_cvChaos.BoolValue || !IsValidClient(client))
        return Plugin_Handled;

    int mincpu = GetRandomInt(0, 2);
    int maxcpu = GetRandomInt(0, 2);
    int mingpu = GetRandomInt(0, 2);
    int maxgpu = GetRandomInt(0, 2);

    if (args >= 4)
    {
        char s1[8], s2[8], s3[8], s4[8];
        GetCmdArg(1, s1, sizeof(s1));
        GetCmdArg(2, s2, sizeof(s2));
        GetCmdArg(3, s3, sizeof(s3));
        GetCmdArg(4, s4, sizeof(s4));

        mincpu = StringToInt(s1);
        maxcpu = StringToInt(s2);
        mingpu = StringToInt(s3);
        maxgpu = StringToInt(s4);
    }

    SetEntProp(client, Prop_Send, "m_nMinCPULevel", mincpu);
    SetEntProp(client, Prop_Send, "m_nMaxCPULevel", maxcpu);
    SetEntProp(client, Prop_Send, "m_nMinGPULevel", mingpu);
    SetEntProp(client, Prop_Send, "m_nMaxGPULevel", maxgpu);

    PrintToChatAll("[CHAOS] %N CPU[%d-%d] GPU[%d-%d]", client, mincpu, maxcpu, mingpu, maxgpu);

    return Plugin_Handled;
}

public Action Cmd_Fade(int client, int args)
{
    if (!g_cvChaos.BoolValue || !IsValidClient(client))
        return Plugin_Handled;

    float min = GetRandomFloat(0.0, 500.0);
    float max = GetRandomFloat(500.0, 2000.0);

    if (args >= 2)
    {
        char sMin[32], sMax[32];
        GetCmdArg(1, sMin, sizeof(sMin));
        GetCmdArg(2, sMax, sizeof(sMax));

        min = StringToFloat(sMin);
        max = StringToFloat(sMax);
    }

    SetEntPropFloat(client, Prop_Send, "m_fadeMinDist", min);
    SetEntPropFloat(client, Prop_Send, "m_fadeMaxDist", max);

    PrintToChatAll("[CHAOS] %N fade min %.1f | max %.1f", client, min, max);

    return Plugin_Handled;
}

public Action Cmd_HealChaos(int client, int args)
{
    if (!IsValidClientInGame(client))
        return Plugin_Handled;

    g_bChaosHeal[client] = !g_bChaosHeal[client];

    PrintToChat(client, "[CHAOS] Heal animaciones: %s", g_bChaosHeal[client] ? "ON" : "OFF");

    return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int& buttons)
{
    if ( !IsValidClientAlive(client) ) return Plugin_Continue;
    if ( g_iHealing[client]==0 ) return Plugin_Continue;
    if (!g_bChaosHeal[client])
    return Plugin_Continue;
    
    if ( buttons&IN_DUCK ){}
    else if ( g_iHealing[client]==2 ){}
    else if ( g_iHealing[client]==-2 ){}
    else return Plugin_Continue;
    
    int iRand = GetRandomInt(0, 46);
    int clone = EntRefToEntIndex(g_iClone[client]);
    if ( !IsValidEntity(clone) )
    {
        //PrintToChatAll("FATAL ERROR: Clone doesnt exist!");
        return Plugin_Continue;
    }
    
    //make sure this condition runs once per healing
    if ( g_iHealing[client] > 0 )
    {
        SetEntityRenderMode(clone, RENDER_NORMAL); //make clone visible
        SetEntityRenderMode(client, RENDER_NONE); //make original survivor visible
        g_iHealing[client] *= -1; 
    }
    
    // Set animation...
    SetVariantString(g_sAnimations[iRand]);
    AcceptEntityInput(clone, "SetAnimation");
    SetEntPropFloat(clone, Prop_Send, "m_flPlaybackRate", 4.0); //animation speed 1.0=normal

    //random angle is funniest...
    float fAngle[3];
    //fAngle[0] = 180.0 * GetRandomInt(0, 1);
    fAngle[1] = GetRandomFloat(0.0, 360.0);
    //fAngle[2] = 180.0 * GetRandomInt(0, 1);
    TeleportEntity(clone, NULL_VECTOR, fAngle, NULL_VECTOR);
    
    //PrintToConsole(client, "Success! Random animation(%i): %s", iRand, g_sAnimations[iRand]);
    return Plugin_Continue;
}

public Action Cmd_FakeIncap(int client, int args)
{
    if (!g_cvChaos.BoolValue || !IsValidClient(client))
        return Plugin_Handled;

    SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
    return Plugin_Handled;
}

public Action Cmd_Stagger(int client, int args)
{
    if (!g_cvChaos.BoolValue || !IsValidClient(client))
        return Plugin_Handled;

    SetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1.0);
    return Plugin_Handled;
}

public Action Cmd_LagMove(int client, int args)
{
    if (!g_cvChaos.BoolValue || !IsValidClient(client))
        return Plugin_Handled;

    float value = GetRandomFloat(0.5, 2.0);

    if (args >= 1)
    {
        char sArg[32];
        GetCmdArg(1, sArg, sizeof(sArg));
        value = StringToFloat(sArg);
    }

    SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", value);
    PrintToChat(client, "[CHAOS] speed = %.2f", value);

    return Plugin_Handled;
}

public Action Cmd_Collision(int client, int args)
{
    if (!g_cvChaos.BoolValue || !IsValidClient(client))
        return Plugin_Handled;

    int group = GetRandomInt(0, 20);

    if (args >= 1)
    {
        char sArg[32];
        GetCmdArg(1, sArg, sizeof(sArg));
        group = StringToInt(sArg);
    }

    SetEntProp(client, Prop_Send, "m_CollisionGroup", group);
    PrintToChat(client, "[CHAOS] collision = %d", group);

    return Plugin_Handled;
}

public Action Cmd_TeamChange(int client, int args)
{
    if (!g_cvChaos.BoolValue || !IsValidClient(client))
        return Plugin_Handled;

    int team = GetRandomInt(1, 3);

    if (args >= 1)
    {
        char sArg[32];
        GetCmdArg(1, sArg, sizeof(sArg));
        team = StringToInt(sArg);
    }

    ChangeClientTeam(client, team);
    PrintToChatAll("[CHAOS] %N → team (changed to) %d", client, team);

    return Plugin_Handled;
}

public Action Cmd_TeamSet(int client, int args)
{
    if (!g_cvChaos.BoolValue || !IsValidClient(client))
        return Plugin_Handled;

    int team = GetRandomInt(1, 3);

    if (args >= 1)
    {
        char sArg[32];
        GetCmdArg(1, sArg, sizeof(sArg));
        team = StringToInt(sArg);
    }

    SetEntProp(client, Prop_Send, "m_iTeamNum", team);

    PrintToChatAll("[CHAOS] %N → team (Set) %d", client, team);

    return Plugin_Handled;
}

public Action Cmd_ZClassChaos(int client, int args)
{
    if (!g_cvChaos.BoolValue || !IsValidClient(client))
        return Plugin_Handled;

    int zclass = GetRandomInt(1, 6);

    if (args >= 1)
    {
        char sArg[32];
        GetCmdArg(1, sArg, sizeof(sArg));
        zclass = StringToInt(sArg);
    }

    SetEntProp(client, Prop_Send, "m_zombieClass", zclass);
    PrintToChatAll("[CHAOS] %N → clase %d", client, zclass);

    return Plugin_Handled;
}

public Action Cmd_Scale(int client, int args)
{
    if (!g_cvChaos.BoolValue || !IsValidClient(client))
        return Plugin_Handled;

    float scale = GetRandomFloat(0.5, 2.0);

    if (args >= 1)
    {
        char sArg[32];
        GetCmdArg(1, sArg, sizeof(sArg));
        scale = StringToFloat(sArg);
    }

    if (scale < 0.3) scale = 0.3;
    if (scale > 3.0) scale = 3.0;

    SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
    PrintToChatAll("[CHAOS] %N ahora mide x%.2f", client, scale);

    return Plugin_Handled;
}

stock bool RemoveClone(int client)
{
    if ( !IsValidClientInGame(client) )
        return false;
        
    //PrintToChatAll("Trying to remove clone...");
    int clone = EntRefToEntIndex(g_iClone[client]);
    SetEntityRenderMode(client, RENDER_NORMAL);
    
    if ( !IsValidEntity(clone) )
    {
        //PrintToChatAll("Clone(%i) not found!", clone);
        g_iClone[client] = INVALID_ENT_REFERENCE;
        return false;
    }
    
    //PrintToChatAll("Clone removed successfully. Ref=%i, Index=%i!!", g_iClone[client], clone);
    AcceptEntityInput(clone, "ClearParent");
    RemoveEntity(clone);
    g_iClone[client] = INVALID_ENT_REFERENCE;
    g_iHealing[client] = 0;
    return true;
}

stock bool CreateClone(int client)
{
    if ( !IsValidClientAlive(client) )
        return false;
    
    int clone = EntRefToEntIndex(g_iClone[client]);
    
    //check if clone already exists...
    if ( IsValidEntity(clone) )
    {
        return false;
    }
    
    //create a new clone...
    clone = CreateEntityByName("prop_dynamic");
    g_iClone[client] = EntIndexToEntRef(clone);
    //PrintToChatAll("Creating a clone first time. Ref(%i) Index(%i).", g_iClone[client], clone);
    
    char modelname[64];
    GetEntPropString(client, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
    
    //check if clone was created successfully...
    if ( !IsValidEntity(clone) )
    {
        //PrintToChatAll("Failed to create prop_dynamic '%s' (%N)", modelname, client);
        return false;
    }
    
    //-------------------------------------------------------------
    //if everything's alright...
    //-------------------------------------------------------------
    SetEntityModel(clone, modelname);
    
    //attach clone to survivor...
    SetVariantString("!activator");
    AcceptEntityInput(clone, "SetParent", client);
    
    //set position:
    TeleportEntity(clone, view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
    //TeleportEntity(clone, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR); //does not work
    //PrintToChat(client, "Clone created successfully!");
    
    //we need to make clone independent from survivor before setting their rendering.
    AcceptEntityInput(clone, "ClearParent");
    
    SetEntityRenderMode(clone, RENDER_NONE); //make clone invisible temporarily
    
    g_iHealing[client] = 1;
    if ( IsFakeClient(client) )
     g_iHealing[client] = 2;

    return true;
}

public void OnClientDisconnect(int client)
{
    RemoveClone(client);
}

stock int IsValidClientInGame(int client)
{
    if (IsValidClientIndex(client))
    {
        if (IsClientInGame(client))
            return 1;
    }
    return 0;
}

stock int IsValidClientIndex(int index)
{
    if (index>0 && index<=MaxClients)
    {
        return 1;
    }
    return 0;
}

public bool IsValidClientAlive(int client)
{
    if (client <= 0)
        return false;
    if (!IsClientConnected(client))
        return false;
    if (!IsClientInGame(client))
        return false;
    if (!IsPlayerAlive(client))
        return false;
    
    return true;
}

void GiveItem(int client, char[] sItem)
{
    int flags = GetCommandFlags("give");
    SetCommandFlags("give", flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "give %s", sItem);
    SetCommandFlags("give", flags);
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

int GetRandomPlayer()
{
    int clients[MAXPLAYERS+1];
    int count = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            clients[count++] = i;
        }
    }

    if (count == 0)
        return -1;

    return clients[GetRandomInt(0, count - 1)];
}

int GetRandomSurvivor(int exclude)
{
    int list[MAXPLAYERS+1];
    int count = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && i != exclude)
        {
            list[count++] = i;
        }
    }

    if (count == 0)
        return -1;

    return list[GetRandomInt(0, count - 1)];
}