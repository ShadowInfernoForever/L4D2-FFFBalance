#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define PLUGIN_VERSION "0.2"
#define DEBUG_LOGGING 1  // Set to 1 to enable logging, 0 to disable

#define ZOMBIECLASS_MIN 1
#define ZOMBIECLASS_MAX 7

#define GAMEDATA_FILENAME  "l4d2_infectiongamemode"

#define SOUND_HEARTBEAT     "player/heartbeatloop.wav"

#define MAX_SOUNDS 12

// Cambie KickBot Guarda!
//public Action:KickBot(Handle timer, any:client)

Handle g_hCreateAbility     = INVALID_HANDLE;
Handle g_hGameConf      = INVALID_HANDLE;

int g_oAbility          = 0;
int g_Sprite[MAXPLAYERS+1];

bool g_bRoundRestarted = false;

ConVar   survivor_limit;
bool     isMapActive;


char g_smokerPainSounds[MAX_SOUNDS][] = {
    "npc/infected/action/been_shot/been_shot_01.wav",
    "npc/infected/action/been_shot/been_shot_02.wav",
    "npc/infected/action/been_shot/been_shot_03.wav",
    "npc/infected/action/been_shot/been_shot_04.wav",
    "npc/infected/action/been_shot/been_shot_05.wav",
    "npc/infected/action/been_shot/been_shot_06.wav",
    "npc/infected/action/been_shot/been_shot_07.wav",
    "npc/infected/action/been_shot/been_shot_08.wav",
    "npc/infected/action/been_shot/been_shot_09.wav",
    "npc/infected/action/been_shot/been_shot_12.wav",
    "npc/infected/action/been_shot/been_shot_13.wav",
    "npc/infected/action/been_shot/been_shot_14.wav",
};

ConVar hCvarReloadSpeedUzi;
ConVar hCvarReloadSpeedMp5;
ConVar hCvarReloadSpeedSilencedSmg;
ConVar hCvarReloadSpeedChromeShotgun;
ConVar hCvarReloadSpeedPumpShotgun;
ConVar hCvarReloadSpeedSniperAwp;
ConVar hCvarReloadSpeedSniperScout;

public Plugin myinfo = 
{
    name = "Divergent Epidemic CORE",
    author = "Shadow",
    description = "Alternative Versus where everyone start as survivor and once died will become infected team and vice versa",
    version = PLUGIN_VERSION,
    url = ""
};

// Struct to store dead survivor info
enum struct SurvivorData{
    int steamId;
    bool isDead;
}

ConVar  g_hCvarSlowdown , g_hCvar1Down;

// Plugin Initialization
public void OnPluginStart(){
    Sub_HookGameData(GAMEDATA_FILENAME);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post); // Handle when Survivor death
    HookEvent("defibrillator_used", Event_DefibSuccess, EventHookMode_Post); // Handle when Survivor revive via defib_unit only

    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("survivor_rescued", Event_SurvivorRescuedPre, EventHookMode_Pre);
    HookEvent("survivor_rescued", Event_SurvivorRescuedPost);
    HookEvent("round_start",  Event_RoundStart);
    HookEvent("mission_lost", Event_MissionLost, EventHookMode_Post);

    HookEvent("weapon_reload", OnWeaponReload, EventHookMode_Post);

    survivor_limit = FindConVar("survivor_limit");
    survivor_limit.AddChangeHook(survivor_limitChanged);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }

    g_hCvar1Down = FindConVar("survivor_max_incapacitated_count");
    g_hCvarSlowdown = FindConVar("survivor_limp_health");

    hCvarReloadSpeedUzi = CreateConVar("l4d2_reload_speed_uzi", "3.8", "Reload duration of Uzi (weapon_smg)", FCVAR_CHEAT|FCVAR_NOTIFY, true, 0.0, true, 10.0);
    hCvarReloadSpeedMp5 = CreateConVar("l4d2_reload_speed_mp5", "4.1", "Reload duration of MP5 (weapon_smg_mp5)", FCVAR_CHEAT|FCVAR_NOTIFY, true, 0.0, true, 10.0);
    hCvarReloadSpeedSilencedSmg = CreateConVar("l4d2_reload_speed_silenced_smg", "4.4", "Reload duration of Silenced SMG (weapon_smg_silenced)", FCVAR_CHEAT|FCVAR_NOTIFY, true, 0.0, true, 10.0);

    hCvarReloadSpeedChromeShotgun = CreateConVar("l4d2_reload_speed_chrome", "4.2", "Reload duration of Chrome Shotgun (weapon_shotgun_chrome)", FCVAR_CHEAT|FCVAR_NOTIFY, true, 0.0, true, 10.0);
    hCvarReloadSpeedPumpShotgun = CreateConVar("l4d2_reload_speed_pump", "4.2", "Reload duration of Pump Shotgun (weapon_pumpshotgun)", FCVAR_CHEAT|FCVAR_NOTIFY, true, 0.0, true, 10.0);

    hCvarReloadSpeedSniperAwp = CreateConVar("l4d2_reload_speed_awp", "6", "Reload duration of AWP (weapon_sniper_awp)", FCVAR_CHEAT|FCVAR_NOTIFY, true, 0.0, true, 10.0);
    hCvarReloadSpeedSniperScout = CreateConVar("l4d2_reload_speed_scout", "5", "Reload duration of Scout (weapon_sniper_scout)", FCVAR_CHEAT|FCVAR_NOTIFY, true, 0.0, true, 10.0);

    LogMessage("Plugin Initialized: %s v%s", "[Left 4 Dead 2] Keep playing!!", PLUGIN_VERSION);
}

public void Sub_HookGameData(char[] GameDataFile)
{
    g_hGameConf = LoadGameConfigFile(GameDataFile);

    if (g_hGameConf != INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Static);
        PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CreateAbility");
        PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
        PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hCreateAbility = EndPrepSDKCall();

        if (g_hCreateAbility == INVALID_HANDLE)
            SetFailState("[+] S_HGD: Error: Unable to find CreateAbility signature.");

        g_oAbility = GameConfGetOffset(g_hGameConf, "oAbility");

        CloseHandle(g_hGameConf);
    }

    else
        SetFailState("[+] S_HGD: Error: Unable to load gamedata file, exiting.");
}

void survivor_limitChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (isMapActive && GetHumanCount()) FixBotCount();
}

public void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
    g_bRoundRestarted = true;
}

public Event_RoundStart(Handle:event, String:event_name[], bool:dontBroadcast) {

    g_bRoundRestarted = false;

    CreateTimer(1.0, TimerLeftSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);    

    ResetPlayersToSurvivors();
    
}

Action Event_SurvivorRescuedPre(Event event, const char[] name, bool dontBroadcast)
{
    int UserId = event.GetInt("userid");
    int client = GetClientOfUserId(UserId);
    
    if ( IsClientInGame(client) && (GetClientTeam(client) == 2) && IsPlayerAlive(client))
    {

    SetCustomHealth(client);

    StopHeartBeat(client);
        
    }

    return Plugin_Continue;
}

Action Event_SurvivorRescuedPost(Event event, const char[] name, bool dontBroadcast)
{
    int UserId = event.GetInt("userid");
    int client = GetClientOfUserId(UserId);
    
    if ( IsClientInGame(client) && (GetClientTeam(client) == 2) && IsPlayerAlive(client))
    {

    SetCustomHealth(client);

    StopHeartBeat(client);
        
    }

    return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int UserId = event.GetInt("userid");
    int client = GetClientOfUserId(UserId);
    
    if ( IsClientInGame(client) && (GetClientTeam(client) == 2) && IsPlayerAlive(client))
    {

    CreateTimer(0.5, Timer_SetHealth, client);

    StopHeartBeat(client);
        
    }

    return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage,
                           int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (!IsClientInGame(victim) || !IsClientInGame(attacker))
        return Plugin_Continue;

    // Solo si el atacante es infectado (team 3) y la víctima es superviviente (team 2)
    if (GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2)
    {
        char weaponClassname[64];
        GetEdictClassname(weapon, weaponClassname, sizeof(weaponClassname));

        float scaledDamage = 0.0;

        if (StrEqual(weaponClassname, "weapon_sniper_awp"))
            scaledDamage = 4.0;
        else if (StrEqual(weaponClassname, "weapon_sniper_scout"))
            scaledDamage = 3.0;
        else if (StrEqual(weaponClassname, "weapon_smg"))
            scaledDamage = 1.0;
        else if (StrEqual(weaponClassname, "weapon_smg_mp5"))
            scaledDamage = 1.0;
        else if (StrEqual(weaponClassname, "weapon_smg_silenced"))
            scaledDamage = 1.0;
        else if (StrEqual(weaponClassname, "weapon_pumpshotgun"))
            scaledDamage = 1.0;
        else if (StrEqual(weaponClassname, "weapon_shotgun_chrome"))
            scaledDamage = 1.0;
        else if (StrEqual(weaponClassname, "weapon_pistol"))
            scaledDamage = 1.5;

        if (scaledDamage > 0.0)
        {
            SDKHooks_TakeDamage(victim, attacker, attacker, scaledDamage, DMG_BULLET);

            return Plugin_Handled;  // Cortamos daño normal para aplicar el personalizado
        }
    }

    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnWeaponReload(Event hEvent, const char[] eName, bool dontBroadcast)
{
    int client = GetClientOfUserId(hEvent.GetInt("userid"));

    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
        return;

    if (GetClientTeam(client) != 3)
        return; // Solo infectados

    int weapon = GetPlayerWeaponSlot(client, 0);
    if (weapon == -1) return;

    int weaponId = IdentifyWeapon(weapon);
    float originalReloadDuration = 0.0, alteredReloadDuration = 0.0;

    switch (weaponId)
    {
        case WEPID_SMG:
        {
            originalReloadDuration = 2.235352;
            alteredReloadDuration = hCvarReloadSpeedUzi.FloatValue;
        }
        case WEPID_SMG_MP5:
        {
            originalReloadDuration = 3.0667;
            alteredReloadDuration = hCvarReloadSpeedMp5.FloatValue;
        }
        case WEPID_SMG_SILENCED:
        {
            originalReloadDuration = 2.235291;
            alteredReloadDuration = hCvarReloadSpeedSilencedSmg.FloatValue;
        }
        case WEPID_SHOTGUN_CHROME:
        {
            originalReloadDuration = 4.2;
            alteredReloadDuration = hCvarReloadSpeedChromeShotgun.FloatValue;
        }
        case WEPID_PUMPSHOTGUN:
        {
            originalReloadDuration = 4.2;
            alteredReloadDuration = hCvarReloadSpeedPumpShotgun.FloatValue;
        }
        case WEPID_SNIPER_AWP:
        {
            originalReloadDuration = 3.66;
            alteredReloadDuration = hCvarReloadSpeedSniperAwp.FloatValue;
        }
        case WEPID_SNIPER_SCOUT:
        {
            originalReloadDuration = 2.9;
            alteredReloadDuration = hCvarReloadSpeedSniperScout.FloatValue;
        }
        default: return;
    }

    if (alteredReloadDuration <= 0.0) return;

    float oldNextAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 0);
    float newNextAttack = oldNextAttack - originalReloadDuration + alteredReloadDuration;
    float playbackRate = originalReloadDuration / alteredReloadDuration;

    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", newNextAttack);
    SetEntPropFloat(client, Prop_Send, "m_flNextAttack", newNextAttack);
    SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", playbackRate);
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
    if (!(buttons & IN_ATTACK2))
        return Plugin_Continue;

    if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client))
        return Plugin_Continue;

    float originalReloadDuration = 0.0, alteredReloadDuration = 0.0;

    int weapon = GetPlayerWeaponSlot(client, 0);
    int weaponId = IdentifyWeapon(weapon);

    switch (weaponId)
    {
        case WEPID_SMG:
        {
            originalReloadDuration = 2.235352;
            alteredReloadDuration = hCvarReloadSpeedUzi.FloatValue;
        }
        case WEPID_SMG_MP5:
        {
            originalReloadDuration = 2.2;
            alteredReloadDuration = hCvarReloadSpeedMp5.FloatValue;
        }
        case WEPID_SMG_SILENCED:
        {
            originalReloadDuration = 2.235291;
            alteredReloadDuration = hCvarReloadSpeedSilencedSmg.FloatValue;
        }
        case WEPID_SHOTGUN_CHROME:
        {
            originalReloadDuration = 4.0;
            alteredReloadDuration = hCvarReloadSpeedChromeShotgun.FloatValue;
        }
        case WEPID_PUMPSHOTGUN:
        {
            originalReloadDuration = 4.3;
            alteredReloadDuration = hCvarReloadSpeedPumpShotgun.FloatValue;
        }
        case WEPID_SNIPER_AWP:
        {
            originalReloadDuration = 3.4;
            alteredReloadDuration = hCvarReloadSpeedSniperAwp.FloatValue;
        }
        case WEPID_SNIPER_SCOUT:
        {
            originalReloadDuration = 3.0;
            alteredReloadDuration = hCvarReloadSpeedSniperScout.FloatValue;
        }
        default:
        {
            return Plugin_Continue;
        }
    }

    float playbackRate = originalReloadDuration / alteredReloadDuration;
    SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", playbackRate);

    return Plugin_Continue;
}

// Handles when a survivor successfully revives another
void Event_DefibSuccess(Event event, const char[] name, bool dontBroadcast){
    int client = GetClientOfUserId(event.GetInt("subject"));
    SetCustomHealth(client);
}

// Handles when a survivor dies
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsValidClient(client) || IsFakeClient(client)) return;

    if (g_bRoundRestarted)
        return;

    if (IsValidEntity(g_Sprite[client]))
    {
        AcceptEntityInput(g_Sprite[client], "Kill");
        g_Sprite[client] = -1;
    }

    int team = GetClientTeam(client);

    // Verificar si el jugador era sobreviviente
    if (team == 2) // Si era sobreviviente
    {
        // Verificamos si el jugador ha dejado el área de inicio
        if (LeftStartArea()) 
        {
            // Si ha dejado el área de inicio, lo respawneamos como infectado
            CreateTimer(4.0, Timer_RespawnAsInfected, GetClientUserId(client));
            //CreateTimer(5.0, Timer_KickDeadBots);
        }
        else
        {
            // Si está en la zona de inicio, lo respawneamos como sobreviviente
            CreateTimer(4.0, Timer_RespawnAsHuman, GetClientUserId(client));
            //CreateTimer(5.0, Timer_KickDeadBots);
        }
    }
    else if (team == 3) // Si era infectado
    {
        // No convertir si el jugador es un fantasma
        if (IsGhost(client))
        {
            return;
        }

        CreateTimer(4.0, Timer_RespawnAsHuman, GetClientUserId(client));
        //CreateTimer(5.0, Timer_KickDeadBots);
    }
}

public void OnMapStart(){
    isMapActive = true;
    ResetPlayersToSurvivors();

    for (int i = 0; i < sizeof(g_smokerPainSounds); i++)
    {
        PrecacheSound(g_smokerPainSounds[i], true);
    }
}

public void OnMapEnd()
{
    isMapActive = false;
}

int CreateFollowingSprite(int client, const char[] spritePath)
{
    int sprite = CreateEntityByName("env_sprite");
    if (sprite == -1) return -1;

    DispatchKeyValue(sprite, "model", spritePath);      // Ruta del sprite, ej: "sprites/glow01.vmt"
    DispatchKeyValue(sprite, "rendermode", "5");        // Translucent
    DispatchKeyValue(sprite, "rendercolor", "255 0 0"); // Color rojo (puedes cambiarlo)
    DispatchKeyValue(sprite, "scale", "0.5");            // Tamaño del sprite
    DispatchKeyValue(sprite, "spawnflags", "1");         // Start On (activo)
    DispatchSpawn(sprite);

    // Posición inicial (igual a la del jugador)
    float pos[3];
    GetClientAbsOrigin(client, pos);
    TeleportEntity(sprite, pos, NULL_VECTOR, NULL_VECTOR);

    return sprite;
}

public Action:TimerLeftSafeRoom(Handle:timer) {

    if (LeftStartArea()) 
    { 
        g_hCvar1Down.SetInt(0, true, true);
        g_hCvarSlowdown.SetInt(11, true, true);

        for (int i = 1; i <= MaxClients; i++)
            {
                if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
                {
                    SetCustomHealth(i);
                }
            }
        }
    else
    {
        CreateTimer(1.0, TimerLeftSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);
    }
    
}

public Action Timer_KickDeadBots(Handle timer)
{
    KickUncontrolledDeadSurvivorBots();
    return Plugin_Handled;
}

public Action Timer_UpdateSpritePosition(Handle timer, any data)
{
    int client = data & 0xFFFF;
    int sprite = (data >> 16) & 0xFFFF;

    if (!IsValidClient(client) || !IsValidEntity(sprite))
    {
        return Plugin_Stop;
    }

    float pos[3];
    GetClientAbsOrigin(client, pos);

    // Ajusta la altura si querés que el sprite esté un poco arriba del jugador
    pos[2] += 70.0;

    TeleportEntity(sprite, pos, NULL_VECTOR, NULL_VECTOR);

    return Plugin_Continue;
}

public Action Timer_RespawnAsInfected(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client)) return Plugin_Stop;

    L4D_RespawnPlayer(client);
    SetupClientLoadout(client);

    RespawnAtRandomInfectedNavArea(client);

    return Plugin_Stop;
}

public Action Timer_RespawnAsHuman(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client)) return Plugin_Stop;

    ChangeClientTeam(client, 2);
    SetGhostState(client, false); // El jugador deja de ser un fantasma
    RespawnAtRandomHumanPlayer(client);
    SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
    // Colors and aura
    SetEntityRenderMode(client, RENDER_NORMAL);
    SetEntityRenderFx(client, RENDERFX_NONE);
    SetEntityRenderColor(client, 255, 255, 255, 255);


    SetupClientLoadout(client);

    return Plugin_Stop;
}

public Action Timer_TeleportToRandomInfectedNavArea(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;

    g_Sprite[client] = CreateFollowingSprite(client, "vgui/crouch_infected.vmt");

    if (g_Sprite[client] != -1)
    {
        CreateTimer(0.03, Timer_UpdateSpritePosition, (client & 0xFFFF) | (g_Sprite[client] << 16));
    }

   SetEntProp(client, Prop_Data, "m_iTeamNum", 3);
   SetEntProp(client, Prop_Send, "m_ArmorValue", 1245);
   SetEntProp(client, Prop_Send, "m_zombieClass", 3);
   SetEntityRenderMode(client, RENDER_GLOW);
   SetEntityRenderColor(client, 255, 0, 0, 100); 

   //int cAbility = GetEntPropEnt(client, Prop_Send, "m_customAbility");
        //if (cAbility > 0) AcceptEntityInput(cAbility, "Kill");

   //SetEntProp(client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, client), g_oAbility));

    // Definir variables para la posición
    int randomZombieClass = GetRandomInt(ZOMBIECLASS_MIN, ZOMBIECLASS_MAX);
    float vPos[3];
    
    // Intenta obtener una posición aleatoria válida en una zona de navegación
    if (L4D_GetRandomPZSpawnPosition(L4D_GetHighestFlowSurvivor(), randomZombieClass, 5, vPos))
    {
        // Si obtenemos una posición válida, teletransportamos al cliente
        vPos[2] += 10.0; // Para evitar el atasco en el suelo (ajustar la altura según sea necesario)
        TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
    }
    else
    {
        // Si no se pudo obtener una posición válida, usamos una alternativa
        float safePos[3] = {100.0, 100.0, 100.0}; // Posición predeterminada si no se puede obtener una válida
        TeleportEntity(client, safePos, NULL_VECTOR, NULL_VECTOR);
    }

    return Plugin_Stop;
}

public Action Timer_TeleportToRandomSurvivorPlayer(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;

    int players[MAXPLAYERS+1];
    int count = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == client) continue;
        if (!IsClientInGame(i)) continue;
        if (!IsPlayerAlive(i)) continue;
        if (GetClientTeam(i) != 2) continue; // Verifica si el jugador está en el equipo de supervivientes (TEAM_SURVIVOR)

        players[count++] = i;
    }

    if (count == 0)
    {
        float safePos[3] = {100.0, 100.0, 100.0}; // Alternativa si no hay jugadores supervivientes válidos
        TeleportEntity(client, safePos, NULL_VECTOR, NULL_VECTOR);
    }
    else
    {
        int target = players[GetRandomInt(0, count - 1)];
        float pos[3];
        GetClientAbsOrigin(target, pos);
        pos[2] += 10.0; // Para evitar atasco en el suelo
        TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
    }

    return Plugin_Stop;
}

public Action Timer_TakeOverBot(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    L4D_TakeOverBot(client);
    return Plugin_Stop;
}

public Action Timer_SetHealth(Handle timer, any client)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
    {
        SetCustomHealth(client);
    }
    return Plugin_Stop;
}

public Action kickbot(Handle:timer, any client)
{
    if (IsClientInGame(client) && (!IsClientInKickQueue(client)))
    {
        if (IsFakeClient(client)) KickClient(client);
    }
    return Plugin_Stop;
}

public void ResetPlayers(Event event, const char[] szName, bool dontBroadcast)
{
    // Reset all players to survivors at the start of a new round
    ResetPlayersToSurvivors();
}

public void KickUncontrolledDeadSurvivorBots()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;

        // Solo bots sobrevivientes
        if (IsFakeClient(i) && GetClientTeam(i) == 2)
        {
            bool isAlive = IsPlayerAlive(i);
            int owner = GetEntPropEnt(i, Prop_Send, "m_humanSpectatorUserID");

            // Está muerto y no tiene dueño
            if (!isAlive && owner == -1)
            {
                char name[64];
                GetClientName(i, name, sizeof(name));
                KickClient(i, "Bot muerto sin dueño");
            }
        }
    }
}

// "m_ghostSpawnState" --- "0" == enabled; "1" == disabled "2" == waiting to leave saferoom
// Ghost Mode
void SetGhostState(int client, bool isGhostBool) {
    if (!IsValidClient(client)) return;
    if (isGhostBool) {
        SetEntProp(client, Prop_Send, "m_isGhost", 1);
    } else {
        SetEntProp(client, Prop_Send, "m_isGhost", 0);
    }
}

// Sets random zombie class
// Not Really Used, maybe in the future
/*
void SetZombieClass(int client, int zombieClass) {
    if (!IsValidClient(client)) return;

    // Asignamos la clase de zombie al cliente
    SetEntProp(client, Prop_Send, "m_zombieClass", zombieClass);
} */

void RespawnAtRandomInfectedNavArea(int client)
{
    if (!IsValidClient(client)) return;

    // Esperamos un frame para moverlo después de que revive correctamente
    CreateTimer(0.2, Timer_TeleportToRandomInfectedNavArea, GetClientUserId(client));
}

void RespawnAtRandomHumanPlayer(int client)
{
    if (!IsValidClient(client)) return;

    // Revive primero
    L4D_RespawnPlayer(client);

    // Esperamos un frame para moverlo después de que revive correctamente
    CreateTimer(0.1, Timer_TeleportToRandomSurvivorPlayer, GetClientUserId(client));
}

void ResetPlayersToSurvivors()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            FixBotCount();
            ChangeClientTeam(i, 2);
            SetGhostState(i, false);
            CreateTimer(1.5, Timer_TakeOverBot, GetClientUserId(i));
            SetEntProp(i, Prop_Send, "m_ArmorValue", 0);
            SetEntityRenderMode(i, RENDER_NORMAL); // Quita el modo de brillo
            SetEntityRenderColor(i, 255, 255, 255, 255); // Color original

                if (IsValidEntity(g_Sprite[i]))
                {
                    AcceptEntityInput(g_Sprite[i], "Kill");
                    g_Sprite[i] = -1;
                }
        }
    }
}

void OnFrame_KickBot(int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0) KickClient(client);
}

void SetupClientLoadout(int client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return;

    // Armas principales
    static const char weapons[][] = {
        "weapon_smg",
        "weapon_smg_mp5",
        "weapon_smg_silenced",
        "weapon_shotgun_chrome",
        "weapon_pumpshotgun",
        "weapon_sniper_awp",
        "weapon_sniper_scout"
    };

    int weaponCount = sizeof(weapons);
    int weaponIndex = GetRandomInt(0, weaponCount - 1);
    GivePlayerItem(client, weapons[weaponIndex]);

    // Ítems de soporte (cura o utilidad)
    static const char supportItems[][] = {
        "", // Give Nothing! yay
        "weapon_first_aid_kit",
        "weapon_defibrillator",
        "weapon_pain_pills",
        "weapon_adrenaline"
    };

    int supportCount = sizeof(supportItems);
    int supportIndex = GetRandomInt(0, supportCount - 1);

    if (!StrEqual(supportItems[supportIndex], ""))
    {
        GivePlayerItem(client, supportItems[supportIndex]);
    }
}

void SetCustomHealth(int client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    if (GetClientTeam(client) != 2)
    return;

    int newHealth = 45;

    SetEntityHealth(client, newHealth);
    SetEntProp(client, Prop_Send, "m_iMaxHealth", newHealth);
    SetEntProp(client, Prop_Send, "m_iHealth", newHealth);
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
    SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
}

void StopHeartBeat(int client) {

    StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
    StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
    StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
    StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
}

stock QuickCheat(client, String:command[], String:arguments[] = "")
{
    new userFlags = GetUserFlagBits(client);
    SetUserFlagBits(client, ADMFLAG_ROOT);
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
    SetUserFlagBits(client, userFlags);
}

stock GetAnyClient() 
{ 
    for (new target = 1; target <= MaxClients; target++) 
    { 
        if (IsClientInGame(target)) return target; 
    } 
    return -1; 
} 

stock void FixBotCount()
{
    int survivor_count = 0;
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && GetClientTeam(client) == 2)
        {
            survivor_count++;
        }
    }
    int limit = GetConVarInt(survivor_limit);
    if (survivor_count < limit)
    {
        int bot;
        for (; survivor_count < limit; survivor_count++)
        {
            bot = CreateFakeClient("k9Q6CK42");
            if (bot != 0)
            {
                ChangeClientTeam(bot, view_as<int>(2));
                RequestFrame(OnFrame_KickBot, GetClientUserId(bot));
            }
        }
    }
    else if (survivor_count > limit)
    {
        for (int client = 1; client <= MaxClients && survivor_count > limit; client++)
        {
            if (IsClientInGame(client) && GetClientTeam(client) == 2)
            {
                if (IsFakeClient(client))
                {
                    survivor_count--;
                    KickClient(client);
                }
            }
        }
    }
}

stock int GetHumanCount()
{
    int humans = 0;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientConnected(client) && !IsFakeClient(client))
        {
            humans++;
        }
    }

    return humans;
}


stock bool:LeftStartArea() {

    new maxents = GetMaxEntities();
    
    for (new i = MaxClients + 1; i <= maxents; i++)
    {
        if (IsValidEntity(i))
        {
            decl String:netclass[64];
            
            GetEntityNetClass(i, netclass, sizeof(netclass));
            
            if (StrEqual(netclass, "CTerrorPlayerResource"))
            {
                if (GetEntProp(i, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
                {
                    return true;
                }
            }
        }
    }
    
    return false;
}

bool IsGhost(int client) {
    return GetEntProp(client, Prop_Send, "m_isGhost") == 1;
}

bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}