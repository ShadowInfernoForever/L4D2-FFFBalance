#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <colors>

#pragma newdecls required
#pragma semicolon 1

ConVar g_hNukeDamage, g_hNukeRadius, g_hNukeVelocity, g_hNukeLimit, g_hNukeTime, g_hParticle;

char NukeDamage[16], NukeRadius[16];
float ProjectileVelo;

int Rocketparts[2000][2], Limit[MAXPLAYERS+1], Time;
    
bool isLaunch[MAXPLAYERS+1] = false;
    
Handle HandleTimer = null;

#define NUKE_SOUND    "nuke/explosion.mp3"
#define NUKE_LAUNCH   "nuke/missile.mp3"
#define COUNT_SOUND   "UI/Beep07.wav"

#define amg65 "models/missiles/f18_agm65maverick.mdl"
#define MOLO  "models/w_models/weapons/w_eq_molotov.mdl"

#define PARTICLE_1        "explosion_core"
#define PARTICLE_2        "nuke_core"

public Plugin myinfo =
{
    name = "[L4D2] Nuclear Missile",
    author = "King_OXO",
    description = "Call A Nuclear Missile On Crosshair(new codes, thanks Silver)",
    version = "3.0",
    url = "https://forums.alliedmods.net/showthread.php?t=336654"
};

public void OnPluginStart()
{
    g_hNukeDamage   = CreateConVar("l4d2_nuke_damage", "500.0", "Damage when Missile explodes", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
    g_hNukeLimit    = CreateConVar("l4d2_nuke_limit", "15.0", "Limit to use the nuke missile", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
    g_hNukeTime     = CreateConVar("l4d2_nuke_time", "4", "time for the nuclear missile to be created", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
    g_hParticle     = CreateConVar("l4d2_nuke_particle_type", "1", "Choose the particle nuke", FCVAR_NOTIFY, true, 1.0, true, 2.0);
    g_hNukeRadius   = CreateConVar("l4d2_nuke_radius", "1500.0", "Missile blast distance", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
    g_hNukeVelocity = CreateConVar("l4d2_nuke_velocity", "2000.0", "Missile Velocity", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
    
    HookEvent("player_death", Event_death);
    HookEvent("round_end", Event_end);
    HookEvent("finale_vehicle_leaving", Event_Explode);
    
    RegAdminCmd("sm_nuke", Cmd_Nuke, ADMFLAG_KICK);
    RegAdminCmd("sm_nuke_reload", Cmd_NukeReload, ADMFLAG_KICK);
    
    AutoExecConfig(true, "l4d2_nuke_missile");
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnMapStart()
{
    PrecacheParticle(PARTICLE_1);
    PrecacheParticle(PARTICLE_2);
    
    PrecacheModel(amg65, true);
    
    PrecacheSound(NUKE_SOUND, true);
    PrecacheSound(NUKE_LAUNCH, true);
    PrecacheSound(COUNT_SOUND, true);
    
    AddFileToDownloadsTable("sound/nuke/missile.mp3");
    AddFileToDownloadsTable("sound/nuke/explosion.mp3");
    AddFileToDownloadsTable("particles/nuke.pcf");
    AddFileToDownloadsTable("particles/nuke2.pcf");
    AddFileToDownloadsTable("maps/c1m1_hotel_particles.txt");
    AddFileToDownloadsTable("maps/c1m2_streets_particles.txt");
    AddFileToDownloadsTable("maps/c1m3_mall_particles.txt");
    AddFileToDownloadsTable("maps/c1m4_atrium_particles.txt");
    AddFileToDownloadsTable("maps/c2m1_highway_particles.txt");
    AddFileToDownloadsTable("maps/c2m2_fairgrounds_particles.txt");
    AddFileToDownloadsTable("maps/c2m3_coaster_particles.txt");
    AddFileToDownloadsTable("maps/c2m4_barns_particles.txt");
    AddFileToDownloadsTable("maps/c2m5_concert_particles.txt");
    AddFileToDownloadsTable("maps/c3m1_plankcountry_particles.txt");
    AddFileToDownloadsTable("maps/c3m2_swamp_particles.txt");
    AddFileToDownloadsTable("maps/c3m3_shantytown_particles.txt");
    AddFileToDownloadsTable("maps/c3m4_plantation_particles.txt");
    AddFileToDownloadsTable("maps/c4m1_milltown_a_particles.txt");
    AddFileToDownloadsTable("maps/c4m2_sugarmill_a_particles.txt");
    AddFileToDownloadsTable("maps/c4m3_sugarmill_b_particles.txt");
    AddFileToDownloadsTable("maps/c4m4_milltown_b_particles.txt");
    AddFileToDownloadsTable("maps/c4m5_milltown_escape_particles.txt");
    AddFileToDownloadsTable("maps/c5m1_waterfront_particles.txt");
    AddFileToDownloadsTable("maps/c5m2_park_particles.txt");
    AddFileToDownloadsTable("maps/c5m3_cemetery_particles.txt");
    AddFileToDownloadsTable("maps/c5m4_quarter_particles.txt");
    AddFileToDownloadsTable("maps/c5m5_bridge_particles.txt");
    AddFileToDownloadsTable("maps/c6m1_riverbank_particles.txt");
    AddFileToDownloadsTable("maps/c6m2_bedlam_particles.txt");
    AddFileToDownloadsTable("maps/c6m3_port_particles.txt");
    AddFileToDownloadsTable("maps/c7m1_docks_particles.txt");
    AddFileToDownloadsTable("maps/c7m2_barge_particles.txt");
    AddFileToDownloadsTable("maps/c7m3_port_particles.txt");
    AddFileToDownloadsTable("maps/c8m1_apartment_particles.txt");
    AddFileToDownloadsTable("maps/c8m2_subway_particles.txt");
    AddFileToDownloadsTable("maps/c8m3_sewers_particles.txt");
    AddFileToDownloadsTable("maps/c8m4_interior_particles.txt");
    AddFileToDownloadsTable("maps/c8m5_rooftop_particles.txt");
    AddFileToDownloadsTable("maps/c9m1_alleys_particles.txt");
    AddFileToDownloadsTable("maps/c9m2_lots_particles.txt");
    AddFileToDownloadsTable("maps/c10m1_caves_particles.txt");
    AddFileToDownloadsTable("maps/c10m2_drainage_particles.txt");
    AddFileToDownloadsTable("maps/c10m3_ranchhouse_particles.txt");
    AddFileToDownloadsTable("maps/c10m4_mainstreet_particles.txt");
    AddFileToDownloadsTable("maps/c10m5_houseboat_particles.txt");
    AddFileToDownloadsTable("maps/c11m1_greenhouse_particles.txt");
    AddFileToDownloadsTable("maps/c11m2_offices_particles.txt");
    AddFileToDownloadsTable("maps/c11m3_garage_particles.txt");
    AddFileToDownloadsTable("maps/c11m4_terminal_particles.txt");
    AddFileToDownloadsTable("maps/c11m5_runway_particles.txt");
    AddFileToDownloadsTable("maps/c12m1_hilltop_particles.txt");
    AddFileToDownloadsTable("maps/c12m2_traintunnel_particles.txt");
    AddFileToDownloadsTable("maps/c12m3_bridge_particles.txt");
    AddFileToDownloadsTable("maps/c12m4_barn_particles.txt");
    AddFileToDownloadsTable("maps/c12m5_cornfield_particles.txt");
    AddFileToDownloadsTable("maps/c13m1_alpinecreek_particles.txt");
    AddFileToDownloadsTable("maps/c13m2_southpinestream_particles.txt");
    AddFileToDownloadsTable("maps/c13m3_memorialbridge_particles.txt");
    AddFileToDownloadsTable("maps/c13m4_cutthroatcreek_particles.txt");
}

public Action Event_death(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(client) && GetClientTeam(client) == 2)
    {
        Limit[client] = 0;
        //CPrintToChat(client, "\x04[\x03NM\x04] \x01Nuke Limit\x01:\x03 Reseted\x05!");
    }
}

public Action Event_end(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(client) && GetClientTeam(client) == 2)
    {
        Limit[client] = 0;
        //CPrintToChat(client, "\x04[\x03NM\x04] \x01Nuke Limit\x01:\x03 Reseted\x05!");
    }
}

public Action Event_Explode(Event event, const char[] name, bool dontBroadcast)
{
    float vPos[3], vAng[3], vPosEnd[3];
    char buffer[32];
    GetCurrentMap(buffer, sizeof(buffer));
    if ( strcmp(buffer, "c5m5_bridge")==0 )
    {
        vPos[0] = 9460.0, vAng[0] = 15.0, vPosEnd[0] = 4272.0;
        vPos[1] = 3156.0, vAng[1] = 154.0, vPosEnd[1] = 4403.0;
        vPos[2] = 1359.0, vAng[2] = 0.00, vPosEnd[2] = -195.0;
        CallMissile(vPos, vAng, vPosEnd);
    }
    else if ( strcmp(buffer, "c6m3_port")==0 )
    {
        vPos[0] = 2804.0, vAng[0] = 11.0, vPosEnd[0] = 749.0;
        vPos[1] = -2574.0, vAng[1] = 169.0, vPosEnd[1] = -1834.0;
        vPos[2] = 638.0, vAng[2] = 0.00, vPosEnd[2] = -583.0;
        CallMissile(vPos, vAng, vPosEnd);
    }
    
    else if ( strcmp(buffer, "c11m5_runway")==0 )
    {
        vPos[0] = 4108.0, vAng[0] = 5.0, vPosEnd[0] = 4544.0;
        vPos[1] = -319.0, vAng[1] = 87.0, vPosEnd[1] = 10916.0;
        vPos[2] = 896.0, vAng[2] = 0.00, vPosEnd[2] = -274.0;
        CallMissile(vPos, vAng, vPosEnd);
    }
    else if ( strcmp(buffer, "c8m5_rooftop")==0 )
    {
        vPos[0] = 10912.0, vAng[0] = 17.0, vPosEnd[0] = 7149.0;
        vPos[1] = 7105.0, vAng[1] = 159.0, vPosEnd[1] = 8563.0;
        vPos[2] = 7123.0, vAng[2] = -0.00, vPosEnd[2] = 5980.0;
        CallMissile(vPos, vAng, vPosEnd);
    }
    else return;
}

public Action Cmd_NukeReload(int client, int args)
{
    if(IsValidClient(client) && GetClientTeam(client) == 2)
    {
        Limit[client] = 0;
        CPrintToChat(client, "\x04[\x03NM\x04] \x01Nuke Limit\x01:\x03 Reseted\x05!");
    }
}
public Action Cmd_Nuke(int client, int args)
{
    if (!(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2))
    {
        CPrintToChat(client, "\x04[\x03NM\x04] \x05only \x03survivor \x01can use this \x04command \x01!");

        return Plugin_Handled;
    }
    
    int NukeLimit = GetConVarInt(g_hNukeLimit);
    if(!isLaunch[client])
    {
        Time = GetConVarInt(g_hNukeTime);
        if (HandleTimer == null)
        {
            HandleTimer = CreateTimer(1.0, TacticalNuke, client, TIMER_REPEAT); //do not change the time value
        }
        isLaunch[client] = true;
        Limit[client] += 1;
        CPrintToChat(client, "\x04[\x03NM\x04] \x01Nuke Limit\x01:\x03 %d \x01/ \x03%d", Limit[client], NukeLimit);
    }
    else
    {
        CPrintToChat(client, "\x04[\x03NM\x04]\x01Have you ever called a nuclear missile");
    }
    
    return Plugin_Handled;
}

public Action TacticalNuke(Handle timer, int client)
{
    if (HandleTimer == null)
    {
        return Plugin_Stop;
    }
    
    if(Time == 0)
    {
        if(IsPlayerAlive(client) && GetClientTeam(client) == 2)
        {
            NukeMissile(client);
        }
        
        if (HandleTimer != null)
        {
            KillTimer(HandleTimer);
            HandleTimer = null;
        }
        
        isLaunch[client] = false;
    }
    else if(Time > 0)
    {
        Time -= 1;
        PrintHintTextToAll("[NM]\nA NUCLEAR MISSILE IS COMING\n TIME -> %d <-", Time);
        for(int i = 1; i <= MaxClients; i++)
        {
            if(i > 0 && IsClientInGame(i) && !IsFakeClient(i))
            {
                EmitSoundToClient(i, COUNT_SOUND);
            }
        }
    }
    
    return Plugin_Continue;
}

void CallMissile( float vPos[3], float vAng[3], float vPosEnd[3])
{
    float bfVol[3];
    int body = CreateEntityByName( "molotov_projectile" );
    if( body != -1 )
    {
        DispatchKeyValue( body, "model", MOLO );
        DispatchKeyValueVector( body, "origin", vPos );
        DispatchKeyValueVector( body, "Angles", vAng );
        SetEntPropFloat( body, Prop_Send,"m_flModelScale",0.00001 );
        SetEntityGravity( body, 0.001 );
        DispatchSpawn( body );
    }
    
    int exau = CreateExaust( body, 90 );
    int atth = CreateAttachment( body, amg65, 0.6, 5.0 );

    Rocketparts[body][0] = exau;
    Rocketparts[body][1] = atth;
    
    SDKHook( body, SDKHook_StartTouch, OnNukeCollide );
        
    MakeVectorFromPoints( vPos, vPosEnd, bfVol );
    NormalizeVector( bfVol, bfVol );
    GetVectorAngles( bfVol, vAng );
    ProjectileVelo = GetConVarFloat(g_hNukeVelocity);
    ScaleVector( bfVol, ProjectileVelo );
    TeleportEntity( body, NULL_VECTOR, vAng, bfVol );
     
    for(int i = 1; i <= MaxClients; i++)
    {
        if(i > 0 && IsClientInGame(i) && !IsFakeClient(i))
        {
            EmitSoundToClient(i, NUKE_LAUNCH);
        }
    }
}

void NukeMissile( int client )
{
    float vAng[3];
    float vPos[3];
    
    GetClientEyePosition( client,vPos );
    GetClientEyeAngles( client, vAng );
    Handle hTrace = TR_TraceRayFilterEx( vPos, vAng, MASK_SHOT, RayType_Infinite, bTraceEntityFilterPlayer );
    
    if ( TR_DidHit( hTrace ) )
    {
        float vBuffer[3];
        float vStart[3];
        float vDistance = -35.0;
        
        TR_GetEndPosition( vStart, hTrace );
        GetVectorDistance( vPos, vStart, false );
        GetAngleVectors( vAng, vBuffer, NULL_VECTOR, NULL_VECTOR );
        
        vPos[0] = vStart[0] + ( vBuffer[0] * vDistance );
        vPos[1] = vStart[1] + ( vBuffer[1] * vDistance );
        vPos[2] = vStart[2] + ( vBuffer[2] * vDistance );
        
        float ClientPos[3];
        float bfAng[3];
        float bfVol[3];
        GetEntPropVector( client, Prop_Send, "m_vecOrigin", ClientPos );
        GetEntPropVector( client, Prop_Data, "m_angRotation", bfAng );
        
        ClientPos[2] += 800;
    
        int body = CreateEntityByName( "molotov_projectile" );
        if( body != -1 )
        {
            DispatchKeyValue( body, "model", MOLO );
            DispatchKeyValueVector( body, "origin", ClientPos );
            DispatchKeyValueVector( body, "Angles", bfAng );
            SetEntPropFloat( body, Prop_Send,"m_flModelScale",0.00001 );
            SetEntityGravity( body, 0.001 );
            SetEntPropEnt( body, Prop_Data, "m_hOwnerEntity", client );
            DispatchSpawn( body );
        }
    
        int exau = CreateExaust( body, 90 );
        int atth = CreateAttachment( body, amg65, 0.6, 5.0 );

        Rocketparts[body][0] = exau;
        Rocketparts[body][1] = atth;
    
        SDKHook( body, SDKHook_StartTouch, OnNukeCollide );
    
        ClientPos[0] += GetRandomFloat( -20.0, 20.0 );
        ClientPos[1] += GetRandomFloat( -20.0, 20.0 );
        ClientPos[2] += GetRandomFloat( -10.0, 5.0 );
        
        MakeVectorFromPoints( ClientPos, vPos, bfVol );
        NormalizeVector( bfVol, bfVol );
        GetVectorAngles( bfVol, bfAng );
        ProjectileVelo = GetConVarFloat(g_hNukeVelocity);
        ScaleVector( bfVol, ProjectileVelo );
        TeleportEntity( body, NULL_VECTOR, bfAng, bfVol );
        
    }
    for(int i = 1; i <= MaxClients; i++)
    {
        if(i > 0 && IsClientInGame(i) && !IsFakeClient(i))
        {
            EmitSoundToClient(i, NUKE_LAUNCH);
        }
    }
    delete hTrace;
}

public Action OnNukeCollide( int ent, int target )
{
    int part1 = Rocketparts[ent][1];
    int part0 = Rocketparts[ent][0];
    Rocketparts[ent][1] = -1;
    Rocketparts[ent][0] = -1;
    
    NukeExplosion( ent );
    DoNukeDamage( ent );

    SDKUnhook( ent, SDKHook_TouchPost, OnNukeCollide );
    if ( IsValidEntity( part1 )) AcceptEntityInput( part1, "kill" );
    if ( IsValidEntity( part0 )) AcceptEntityInput(part0, "kill" );
    if ( IsValidEntity( ent )) AcceptEntityInput( ent, "kill" );
}

void NukeExplosion( int entity )
{
    float vPos[3];
    GetEntPropVector( entity, Prop_Send, "m_vecOrigin", vPos );
    
    int particle = CreateEntityByName("info_particle_system");
    if( particle != -1 )
    {
        int type = GetConVarInt(g_hParticle);
        if(type == 1)
        {
            DispatchKeyValue(particle, "effect_name", PARTICLE_1);
        }
        else if(type == 2)
        {
            DispatchKeyValue(particle, "effect_name", PARTICLE_2);
        }
        
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");

        TeleportEntity(particle, vPos, NULL_VECTOR, NULL_VECTOR);

        SetVariantString("OnUser1 !self:Kill::45.0:-1");
        AcceptEntityInput(particle, "AddOutput");
        AcceptEntityInput(particle, "FireUser1"); 
    }
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if(i > 0 && IsClientInGame(i) && !IsFakeClient(i))
        {
            EmitSoundToClient(i, NUKE_SOUND);
        }
    }
}

void DoNukeDamage( int entity )
{
    float MissilePos[3];
    GetEntPropVector( entity, Prop_Send, "m_vecOrigin", MissilePos );
    g_hNukeDamage.GetString(NukeDamage, sizeof(NukeDamage));
    g_hNukeRadius.GetString(NukeRadius, sizeof(NukeRadius));
     
    MakeDamage( MissilePos );
}

int CreateExaust( int ent, int length )
{ 
    float flmOri[3] = { 0.0, 0.0, 0.0 };
    float flmAng[3] = { 0.0, 180.0, 0.0 };
    char exaustName[128];
    Format( exaustName, sizeof( exaustName ), "target%d", ent );
    
    int exaust = CreateEntityByName( "env_steam" );
    if ( exaust != -1 )
    {
        char lg[32];
        Format( lg, sizeof( lg ), "%d.0", length );
        DispatchKeyValue( ent, "targetname", exaustName );
        DispatchKeyValue( exaust, "SpawnFlags", "1" );
        DispatchKeyValue( exaust, "Type", "0" );
        DispatchKeyValue( exaust, "InitialState", "1" );
        DispatchKeyValue( exaust, "Spreadspeed", "10" );
        DispatchKeyValue( exaust, "Speed", "200" );
        DispatchKeyValue( exaust, "Startsize", "10" );
        DispatchKeyValue( exaust, "EndSize", "30" );
        DispatchKeyValue( exaust, "Rate", "555" );
        DispatchKeyValue( exaust, "RenderColor", "255 100 0");
        DispatchKeyValue( exaust, "JetLength", lg ); 
        DispatchKeyValue( exaust, "RenderAmt", "180" );
    
        DispatchSpawn( exaust );
        SetVariantString( exaustName );
        AcceptEntityInput( exaust, "SetParent", exaust, exaust, 0 );
        TeleportEntity( exaust, flmOri, flmAng, NULL_VECTOR );
        AcceptEntityInput( exaust, "TurnOn" );
    }
    return exaust;
}

int CreateAttachment( int ent, char[] Model, float ScaleSize, float fwdPos )
{
    float athPos[3];
    float athAng[3];
    float caPos[3] = { 0.0, 0.0, 0.0 };
    GetEntPropVector( ent, Prop_Send, "m_vecOrigin", athPos );
    GetEntPropVector( ent, Prop_Data, "m_angRotation", athAng );
    int attch = CreateEntityByName( "prop_dynamic_override" );
    if( attch != -1 )
    {
        caPos[1] = fwdPos;
        char namE[20];
        Format( namE, sizeof( namE ), "missile%d", ent );
        DispatchKeyValue( ent, "targetname", namE );
        DispatchKeyValue( attch, "model", Model );  
        DispatchKeyValue( attch, "parentname", namE); 
        DispatchKeyValueVector( attch, "origin", athPos );
        DispatchKeyValueVector( attch, "Angles", athAng );
        SetVariantString( namE );
        AcceptEntityInput( attch, "SetParent", attch, attch, 0 );
        DispatchKeyValueFloat( attch, "fademindist", 10000.0 );
        DispatchKeyValueFloat( attch, "fademaxdist", 20000.0 );
        DispatchKeyValueFloat( attch, "fadescale", 0.0 ); 
        SetEntPropFloat( attch, Prop_Send,"m_flModelScale", ScaleSize );
        DispatchSpawn( attch );
        TeleportEntity( attch, caPos, NULL_VECTOR, NULL_VECTOR );
    }
    return attch;
}

public bool bTraceEntityFilterPlayer( int entity, int contentsMask )
{
    return ( entity > MaxClients || !entity );
}

void MakeDamage( float vPos[3] )
{
    int entity = CreateEntityByName("env_explosion");
    TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
    DispatchKeyValue(entity, "iMagnitude", NukeDamage);
    DispatchKeyValue(entity, "iRadiusOverride", NukeRadius);
    DispatchKeyValue(entity, "rendermode", "5");
    DispatchKeyValue(entity, "spawnflags", "128");
    
    DispatchSpawn(entity);
	SetEntProp(entity, Prop_Data, "m_iHammerID", 1078682);
    
    SetVariantString("OnUser1 !self:Explode::0.2:1)");    // Add a delay to allow explosion effect to be visible
    AcceptEntityInput(entity, "Addoutput");
    AcceptEntityInput(entity, "FireUser1");
}

public int Fade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
    Handle msg = StartMessageOne("Fade", target);
    BfWriteShort(msg, 500);
    BfWriteShort(msg, duration);
    if (type == 0)
        BfWriteShort(msg, (0x0002 | 0x0008));
    else
        BfWriteShort(msg, (0x0001 | 0x0010));
    BfWriteByte(msg, red);
    BfWriteByte(msg, green);
    BfWriteByte(msg, blue);
    BfWriteByte(msg, alpha);
    EndMessage();
}

public void Shake(int target, float intensity)
{
    Handle msg;
    msg = StartMessageOne("Shake", target);
    
    BfWriteByte(msg, 0);
    BfWriteFloat(msg, intensity);
    BfWriteFloat(msg, 10.0);
    BfWriteFloat(msg, 3.0);
    EndMessage();
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
     if( damagetype & DMG_BLAST && victim > 0 && victim <= MaxClients && GetEntProp(inflictor, Prop_Data, "m_iHammerID") == 1078682 && GetClientTeam(victim) == 2 )
     {
          damage = damage * 0.1 / 100.0;
          return Plugin_Changed;
     }
     return Plugin_Continue;
}

void PrecacheParticle(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;
    if( table == INVALID_STRING_TABLE )
    {
        table = FindStringTable("ParticleEffectNames");
    }

    if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
    {
        bool save = LockStringTables(false);
        AddToStringTable(table, sEffectName);
        LockStringTables(save);
    }
}

stock bool IsValidClient(int client) 
{
    return ((1 <= client <= MaxClients) && IsClientInGame(client));
}

stock bool IsValidEntRef(int entity)
{
    if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
        return true;
    return false;
}