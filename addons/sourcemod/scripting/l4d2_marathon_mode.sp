#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <sdkhooks>

#define CVAR_FLAGS                   FCVAR_NOTIFY|FCVAR_DONTRECORD
#define CVAR_FLAGS_PLUGIN_VERSION    FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY
#define PLUGIN_VERSION              "1.2.1"
#define FILE_NAME                   "l4d2_mix_map"
#define PREFIX                      "[Marathon Mode]"
#define MAXWEAPONNAME               64
#define MAX_HEALTH                  100
#define MAX_TEMP_HEALTH            100
#define RESCUE_HEALTH              50

Address g_pDirector;
Handle g_hSDK_CDirector_IsFirstMapInScenario;

enum struct CampaignInfo {
    char firstMap[64];
    char finaleMap[64];
    char name[64];
}

enum struct PlayerStats {
    int health;
    float tempHealth;
    char primaryWeapon[MAXWEAPONNAME];
    int primaryAmmo;      // Reserve ammo for primary weapon
    int primaryClip;      // Main clip ammo for primary weapon
    char secondaryWeapon[MAXWEAPONNAME];
    char throwable[MAXWEAPONNAME];
    char healSlot[MAXWEAPONNAME];
    char pillsSlot[MAXWEAPONNAME];
    bool hasStats;
}

static const CampaignInfo g_Campaigns[] = {
    {"c1m1_hotel", "c1m4_atrium", "Dead Center"},
    {"c2m1_highway", "c2m5_concert", "Dark Carnival"},
    {"c3m1_plankcountry", "c3m4_plantation", "Swamp Fever"},
    {"c4m1_milltown_a", "c4m5_milltown_escape", "Hard Rain"},
    {"c5m1_waterfront", "c5m5_bridge", "The Parish"},
    {"c6m1_riverbank", "c6m3_port", "The Passing"},
    {"c7m1_docks", "c7m3_port", "The Sacrifice"},
    {"c8m1_apartment", "c8m5_rooftop", "No Mercy"},
    {"c9m1_alleys", "c9m2_lots", "Crash Course"},
    {"c10m1_caves", "c10m5_houseboat", "Death Toll"},
    {"c11m1_greenhouse", "c11m5_runway", "Dead Air"},
    {"c12m1_hilltop", "c12m5_cornfield", "Blood Harvest"},
    {"c13m1_alpinecreek", "c13m4_cutthroatcreek", "Cold Stream"},
    {"c14m1_junkyard", "c14m2_lighthouse", "The Last Stand"}
};

char
    g_sValidLandMarkName[128];

bool
    g_bInited,
    g_bEnable,
    g_bStart,
    g_bSpawn,
    g_bIsValid,
    g_bFirstMap,
    g_bIsFinaleMap,
    g_bShouldRestoreStats;

PlayerStats g_PlayerStats[MAXPLAYERS + 1];

ConVar
    g_hCvar_Enable,
    g_hCvar_TransitionTime,
    g_hCvar_FinaleTime,
    g_hCvar_FinaleCamera;

StringMap
    g_mMapLandMarkSet,
    g_mMapSet;

StringMapSnapshot
    g_msMapLandMarkSet,
    g_msMapSet;

// Add this function to check if we're in an active marathon
static bool IsInMarathon()
{
    // We're in a marathon if we have stats to restore
    // or if players have active stats
    if (g_bShouldRestoreStats)
        return true;
        
    // Check if any players have active stats
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && g_PlayerStats[i].hasStats)
            return true;
    }
    
    return false;
}

public Plugin myinfo =
{
    name = "Marathon Mode",
    author = "Yuzumi, Modified by Mezo123451A",
    description = "Sequential campaign progression with stats saving",
    version = PLUGIN_VERSION,
    url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if(engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

static void InitGameData()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", FILE_NAME);
    if(!FileExists(sPath))
    {
        SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);
    }

    GameData hGameData = new GameData(FILE_NAME);
    if(!hGameData)
    {
        SetFailState("Failed to load \"%s.txt\" gamedata.", FILE_NAME);
    }

    g_pDirector = hGameData.GetAddress("CDirector");
    if(!g_pDirector)
    {
        SetFailState("Failed to find address: \"CDirector\"");
    }

    StartPrepSDKCall(SDKCall_Raw);
    if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsFirstMapInScenario"))
    {
        SetFailState("Failed to find signature: \"CDirector::IsFirstMapInScenario\"");
    }
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
    g_hSDK_CDirector_IsFirstMapInScenario = EndPrepSDKCall();
    if(!g_hSDK_CDirector_IsFirstMapInScenario)
    {
        SetFailState("Failed to create SDKCall: \"CDirector::IsFirstMapInScenario\"");
    }

    delete hGameData;
}

public void OnPluginStart()
{
    g_mMapLandMarkSet = new StringMap();
    g_mMapSet = new StringMap();
    LoadKvFile();

    InitGameData();

    CreateConVar("l4d2_marathon_version", PLUGIN_VERSION, "Marathon Mode version.", CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enable = CreateConVar("l4d2_marathon_enable", "1", "Enable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_TransitionTime = CreateConVar("l4d2_marathon_transition_time", "4.0", "Time to wait before normal map transition", CVAR_FLAGS, true, 0.1);
    g_hCvar_FinaleTime = CreateConVar("l4d2_marathon_finale_time", "3.0", "Time to wait after finale before transition", CVAR_FLAGS, true, 0.1);

    InitFinaleCamera();
    g_hCvar_Enable.AddChangeHook(CvarChange);
    RegAdminCmd("sm_marathon_reload", Command_Reload, ADMFLAG_ROOT, "Reload map config");

    HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving, EventHookMode_Pre);
    HookEvent("finale_win", Event_FinaleWin, EventHookMode_Pre);
    HookEvent("mission_lost", Event_MissionLost, EventHookMode_Pre);
    HookEvent("map_transition", Event_MapTransition, EventHookMode_Pre);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("survivor_rescued", Event_PlayerRevived);
    HookEvent("defibrillator_used", Event_PlayerRevived);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            OnClientPutInServer(i);
        }
    }

    Init();
    AutoExecConfig(true, "l4d2_marathon");
}

// Single event handler for rescue room and defib
public void Event_PlayerRevived(Event event, const char[] name, bool dontBroadcast)
{
    int client;
    
    // Get the correct client based on the event type
    if (StrEqual(name, "survivor_rescued"))
        client = GetClientOfUserId(event.GetInt("victim"));
    else if (StrEqual(name, "defibrillator_used"))
        client = GetClientOfUserId(event.GetInt("subject"));
    
    if (client > 0 && IsClientInGame(client))
    {
        g_PlayerStats[client].hasStats = false;  // Remove saved stats
        
        // Use a timer to ensure we override any default game behavior
        DataPack dp = new DataPack();
        dp.WriteCell(GetClientUserId(client));
        CreateTimer(0.1, Timer_ResetRevivedPlayer, dp, TIMER_DATA_HNDL_CLOSE);
        
        PrintToServer("%s Clearing saved stats for revived/rescued player %N", PREFIX, client);
    }
}

public Action Timer_ResetRevivedPlayer(Handle timer, DataPack dp)
{
    dp.Reset();
    int client = GetClientOfUserId(dp.ReadCell());
    
    if (client <= 0 || !IsClientInGame(client)) 
        return Plugin_Stop;
        
    // Set health to 50 (no temp health)
    SetEntityHealth(client, RESCUE_HEALTH);
    SetTempHealth(client, 0.0);
    
    // Remove all items
    for (int slot = 0; slot <= 4; slot++)
    {
        int weapon = GetPlayerWeaponSlot(client, slot);
        if (weapon != -1)
        {
            RemovePlayerItem(client, weapon);
            AcceptEntityInput(weapon, "Kill");
        }
    }
    
    // Give only a pistol
    GivePlayerItem(client, "weapon_pistol");
    
    PrintToServer("%s Reset loadout for player %N with 50 HP and pistol", PREFIX, client);
    return Plugin_Stop;
}

// Modify RestorePlayerStats to check for these conditions
static void RestorePlayerStats(int client)
{
    // Don't restore stats if player was rescued or defibbed
    if (!g_PlayerStats[client].hasStats) 
    {
        PrintToServer("%s Not restoring stats for player %N (rescued/defibbed)", PREFIX, client);
        return;
    }
    
    // Validate stored health values before restoration
    if (g_PlayerStats[client].health <= 0) g_PlayerStats[client].health = MAX_HEALTH;
    if (g_PlayerStats[client].health > MAX_HEALTH) g_PlayerStats[client].health = MAX_HEALTH;
    if (g_PlayerStats[client].tempHealth > MAX_TEMP_HEALTH) g_PlayerStats[client].tempHealth = float(MAX_TEMP_HEALTH);
    
    CreateTimer(0.5, Timer_DelayedRestore, client);
}

static void InitFinaleCamera()
{
    g_hCvar_FinaleCamera = FindConVar("director_no_finale_camera");
    if (g_hCvar_FinaleCamera == null)
    {
        LogError("Failed to find convar: director_no_finale_camera");
    }
}

static void Init()
{
    g_bInited = true;
    g_bEnable = g_hCvar_Enable.BoolValue;
    g_bStart = false;    g_bSpawn = false;
    g_bIsValid = false;
    g_bFirstMap = false;
    g_bShouldRestoreStats = false;

    for (int i = 1; i <= MaxClients; i++)
    {
        g_PlayerStats[i].hasStats = false;
    }
}

static bool IsValidMeleeWeapon(const char[] meleeScript)
{
    static const char validMeleeTypes[][] = {
        "baseball_bat",
        "cricket_bat",
        "crowbar",
        "electric_guitar",
        "fireaxe",
        "frying_pan",
        "golfclub",
        "katana",
        "knife",
        "machete",
        "tonfa",
        "pitchfork",
        "shovel"
    };
    
    for (int i = 0; i < sizeof(validMeleeTypes); i++)
    {
        if (StrEqual(meleeScript, validMeleeTypes[i], false))
        {
            return true;
        }
    }
    return false;
}

static void ResetPlayerStats(int client)
{
    g_PlayerStats[client].hasStats = false;
    g_PlayerStats[client].health = MAX_HEALTH;
    g_PlayerStats[client].tempHealth = 0.0;
    g_PlayerStats[client].primaryWeapon[0] = '\0';
    g_PlayerStats[client].primaryAmmo = 0;
    g_PlayerStats[client].primaryClip = 0;
    g_PlayerStats[client].secondaryWeapon[0] = '\0';
    g_PlayerStats[client].throwable[0] = '\0';
    g_PlayerStats[client].healSlot[0] = '\0';
    g_PlayerStats[client].pillsSlot[0] = '\0';
    PrintToChat(client, "\x04%s \x01Welcome! Starting fresh with default loadout.", PREFIX);
}

static void ResetAllPlayerStats()
{
    g_bShouldRestoreStats = false;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            ResetPlayerStats(i);
        }
    }
    PrintToChatAll("\x04%s \x01Stats have been reset for a fresh start!", PREFIX);
}

static float GetTempHealth(int client)
{
    float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    float fHealthTime = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
    float fDuration = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
    float fTemp = fHealth - (fHealthTime * fDuration);
    return fTemp > 0.0 ? (fTemp > MAX_TEMP_HEALTH ? float(MAX_TEMP_HEALTH) : fTemp) : 0.0;
}

static void SetTempHealth(int client, float fHealth)
{
    if (fHealth < 0.0) fHealth = 0.0;
    if (fHealth > MAX_TEMP_HEALTH) fHealth = float(MAX_TEMP_HEALTH);
    
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth);
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

static int GetClientAmmo(int client, int weapon)
{
    int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if (ammoType == -1) return -1;
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
}

static void GetClientWeaponName(int client, int slot, char[] buffer, int maxlen)
{
    int weapon = GetPlayerWeaponSlot(client, slot);
    if (weapon != -1)
    {
        GetEdictClassname(weapon, buffer, maxlen);
    }
    else
    {
        buffer[0] = '\0';
    }
}

static bool FindMapEntity()
{
    int CId = -1, LId = -1;
    char LandMarkName[128], BindName[128];
    bool HasChangeLevel = true;

    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    g_bIsFinaleMap = IsFinaleMap(currentMap);

    if ((CId = FindEntityByClassname(CId, "info_changelevel")) == INVALID_ENT_REFERENCE)
    {
        HasChangeLevel = false;
    }
    else
    {
        GetEntPropString(CId, Prop_Data, "m_landmarkName", BindName, sizeof(BindName));
        if (BindName[0] == '\0')
        {
            HasChangeLevel = false;
        }
    }

    if (!HasChangeLevel && g_bIsFinaleMap)
    {
        int entity = CreateEntityByName("info_changelevel");
        if (entity != -1)
        {
            DispatchSpawn(entity);
            HasChangeLevel = true;
            
            entity = CreateEntityByName("info_landmark");
            if (entity != -1)
            {
                DispatchSpawn(entity);
                SetEntPropString(entity, Prop_Data, "m_iName", "marathon_transition_landmark");
                strcopy(BindName, sizeof(BindName), "marathon_transition_landmark");
            }
        }
    }

    while ((LId = FindEntityByClassname(LId, "info_landmark")) != INVALID_ENT_REFERENCE)
    {
        GetEntPropString(LId, Prop_Data, "m_iName", LandMarkName, sizeof(LandMarkName));
        if (StrEqual(LandMarkName, BindName, false))
        {
            return true;
        }
        else
        {
            if (!g_bFirstMap)
            {
                Format(g_sValidLandMarkName, sizeof(g_sValidLandMarkName), "%s", LandMarkName);
            }
        }
    }

    return HasChangeLevel;
}

static void SavePlayerStats()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            // Validate health values when saving
            int currentHealth = GetClientHealth(i);
            if (currentHealth <= 0) currentHealth = MAX_HEALTH;
            if (currentHealth > MAX_HEALTH) currentHealth = MAX_HEALTH;
            g_PlayerStats[i].health = currentHealth;

            float currentTempHealth = GetTempHealth(i);
            if (currentTempHealth > MAX_TEMP_HEALTH) currentTempHealth = float(MAX_TEMP_HEALTH);
            g_PlayerStats[i].tempHealth = currentTempHealth;

            // Save primary weapon and its ammo
            int weapon = GetPlayerWeaponSlot(i, 0);
            char weaponName[MAXWEAPONNAME];
            if (weapon != -1)
            {
                GetEdictClassname(weapon, weaponName, sizeof(weaponName));
                strcopy(g_PlayerStats[i].primaryWeapon, MAXWEAPONNAME, weaponName);
                g_PlayerStats[i].primaryClip = GetEntProp(weapon, Prop_Send, "m_iClip1");
                g_PlayerStats[i].primaryAmmo = GetClientAmmo(i, weapon);
                
                PrintToServer("%s Saved primary weapon %s with clip: %d, reserve: %d for player %N", 
                    PREFIX, 
                    g_PlayerStats[i].primaryWeapon, 
                    g_PlayerStats[i].primaryClip, 
                    g_PlayerStats[i].primaryAmmo,
                    i);
            }
            else
            {
                g_PlayerStats[i].primaryWeapon[0] = '\0';
                g_PlayerStats[i].primaryClip = 0;
                g_PlayerStats[i].primaryAmmo = 0;
            }

            // Save secondary weapon (including melee)
            weapon = GetPlayerWeaponSlot(i, 1);
            if (weapon != -1)
            {
                GetEdictClassname(weapon, weaponName, sizeof(weaponName));
                
                // For melee weapons, save the specific type
                if (StrEqual(weaponName, "weapon_melee"))
                {
                    char meleeName[64];
                    GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", meleeName, sizeof(meleeName));
                    
                    // Debug print
                    PrintToServer("%s Raw melee name: %s for player %N", PREFIX, meleeName, i);
                    
                    // Remove the "scripts/melee/" prefix if present
                    ReplaceString(meleeName, sizeof(meleeName), "scripts/melee/", "");
                    
                    // Validate the melee weapon type
                    if (IsValidMeleeWeapon(meleeName))
                    {
                        // Store just the melee type name with prefix for identification
                        Format(g_PlayerStats[i].secondaryWeapon, MAXWEAPONNAME, "melee_%s", meleeName);
                        PrintToServer("%s Saved valid melee weapon: %s for player %N", PREFIX, g_PlayerStats[i].secondaryWeapon, i);
                    }
                    else
                    {
                        PrintToServer("%s Invalid melee weapon type: %s for player %N", PREFIX, meleeName, i);
                        g_PlayerStats[i].secondaryWeapon[0] = '\0';
                    }
                }
                else
                {
                    strcopy(g_PlayerStats[i].secondaryWeapon, MAXWEAPONNAME, weaponName);
                    PrintToServer("%s Saved secondary weapon: %s for player %N", PREFIX, g_PlayerStats[i].secondaryWeapon, i);
                }
            }
            else
            {
                g_PlayerStats[i].secondaryWeapon[0] = '\0';
            }

            GetClientWeaponName(i, 2, g_PlayerStats[i].throwable, MAXWEAPONNAME);
            GetClientWeaponName(i, 3, g_PlayerStats[i].healSlot, MAXWEAPONNAME);
            GetClientWeaponName(i, 4, g_PlayerStats[i].pillsSlot, MAXWEAPONNAME);

            g_PlayerStats[i].hasStats = true;
            PrintToServer("%s Saved stats for player %N", PREFIX, i);
        }
    }
    g_bShouldRestoreStats = true;
}

public Action Timer_DelayedRestore(Handle timer, any client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Stop;

    // Set main health with validation
    int healthToSet = g_PlayerStats[client].health;
    if (healthToSet <= 0) healthToSet = MAX_HEALTH;
    if (healthToSet > MAX_HEALTH) healthToSet = MAX_HEALTH;
    SetEntityHealth(client, healthToSet);

    // Set temp health with validation
    float tempHealthToSet = g_PlayerStats[client].tempHealth;
    if (tempHealthToSet < 0.0) tempHealthToSet = 0.0;
    if (tempHealthToSet > MAX_TEMP_HEALTH) tempHealthToSet = float(MAX_TEMP_HEALTH);
    SetTempHealth(client, tempHealthToSet);

    // Clear existing weapons
    for (int slot = 0; slot <= 4; slot++)
    {
        int weapon = GetPlayerWeaponSlot(client, slot);
        if (weapon != -1)
        {
            RemovePlayerItem(client, weapon);
            AcceptEntityInput(weapon, "Kill");
        }
    }

    // Restore primary weapon with ammo
    if (g_PlayerStats[client].primaryWeapon[0] != '\0')
    {
        int weapon = GivePlayerItem(client, g_PlayerStats[client].primaryWeapon);
        if (weapon != -1)
        {
            SetEntProp(weapon, Prop_Send, "m_iClip1", g_PlayerStats[client].primaryClip);
            
            int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
            if (ammoType != -1)
            {
                SetEntProp(client, Prop_Send, "m_iAmmo", g_PlayerStats[client].primaryAmmo, _, ammoType);
            }
            
            PrintToServer("%s Restored primary weapon %s with clip: %d, reserve: %d for player %N", 
                PREFIX, 
                g_PlayerStats[client].primaryWeapon, 
                g_PlayerStats[client].primaryClip, 
                g_PlayerStats[client].primaryAmmo,
                client);
        }
    }

    CreateTimer(0.1, Timer_RestoreSecondary, client);
    CreateTimer(0.2, Timer_RestoreItems, client);

    PrintToServer("%s Restored stats for player %N", PREFIX, client);
    return Plugin_Stop;
}

public Action Timer_RestoreSecondary(Handle timer, any client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Stop;
    
    if (g_PlayerStats[client].secondaryWeapon[0] != '\0')
    {
        // Check if it's a melee weapon
        if (StrContains(g_PlayerStats[client].secondaryWeapon, "melee_") == 0)
        {
            char meleeType[64];
            strcopy(meleeType, sizeof(meleeType), g_PlayerStats[client].secondaryWeapon[6]); // Skip "melee_"
            
            if (IsValidMeleeWeapon(meleeType))
            {
                // Create the melee weapon using the specific type
                char meleeWeaponName[64];
                Format(meleeWeaponName, sizeof(meleeWeaponName), "weapon_melee_%s", meleeType);
                
                int weapon = CreateEntityByName("weapon_melee");
                if (weapon != -1)
                {
                    char scriptName[64];
                    Format(scriptName, sizeof(scriptName), "scripts/melee/%s", meleeType);
                    
                    DispatchKeyValue(weapon, "melee_script_name", meleeType);
                    DispatchSpawn(weapon);
                    SetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", scriptName);
                    
                    float position[3];
                    GetClientAbsOrigin(client, position);
                    TeleportEntity(weapon, position, NULL_VECTOR, NULL_VECTOR);
                    
                    if (EquipPlayerWeapon(client, weapon))
                    {
                        PrintToServer("%s Successfully restored melee weapon %s for player %N", PREFIX, meleeType, client);
                    }
                    else
                    {
                        PrintToServer("%s Failed to equip melee weapon for player %N", PREFIX, client);
                        AcceptEntityInput(weapon, "Kill");
                    }
                }
                else
                {
                    PrintToServer("%s Failed to create melee entity for player %N", PREFIX, client);
                }
            }
            else
            {
                PrintToServer("%s Invalid melee type: %s for player %N", PREFIX, meleeType, client);
            }
        }
        else
        {
            // Normal secondary weapons (pistols)
            int weapon = GivePlayerItem(client, g_PlayerStats[client].secondaryWeapon);
            if (weapon != -1)
            {
                PrintToServer("%s Restored secondary weapon: %s for player %N", 
                    PREFIX, g_PlayerStats[client].secondaryWeapon, client);
            }
        }
    }
    return Plugin_Stop;
}

public Action Timer_RestoreItems(Handle timer, any client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Stop;
    
    if (g_PlayerStats[client].throwable[0] != '\0')
    {
        GivePlayerItem(client, g_PlayerStats[client].throwable);
    }
    
    if (g_PlayerStats[client].healSlot[0] != '\0')
    {
        GivePlayerItem(client, g_PlayerStats[client].healSlot);
    }
    
    if (g_PlayerStats[client].pillsSlot[0] != '\0')
    {
        GivePlayerItem(client, g_PlayerStats[client].pillsSlot);
    }
    
    return Plugin_Stop;
}

public Action Timer_RestoreAllPlayers(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            RestorePlayerStats(i);
        }
    }
    return Plugin_Stop;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
    {
        if (g_bShouldRestoreStats && g_PlayerStats[client].hasStats)
        {
            CreateTimer(0.5, Timer_RestorePlayerStats, client);
        }
    }
}

public Action Timer_RestorePlayerStats(Handle timer, any client)
{
    if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        RestorePlayerStats(client);
    }
    return Plugin_Stop;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if(!g_bSpawn)
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && !IsFakeClient(i))
            {
                g_bSpawn = true;
                CreateTimer(1.0, Timer_Start, _, TIMER_FLAG_NO_MAPCHANGE);
                break;
            }
        }
    }
}

public Action Timer_Start(Handle timer)
{
    if(!g_bStart)
    {
        g_bStart = true;
        g_bFirstMap = IsFirstMapInScenario();
        CreateTimer(1.0, Timer_DelayedStart, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    return Plugin_Stop;
}

public Action Timer_DelayedStart(Handle timer)
{
    if(g_bEnable && FindMapEntity())
    {
        g_bIsValid = true;
    }
    return Plugin_Stop;
}

// ... existing code ...

// ... existing code ...

public Action Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnable || !g_bIsValid) return Plugin_Continue;
    
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    // Only handle Last Stand finale normally
    if (StrEqual(currentMap, "c14m2_lighthouse", false))
    {
        return Plugin_Continue;
    }
    
    SavePlayerStats();
    g_bShouldRestoreStats = true;
    
    // Disable finale camera if available
    if (g_hCvar_FinaleCamera != null)
    {
        g_hCvar_FinaleCamera.SetInt(1);
    }
    
    char nextMap[64];
    if (GetChangeLevelMap(nextMap, sizeof(nextMap)))
    {
        // Force change to next campaign's first map
        CreateTimer(g_hCvar_FinaleTime.FloatValue, Timer_ForceNextMap, _, TIMER_FLAG_NO_MAPCHANGE);
        return Plugin_Handled;  // Block the original event
    }
    
    return Plugin_Continue;
}

public Action Timer_ForceNextMap(Handle timer)
{
    char nextMap[64];
    if (GetChangeLevelMap(nextMap, sizeof(nextMap)))
    {
        // Force the map change
        ForceChangeLevel(nextMap, "Marathon Mode");
        
        // Clean up any existing changelevel entities
        int entity = -1;
        while ((entity = FindEntityByClassname(entity, "info_changelevel")) != -1)
        {
            AcceptEntityInput(entity, "Kill");
        }
    }
    return Plugin_Stop;
}

public Action Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnable || !g_bIsValid) return Plugin_Continue;
    
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    // Only handle Last Stand finale specially
    if (StrEqual(currentMap, "c14m2_lighthouse", false))
    {
        PrintToChatAll("\x04%s \x01Congratulations! You've completed the marathon!", PREFIX);
        ResetAllPlayerStats();
        return Plugin_Continue;
    }
    
    SavePlayerStats();
    g_bShouldRestoreStats = true;
    
    // Block the event to prevent returning to lobby
    return Plugin_Handled;
}

public Action Timer_ForceStandardTransition(Handle timer)
{
    // Trigger the changelevel entity to use the standard transition
    int changeLevelEnt = FindEntityByClassname(-1, "info_changelevel");
    if (changeLevelEnt != -1)
    {
        AcceptEntityInput(changeLevelEnt, "Changelevel");
    }
    return Plugin_Stop;
}

public Action Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnable || !g_bIsValid) return Plugin_Continue;
    
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    // Only prevent mission loss on finale maps (except Last Stand)
    if (IsFinaleMap(currentMap) && !StrEqual(currentMap, "c14m2_lighthouse", false))
    {
        return Plugin_Handled;
    }
    
    // Don't reset stats on non-finale map losses if we're in a marathon
    if (!IsFinaleMap(currentMap) && IsInMarathon())
    {
        return Plugin_Continue;
    }
    
    // Reset only if we're not in a marathon or it's a finale loss
    g_bShouldRestoreStats = false;
    ResetAllPlayerStats();
    return Plugin_Continue;
}

public Action Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnable || !g_bIsValid) return Plugin_Continue;
    
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    // Save stats for both finale and non-finale transitions
    SavePlayerStats();
    g_bShouldRestoreStats = true;
    
    // Special handling for finale maps
    if (IsFinaleMap(currentMap))
    {
        char nextMap[64];
        if (GetChangeLevelMap(nextMap, sizeof(nextMap)))
        {
            DataPack dp = new DataPack();
            dp.WriteString(nextMap);
            CreateTimer(g_hCvar_TransitionTime.FloatValue, Timer_ForceNextCampaign, dp, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
            return Plugin_Handled;
        }
    }
    
    return Plugin_Continue;
}

public Action Timer_ForceNextCampaign(Handle timer, DataPack dp)
{
    char nextMap[64];
    dp.Reset();
    dp.ReadString(nextMap, sizeof(nextMap));
    
    ForceChangeLevel(nextMap, "Marathon Mode");
    
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "info_changelevel")) != -1)
    {
        AcceptEntityInput(entity, "Kill");
    }
    
    return Plugin_Stop;
}

public void OnMapStart()
{
    if(!g_bInited)
    {
        Init();
    }
    
    if (g_hCvar_FinaleCamera == null)
    {
        InitFinaleCamera();
    }
    if (g_hCvar_FinaleCamera != null)
    {
        g_hCvar_FinaleCamera.SetInt(1);
    }
    
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    // Only reset on first map if we're actually starting fresh
    if (StrEqual(currentMap, "c1m1_hotel", false) && !g_bShouldRestoreStats)
    {
        ResetAllPlayerStats();
    }
    // If we have stats to restore (including non-finale transitions)
    else if (g_bShouldRestoreStats)
    {
        PrintToChatAll("\x04%s \x01Restoring player loadouts...", PREFIX);
        CreateTimer(1.0, Timer_RestoreAllPlayers);
    }
    
    // Print current campaign progress
    for (int i = 0; i < sizeof(g_Campaigns); i++)
    {
        if (StrContains(currentMap, g_Campaigns[i].firstMap, false) == 0)
        {
            PrintToChatAll("\x04%s \x01Starting Campaign %d/14: \x05%s", PREFIX, i + 1, g_Campaigns[i].name);
            break;
        }
    }
}

public void OnMapEnd()
{
    g_bStart = false;    g_bSpawn = false;
    g_bIsValid = false;
    g_bFirstMap = false;
}

public void OnClientPutInServer(int client)
{
    if (!IsFakeClient(client))
    {
        // Only reset stats if we're not in the middle of a marathon
        if (!g_bShouldRestoreStats)
        {
            ResetPlayerStats(client);
        }
        
        if (!g_bSpawn)
        {
            g_bSpawn = true;
            CreateTimer(1.0, Timer_Start, _, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

static bool GetChangeLevelMap(char[] name, int maxLength)
{
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    if (StrEqual(currentMap, "c14m2_lighthouse", false))
    {
        PrintToChatAll("\x04%s \x01Congratulations! You've completed the marathon!", PREFIX);
        return false;
    }
    
    if (IsFinaleMap(currentMap))
    {
        for (int i = 0; i < sizeof(g_Campaigns); i++)
        {
            if (StrEqual(currentMap, g_Campaigns[i].finaleMap, false))
            {
                int nextCampaign = i + 1;
                if (nextCampaign >= sizeof(g_Campaigns))
                {
                    return false;
                }
                strcopy(name, maxLength, g_Campaigns[nextCampaign].firstMap);
                PrintToChatAll("\x04%s \x01 Completed: \x05%s\x01! Next Campaign: \x05%s", 
                    PREFIX, g_Campaigns[i].name, g_Campaigns[nextCampaign].name);
                return true;
            }
        }
    }
    return false;
}

static bool IsFinaleMap(const char[] mapName)
{
    for (int i = 0; i < sizeof(g_Campaigns); i++)
    {
        if (StrEqual(mapName, g_Campaigns[i].finaleMap, false))
        {
            return true;
        }
    }
    return false;
}

static bool IsFirstMapInScenario()
{
    return SDKCall(g_hSDK_CDirector_IsFirstMapInScenario, g_pDirector);
}

static void LoadKvFile()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "data/l4d2_mix_map.cfg");
    if(!FileExists(sPath))
    {
        SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);
    }

    KeyValues kv = new KeyValues("MapLandMarkSet");
    if(!kv.ImportFromFile(sPath))
    {
        SetFailState("\n==========\nFailed to import keyvalue: \"%s\".\n==========", sPath);
    }

    char sMapName[64], sLandMarkName[128];
    if(kv.GotoFirstSubKey())
    {
        do
        {
            kv.GetSectionName(sMapName, sizeof(sMapName));
            kv.GetString("LandMarkName", sLandMarkName, sizeof(sLandMarkName));
            g_mMapLandMarkSet.SetString(sMapName, sLandMarkName);
            g_mMapSet.SetString(sMapName, sMapName);
        } while (kv.GotoNextKey());
    }

    g_msMapLandMarkSet = g_mMapLandMarkSet.Snapshot();
    g_msMapSet = g_mMapSet.Snapshot();

    delete kv;
}

public void CvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_bEnable = g_hCvar_Enable.BoolValue;
}

public Action Command_Reload(int client, int args)
{
    delete g_mMapLandMarkSet;
    delete g_mMapSet;
    delete g_msMapLandMarkSet;
    delete g_msMapSet;

    g_mMapLandMarkSet = new StringMap();
    g_mMapSet = new StringMap();

    LoadKvFile();

    ReplyToCommand(client, "%s Config reloaded.", PREFIX);
    return Plugin_Handled;
}

public void OnPluginEnd()
{
    delete g_mMapLandMarkSet;
    delete g_mMapSet;
    delete g_msMapLandMarkSet;
    delete g_msMapSet;
}

