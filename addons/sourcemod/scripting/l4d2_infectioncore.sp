#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "0.2"
#define DEBUG_LOGGING 1  // Set to 1 to enable logging, 0 to disable

#define ZOMBIECLASS_MIN 1
#define ZOMBIECLASS_MAX 7

#define GAMEDATA_FILENAME  "l4d2_infectiongamemode"

#define SOUND_HEARTBEAT     "player/heartbeatloop.wav"

// Cambie KickBot Guarda!
//public Action:KickBot(Handle timer, any:client)


Handle g_hCreateAbility     = INVALID_HANDLE;
Handle g_hGameConf      = INVALID_HANDLE;

int g_oAbility          = 0;

bool g_bRoundRestarted = false;

ConVar   survivor_limit;
bool     isMapActive;

public Plugin myinfo = 
{
    name = "Infection CORE",
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

    survivor_limit = FindConVar("survivor_limit");
    survivor_limit.AddChangeHook(survivor_limitChanged);

    L4D_ForceVersusStart();

    g_hCvar1Down = FindConVar("survivor_max_incapacitated_count");
    g_hCvarSlowdown = FindConVar("survivor_limp_health");

    LogMessage("Plugin Initialized: %s v%s", "[Left 4 Dead 2] Keep playing!!", PLUGIN_VERSION);
}

void survivor_limitChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (isMapActive && GetHumanCount()) FixBotCount();
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

    int team = GetClientTeam(client);

    // Verificar si el jugador era sobreviviente
    if (team == 2) // Si era sobreviviente
    {
        // Verificamos si el jugador ha dejado el área de inicio
        if (LeftStartArea()) 
        {
            // Si ha dejado el área de inicio, lo respawneamos como infectado
            CreateTimer(4.0, Timer_RespawnAsInfected, GetClientUserId(client));
            CreateTimer(5.0, Timer_KickDeadBots);
        }
        else
        {
            // Si está en la zona de inicio, lo respawneamos como sobreviviente
            CreateTimer(4.0, Timer_RespawnAsHuman, GetClientUserId(client));
            CreateTimer(5.0, Timer_KickDeadBots);
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
        CreateTimer(5.0, Timer_KickDeadBots);
    }
}

public void OnMapStart(){
    isMapActive = true;
    ResetPlayersToSurvivors();
}

public void OnMapEnd()
{
    isMapActive = false;
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

public Action Timer_RespawnAsInfected(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client)) return Plugin_Stop;

    ChangeClientTeam(client, 3);
    RespawnAtRandomInfectedNavArea(client);

    new anyclient = GetAnyClient();
    new bool:temp = false;
    if (anyclient == -1)
    {
        
        // we create a fake client
        anyclient = CreateFakeClient("Bot");
        temp = true;
    }

    // Random Zombie Spawn Yay!
    SpawnRandomZombie(client);

    if (temp) CreateTimer(0.1, kickbot, anyclient);

    // Activar modo fantasma
    //SetGhostState(client, true);

    int cAbility = GetEntPropEnt(client, Prop_Send, "m_customAbility");
        if (cAbility > 0) AcceptEntityInput(cAbility, "Kill");

    SetEntProp(client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, client), g_oAbility));

    return Plugin_Stop;
}

public Action Timer_RespawnAsHuman(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client)) return Plugin_Stop;

    ChangeClientTeam(client, 2);
    SetGhostState(client, false); // El jugador deja de ser un fantasma
    RespawnAtRandomHumanPlayer(client);

    SetupClientLoadout(client);

    return Plugin_Stop;
}

public Action Timer_TeleportToRandomInfectedNavArea(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;

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

void SpawnRandomZombie(int client)
{
    int randomZombieClass = GetRandomInt(ZOMBIECLASS_MIN, ZOMBIECLASS_MAX);  // Obtiene un zombie aleatorio
    float vPos[3];  // Variable para almacenar la posición del spawn

    SetGhostState(client, true);

    // Primero buscamos al sobreviviente con el mayor flujo
    int highestFlowSurvivor = L4D_GetHighestFlowSurvivor();
    if (IsValidClient(highestFlowSurvivor))
    {
        // Intentamos obtener una posición adecuada para el spawn basada en el sobreviviente
        if (L4D_GetRandomPZSpawnPosition(highestFlowSurvivor, randomZombieClass, 5, vPos))
        {
            // Ahora spawnamos el zombie en la posición obtenida
            if (randomZombieClass == 1)  // Smoker
                L4D2_SpawnSpecial(randomZombieClass, vPos, NULL_VECTOR);
            else if (randomZombieClass == 2)  // Boomer
                L4D2_SpawnSpecial(randomZombieClass, vPos, NULL_VECTOR);
            else if (randomZombieClass == 3)  // Hunter
                L4D2_SpawnSpecial(randomZombieClass, vPos, NULL_VECTOR);
            else if (randomZombieClass == 4)  // Spitter
                L4D2_SpawnSpecial(randomZombieClass, vPos, NULL_VECTOR);
            else if (randomZombieClass == 5)  // Jockey
                L4D2_SpawnSpecial(randomZombieClass, vPos, NULL_VECTOR);
            else if (randomZombieClass == 6)  // Charger
                L4D2_SpawnSpecial(randomZombieClass, vPos, NULL_VECTOR);
        }
        else
        {
            PrintToServer("No se encontró una posición adecuada para el zombie desde el sobreviviente.");
        }
    }
    else
    {
        PrintToServer("No se pudo encontrar al sobreviviente con el mayor flujo.");
    }

    // Si no fue posible obtener la posición desde el sobreviviente, buscamos usando el cliente
    if (!IsValidClient(highestFlowSurvivor) || !L4D_GetRandomPZSpawnPosition(highestFlowSurvivor, randomZombieClass, 5, vPos))
    {
        // Intentamos obtener una posición adecuada para el spawn basada en el cliente
        if (IsValidClient(client) && !IsFakeClient(client))
        {
            // Intentamos obtener una posición adecuada para el spawn basada en el cliente
            if (L4D_GetRandomPZSpawnPosition(client, randomZombieClass, 5, vPos))
            {
                // Ahora spawnamos el zombie en la posición obtenida
                if (randomZombieClass == 1)  // Smoker
                    L4D2_SpawnSpecial(randomZombieClass, vPos, NULL_VECTOR);
                else if (randomZombieClass == 2)  // Boomer
                    L4D2_SpawnSpecial(randomZombieClass, vPos, NULL_VECTOR);
                else if (randomZombieClass == 3)  // Hunter
                    L4D2_SpawnSpecial(randomZombieClass, vPos, NULL_VECTOR);
                else if (randomZombieClass == 4)  // Spitter
                    L4D2_SpawnSpecial(randomZombieClass, vPos, NULL_VECTOR);
                else if (randomZombieClass == 5)  // Jockey
                    L4D2_SpawnSpecial(randomZombieClass, vPos, NULL_VECTOR);
                else if (randomZombieClass == 6)  // Charger
                    L4D2_SpawnSpecial(randomZombieClass, vPos, NULL_VECTOR);
            }
            else
            {
                PrintToServer("No se encontró una posición adecuada para el zombie desde el cliente.");
            }
        }
        else
        {
            PrintToServer("El cliente no es válido o es un cliente falso.");
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

    // Revive primero
    L4D_RespawnPlayer(client);

    // Esperamos un frame para moverlo después de que revive correctamente
    CreateTimer(0.1, Timer_TeleportToRandomInfectedNavArea, GetClientUserId(client));
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
            CreateTimer(1.0, Timer_TakeOverBot, GetClientUserId(i));
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