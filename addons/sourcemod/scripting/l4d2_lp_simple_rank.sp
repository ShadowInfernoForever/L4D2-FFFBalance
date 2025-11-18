/*
- Changelog:
v1.4
    - Added lprank_announce_playtime to display a message when a player joins
    - Update translations
    - Plugin now requires colors include
    - Fix Wipe command, now doesn't wipe play time

v1.3
    - You can now see players stats from the top10 menu
    - Update translations

v1.2
    - Plugin now tracks playtime
    - Update translations

v1.1
    - Escape names with single quotes '\''

v1.0
    - First release
*/

#include <sourcemod>
#include <dbi>
#include <liquidHelpers>
#include <colors>

#define WIPE_PASSWORD "na12345"

// Rank Titles
ArrayList g_RankThresholds;
ArrayList g_RankTitles;

//
// Database
//
Database rankDB;
int CIKills[MAXPLAYERS + 1];
int SIKills[MAXPLAYERS + 1];
int Headshots[MAXPLAYERS + 1];
int HeadshotDamage[MAXPLAYERS + 1];
int PlayerPlayTime[MAXPLAYERS + 1], PlayerJoinTime[MAXPLAYERS + 1];
int Top10Score[10] = { 0 };
char Top10Names[10][MAX_NAME_LENGTH];
char Top10SteamID[10][64];

int rankThresholds[] = {0, 130, 750, 2000, 8000, 12500, 99999};
char rankColors[][] = {"default", "olive", "olive", "green", "green"};
//

//
// Database manipulation
//
char ColumnName[64];
char ColumnDataType[128];
//

//
ConVar cCommonInfectedMult, cSpecialInfectedMult, cHeadshotMult, cHeadshotDamageQuotient;
float fCommonInfectedMult, fSpecialInfectedMult, fHeadshotMult, fHeadshotDamageQuotient;
ConVar cAnnouncePlayTime;
bool bAnnouncePlayTime;
//

public Plugin myinfo =
{
    name = "[L4D2] Simple rank system",
    author = "liquidplasma",
    description = "Simple rank system with top10",
    version = "1.4"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion L4D2Only = GetEngineVersion();
    if (L4D2Only != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "Plugin only supports L4D2");
        return APLRes_Failure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    if (InitDB())
        LogMessage("Connected to SQLite successfully");

    LoadTranslations("l4d2_lp_simple_rank.phrases");

    g_RankThresholds = new ArrayList();
    g_RankTitles = new ArrayList(ByteCountToCells(64));

    cCommonInfectedMult =       CreateConVar("lprank_common_mult", "0.2", "Multiplier for the scoring system from common infected kills");
    cSpecialInfectedMult =      CreateConVar("lprank_special_mult", "3.0", "Multiplier for the scoring system from special infected kills");
    cHeadshotMult =             CreateConVar("lprank_headshot_mult", "10.0", "Multiplier for the scoring system for headshots");
    cHeadshotDamageQuotient =   CreateConVar("lprank_headshotdamage_quotient", "1000.0", "Quotient for the scoring system for headshot damage");
    cAnnouncePlayTime =         CreateConVar("lprank_announce_playtime", "0", "Shows a message relaying playtime to a joining player (0 - disabled / 1 - enabled)");

    cCommonInfectedMult.AddChangeHook(ChangedConvar);
    cSpecialInfectedMult.AddChangeHook(ChangedConvar);
    cHeadshotMult.AddChangeHook(ChangedConvar);
    cHeadshotDamageQuotient.AddChangeHook(ChangedConvar);
    cAnnouncePlayTime.AddChangeHook(ChangedConvar);
    AutoExecConfig(true, "l4d2_lp_simple_rank");

    HookEvent("player_death", PlayerDeathEvent, EventHookMode_Post);
    HookEvent("player_hurt", PlayerHurtEvent, EventHookMode_Post);
    HookEvent("infected_death", InfectedDeathEvent, EventHookMode_Post);

    AddCommandListener(Command_Say, "say");

    RegConsoleCmd("sm_rank", RankMenu, "Opens simple rank menu");
    RegConsoleCmd("sm_top10", Top10Menu, "Open the top 10 players");
    RegAdminCmd("sm_lp_wipe", WipeDB, ADMFLAG_ROOT, "Wipes the database");
    RegAdminCmd("sm_lp_remove_entry", CleanLowScoresCMD, ADMFLAG_ROOT, "Clean entries with a score lower than this");
    RegAdminCmd("sm_setscore", Command_SetScore, ADMFLAG_GENERIC, "Set a player's score");

    GetCvars();
    GetTop10(0);
    LoadRankTitles();
}

public bool InitDB()
{
    static char error[255];
    rankDB = SQLite_UseDatabase("lp_simple_rank_db", error, sizeof(error));
    if (rankDB == INVALID_HANDLE)
    {
        SetFailState(error);
        return false;
    }
    SQL_FastQuery(rankDB, "CREATE TABLE IF NOT EXISTS lp_simple_rank (steamid TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, CIKills INTEGER, SIKills INTEGER, Headshots INTEGER, HeadshotDamage INT, Score INT);");
    CheckForColumn("PlayTime", "INTEGER DEFAULT 0");
    return true;
}

public void ChangedConvar(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

public void GetCvars()
{
    fCommonInfectedMult = cCommonInfectedMult.FloatValue;
    fSpecialInfectedMult = cSpecialInfectedMult.FloatValue;
    fHeadshotMult = cHeadshotMult.FloatValue;
    fHeadshotDamageQuotient = cHeadshotDamageQuotient.FloatValue;
    bAnnouncePlayTime = cAnnouncePlayTime.BoolValue;
}

//
// Table
//

// Check if a column exists, if not create it
public void CheckForColumn(const char[] columnName, const char[] columnDataType)
{
    strcopy(ColumnName, sizeof(ColumnName), columnName)
    strcopy(ColumnDataType, sizeof(ColumnDataType), columnDataType);
    static char query[64];
    Format(query, sizeof(query), "PRAGMA table_info(lp_simple_rank);");
    SQL_TQuery(rankDB, AddColumn, query);
}

void AddColumn(Handle db, Handle query, const char[] error, any data)
{
    if (StrEqual(error, ""))
    {
        static char colName[64];
        bool columnExists = false;
        while (SQL_FetchRow(query))
        {
            SQL_FetchString(query, 1, colName, sizeof(colName));
            if (StrEqual(colName, ColumnName))
            {
                columnExists = true;
                break;
            }
        }

        if (!columnExists)
        {
            static char fastQuery[96];
            Format(fastQuery, sizeof(fastQuery), "ALTER TABLE lp_simple_rank ADD COLUMN %s %s;", ColumnName, ColumnDataType);
            LogMessage("Added column %s successfully", ColumnName);
            SQL_FastQuery(rankDB, fastQuery);
        }
    }
    else
        LogError("SQL Error in AddColumn: %s", error);
}

// Check if steamid exists and update name if necessary
public void CheckAndUpdateName(int client)
{
    static char steamid[64];
    static char query[256];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    if (steamid[0] < '0' || steamid[0] > '9')
        return;

    // Prepare the query to check if the steamid exists
    Format(query, sizeof(query), "SELECT name FROM lp_simple_rank WHERE steamid = '%s';", steamid);

    // Execute the query
    SQL_TQuery(rankDB, CheckNameCallback, query, client);
}

// Callback function to process the query result
public void CheckNameCallback(Handle db, Handle query, const char[] error, any data)
{
    int client = data;
    if (!IsValidClient(client))
        return;

    static char existingName[MAX_NAME_LENGTH];
    static char playerName[MAX_NAME_LENGTH];
    static char steamid[64];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
    if (steamid[0] < '0' || steamid[0] > '9')
        return;

    if (StrEqual(error, ""))
    {
        if (SQL_HasResultSet(query) && SQL_FetchRow(query))
        {
            // Fetch existing name
            SQL_FetchString(query, 0, existingName, sizeof(existingName));

            // Compare names and update if different
            GetClientName(client, playerName, sizeof(playerName));

            // Check if playerName contains a single quote and escape it if necessary
            static char escapedPlayerName[MAX_NAME_LENGTH * 2]; // *2 to account for possible doubling of quotes
            if (StrContains(playerName, "'") != -1)
            {
                EscapeSingleQuotes(playerName, escapedPlayerName, sizeof(escapedPlayerName));
            }
            else
            {
                strcopy(escapedPlayerName, sizeof(escapedPlayerName), playerName);
            }

            // Compare the escaped names
            if (strcmp(existingName, escapedPlayerName) != 0)
            {
                // Name has changed, update it
                static char updateQuery[256];
                Format(updateQuery, sizeof(updateQuery), "UPDATE lp_simple_rank SET name = '%s' WHERE steamid = '%s';", escapedPlayerName, steamid);
                SQL_TQuery(rankDB, SQLErrorCallBack, updateQuery);
            }
        }
        else
        {
            // If steamid does not exist, insert the new record
            GetClientName(client, playerName, sizeof(playerName));
            static char insertQuery[256];
            if (StrContains(playerName, "'") != -1)
            {
                // Name contains a single quote, so we need to escape it
                static char escapedName[MAX_NAME_LENGTH * 2]; // *2 to account for possible doubling of quotes
                EscapeSingleQuotes(playerName, escapedName, sizeof(escapedName));

                // Now use escapedName in your SQL query
                Format(insertQuery, sizeof(insertQuery), "INSERT OR REPLACE INTO lp_simple_rank (steamid, name) VALUES ('%s', '%s')", steamid, escapedName);
            }
            else
            {
                // No single quote, so you can use playerName directly
                Format(insertQuery, sizeof(insertQuery), "INSERT OR REPLACE INTO lp_simple_rank (steamid, name) VALUES ('%s', '%s')", steamid, playerName);
            }
            SQL_TQuery(rankDB, SQLErrorCallBack, insertQuery);
        }
    }
    else
    {
        // Handle SQL error
        LogError("SQL Error in check name callback: %s", error);
    }
}

// Saves this clients stats with scoring
public void SaveStats(int client)
{
    static char steamid[64];
    static char buffer[320];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
    if (steamid[0] < '0' || steamid[0] > '9')
        return;

    int score = CalculateScore(client);
    int sessionTime = CalculateSessionTime(client);
    Format(buffer, sizeof(buffer),
            "UPDATE lp_simple_rank SET CIKills = %i, SIKills = %i, Headshots = %i, HeadshotDamage = %i, Score = %i, PlayTime = PlayTime + %i WHERE steamid = '%s'",
            CIKills[client], SIKills[client], Headshots[client], HeadshotDamage[client], score, sessionTime, steamid);
    SQL_TQuery(rankDB, SQLErrorCallBack, buffer);
}

// Loads this clients stats
public void LoadStats(int client)
{
    static char steamid[64];
    static char query[320];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
    if (steamid[0] < '0' || steamid[0] > '9')
        return;
    Format(query, sizeof(query),
           "SELECT CIKills, SIKills, Headshots, HeadshotDamage, PlayTime FROM lp_simple_rank WHERE steamid = '%s';",
           steamid);
    SQL_TQuery(rankDB, LoadStatsCallback, query, client);

    // Announce message
    if (bAnnouncePlayTime)
        CreateTimer(5.0, PrintPlayTime, client, TIMER_FLAG_NO_MAPCHANGE);
}

stock void LoadRankTitles()
{
    decl String:Path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, Path, sizeof(Path), "data/ranks.cfg");
    PrintToServer("Looking for ranks in: %s", Path);

    if (!FileExists(Path))
    {
        PrintToServer("Rank Titles Error: Cannot read the config %s", Path);
        return;
    }

    // Create the KeyValues object. The name here is arbitrary
    new Handle:kvRanks = CreateKeyValues("RankTitles");

    if (!FileToKeyValues(kvRanks, Path))
    {
        PrintToServer("Rank Titles Error: Failed to load ranks from %s", Path);
        CloseHandle(kvRanks);
        return;
    }

    PrintToServer("Rank Titles: File loaded successfully!");

    // Check the root section name
    char sRoot[64];
    KvGetSectionName(kvRanks, sRoot, sizeof(sRoot));
    PrintToServer("DEBUG: Root section is: %s", sRoot);

    // If the root is not "RankTitles", then try to jump to that section.
    if (!StrEqual(sRoot, "RankTitles", false))
    {
        if (!KvJumpToKey(kvRanks, "RankTitles"))
        {
            PrintToServer("Rank Titles Error: 'RankTitles' section not found in the config!");
            CloseHandle(kvRanks);
            return;
        }
    }

    // Reset the traversal pointer.
    KvRewind(kvRanks);

    int rankCount = 0;

    // Iterate over each subkey (each rank)
    if (KvGotoFirstSubKey(kvRanks))
    {
        do {
            char rankName[64];       // This will hold the rank title (e.g. "ExaltedConqueror")
            char thresholdStr[32];   // This will hold the threshold value as a string

            // Get the current subkey name.
            KvGetSectionName(kvRanks, rankName, sizeof(rankName));
            // Inside the rank subkey, get the value for "threshold".
            KvGetString(kvRanks, "threshold", thresholdStr, sizeof(thresholdStr), "");

            PrintToServer("Found Rank: %s, Threshold: %s", rankName, thresholdStr);

            int threshold = StringToInt(thresholdStr);
            g_RankThresholds.Push(threshold);
            g_RankTitles.PushString(rankName);

            rankCount++;
        } while (KvGotoNextKey(kvRanks));
    }

    if (rankCount == 0)
    {
        PrintToServer("Rank Titles Error: No ranks found in the config!");
    }
    else
    {
        PrintToServer("Rank Titles successfully loaded! Total ranks: %d", rankCount);
    }

    CloseHandle(kvRanks);
}
// Callback function to handle the query result
public void LoadStatsCallback(Handle db, Handle query, const char[] error, any data)
{
    int client = data;
    if (!IsValidClient(client))
        return;

    if (StrEqual(error, ""))
    {
        if (SQL_HasResultSet(query) && SQL_FetchRow(query))
        {
            // Retrieve values from the result set
            CIKills[client] = SQL_FetchInt(query, 0);
            SIKills[client] = SQL_FetchInt(query, 1);
            Headshots[client] = SQL_FetchInt(query, 2);
            HeadshotDamage[client] = SQL_FetchInt(query, 3);
            PlayerPlayTime[client] = SQL_FetchInt(query, 4);
        }
        else
        {
            CIKills[client] = 0;
            SIKills[client] = 0;
            Headshots[client] = 0;
            HeadshotDamage[client] = 0;
            PlayerPlayTime[client] = 0;
        }
    }
    else
    {
        // Handle SQL error
        LogError("SQL Error in load stats callback: %s", error);
    }
}

public Action PrintPlayTime(Handle timer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;

    static char buffer[256];
    static char playerName[MAX_NAME_LENGTH];
    GetClientName(client, playerName, sizeof(playerName));
    FormatPlayTime(client, PlayerPlayTime[client], buffer, sizeof(buffer), playerName, false, true);
    CPrintToChat(client, buffer);
    return Plugin_Continue;
}

public Action Command_SetScore(int client, int args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "[SM] Usage: sm_setscore <player> <score>");
        return Plugin_Handled;
    }

    char arg1[32], arg2[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    int target = FindTarget(client, arg1, true, false);
    if (target == -1)
    {
        ReplyToCommand(client, "[SM] Player not found.");
        return Plugin_Handled;
    }

    int newScore = StringToInt(arg2);
    if (newScore < 0)
    {
        ReplyToCommand(client, "[SM] Score cannot be negative.");
        return Plugin_Handled;
    }

    // Calculate the weight of each factor
    float weightCiKills = 0.5;
    float weightSiKills = 1.5;
    float weightHeadshots = 1.0;
    float weightHeadshotDamage = 0.2;
    float weightPlayTime = 0.3;

    float totalWeight = weightCiKills + weightSiKills + weightHeadshots + weightHeadshotDamage + weightPlayTime;

    // Distribute the new score proportionally
    CIKills[target] = RoundToNearest((newScore * weightCiKills) / (fCommonInfectedMult * totalWeight));
    SIKills[target] = RoundToNearest((newScore * weightSiKills) / (fSpecialInfectedMult * totalWeight));
    Headshots[target] = RoundToNearest((newScore * weightHeadshots) / (fHeadshotMult * totalWeight));
    HeadshotDamage[target] = RoundToNearest((newScore * weightHeadshotDamage) * fHeadshotDamageQuotient / totalWeight);
    PlayerPlayTime[target] = RoundToNearest((newScore * weightPlayTime) / totalWeight);

    // Force recalculation of the score
    int updatedScore = CalculateScore(target);

    ReplyToCommand(client, "[SM] Set %N's score to %d (recalculated: %d).", target, newScore, updatedScore);
    return Plugin_Handled;
}

// Calculates this clients scoref
public int CalculateScore(int client)
{
    int commonScore = RoundToNearest(CIKills[client] * fCommonInfectedMult);
    int specialInfectedScore = RoundToNearest(SIKills[client] * fSpecialInfectedMult);
    int headshotScore = RoundToNearest(Headshots[client] * fHeadshotMult);
    int headshotDamageScore = RoundToNearest(HeadshotDamage[client] / fHeadshotDamageQuotient);

    // Factores de ponderación adicionales
    float weightCiKills = 0.5;
    float weightSiKills = 1.5;
    float weightHeadshots = 1.0;
    float weightHeadshotDamage = 0.2;
    float weightPlayTime = 0.3;

    int playTime = ClampInt(PlayerPlayTime[client], 0, 3600);

    // Cálculo final de puntuación
    float finalScore = (commonScore * weightCiKills) 
                     + (specialInfectedScore * weightSiKills)
                     + (headshotScore * weightHeadshots) 
                     + (headshotDamageScore * weightHeadshotDamage) 
                     + (playTime * weightPlayTime);

    return RoundToNearest(finalScore);
}

void GetRankTitle(int score, char[] buffer, int maxlen)
{
    int count = g_RankThresholds.Length;
    LogMessage("🔍 Searching for rank title. Player score: %d", score);
    LogMessage("📝 Total ranks loaded: %d", count);

    char bestRank[64] = "Desconocido"; // Rango por defecto
    int bestThreshold = -1; // Umbral más alto encontrado dentro del puntaje

    for (int i = 0; i < count; i++)
    {
        int threshold = g_RankThresholds.Get(i);
        char tempTitle[64];
        g_RankTitles.GetString(i, tempTitle, sizeof(tempTitle));

        LogMessage("➡ Checking rank: %s (Threshold: %d)", tempTitle, threshold);

        if (score >= threshold && threshold > bestThreshold) // Seleccionar el mayor posible dentro del límite
        {
            strcopy(bestRank, sizeof(bestRank), tempTitle);
            bestThreshold = threshold;
        }
    }

    strcopy(buffer, maxlen, bestRank);
    LogMessage("✅ Assigned Rank Title: %s", buffer);
}

void GetRankTitleAndSendChatMessage(int client, int score, char[] message)
{
    char rankTitle[64];
    
    // Retrieve rank title based on the player's score
    GetRankTitle(score, rankTitle, sizeof(rankTitle));

    char translatedRank[64];
    Format(translatedRank, sizeof(translatedRank), "%T", rankTitle, client);

    if (translatedRank[0] == '\0')
    {
        // Allow the command to pass through without modifying it
      return;
    }

    char cleanMessage[256];
    RemoveQuotes(message, cleanMessage, sizeof(cleanMessage));

    // Get the player's name
    char playerName[MAX_NAME_LENGTH];
    GetClientName(client, playerName, sizeof(playerName));

int index = 0; // Por defecto, todos inician en el primer índice

for (int i = 1; i < sizeof(rankThresholds); i++) // Empezar desde el segundo umbral
{
    if (score >= rankThresholds[i]) // Verificar el puntaje
    {
        index = i; // Actualizar el índice
    }
    else
    {
        break; // Si no cumple, salir del loop
    }
}

// Si el usuario es un "newborn" (índice 0), no mostrar etiqueta
if (index == 0)
{
    CPrintToChatAllEx(client, "{teamcolor}%s{default}: %s", playerName, cleanMessage);
}
else
{
    CPrintToChatAllEx(client, "[{%s}%s{default}] {teamcolor}%s{default}: %s", rankColors[index - 1], translatedRank, playerName, cleanMessage);
}

}

public Action:Command_Say(client, const String:command[], argc)
{
    // Retrieve the player's client ID and the message they typed
    if (client <= 0) return Plugin_Continue;

    decl String:argstring[256];
    GetCmdArgString(argstring, sizeof(argstring));  // Retrieve the entire command string

    // Check if the message starts with a command (e.g., '!command')
    if (argstring[0] == '!')
    {
        // Allow the command to pass through without modifying it
        return Plugin_Continue;
    }

    // Get the player's score (ensure the CalculateScore function exists and works)
    int score = CalculateScore(client);  // Placeholder function to calculate the player's score

    // Call the function to get the rank and send the chat message
    GetRankTitleAndSendChatMessage(client, score, argstring);  // We don't need the score or message here if you're using the rank directly

    // Prevent the default "say" behavior (if needed)
    return Plugin_Handled;
}

public int CalculateSessionTime(int client)
{
    return GetTime() - PlayerJoinTime[client];
}

public void OnClientPostAdminCheck(int client)
{
    if (!IsValidClient(client) || IsFakeClient(client))
        return;
    CheckAndUpdateName(client);
    PlayerJoinTime[client] = GetTime();
    LoadStats(client);
}

public void OnClientDisconnect(int client)
{
    if (!IsValidClient(client) || IsFakeClient(client))
        return;

    CheckAndUpdateName(client);
    SaveStats(client);
    CIKills[client] = SIKills[client] = Headshots[client] = HeadshotDamage[client] = PlayerPlayTime[client] = PlayerJoinTime[client] = 0;
}

public void SQLErrorCallBack(Handle owner, Handle handle, const char[] error, any data)
{
    if (!StrEqual("", error))
        LogError("SQLite Error in generic error callback: %s", error);
}

///
/// Events
///

public void PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    bool headshot = event.GetBool("headshot");
    if (!IsValidClient(attacker) || !IsValidClient(victim) || IsFakeClient(attacker))
        return;
    if (!OnSurvivorTeam(attacker) || !OnInfectedTeam(victim))
        return;

    if (headshot)
        Headshots[attacker]++;
    SIKills[attacker]++;
    //fToChat(attacker, "Killed SI named %N. SI Kills: %i", victim, SIKills[attacker])
}

public void PlayerHurtEvent(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int damage = event.GetInt("dmg_health");
    bool headshot = event.GetInt("hitgroup") == HITGROUP_HEAD;
    if (!IsValidClient(attacker) || !IsValidClient(victim) || IsFakeClient(attacker))
        return;
    if (!OnSurvivorTeam(attacker) || !OnInfectedTeam(victim))
        return;

    if (headshot)
        HeadshotDamage[attacker] += damage;
    //PrintToChat(attacker, "Hit SI named %N for %i damage and headshot total %i", victim, damage, HeadshotDamage[attacker]);
}

public void InfectedDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int commonID = event.GetInt("infected_id");
    bool headshot = event.GetBool("headshot");
    if (!IsValidClient(attacker) || !IsValidEntity(commonID))
        return;
    if (!OnSurvivorTeam(attacker))
        return;

    CIKills[attacker]++;
    if (headshot)
        Headshots[attacker]++;
    //PrintToChat(attacker, "Infected kills and headshots: CI Kills: %i Headshots:%i", CIKills[attacker], Headshots[attacker]);
}

///
/// Menus and commands
///

public Action CleanLowScoresCMD(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_lp_remove_entry <min score>");
        return Plugin_Handled;
    }
    int floor = GetCmdArgInt(args);
    if (floor < 0)
    {
        ReplyToCommand(client, "Argument must be 0 or higher");
        return Plugin_Handled;
    }
    static char timeBuffer[32];
    FormatTime(timeBuffer, sizeof(timeBuffer), NULL_STRING, GetTime());
    if (client == 0) // Server console, rcon, etc
    {
        CleanLowScores(floor);
        LogMessage("CONSOLE cleared scores below %i on %s", floor, timeBuffer);
        return Plugin_Handled;
    }
    static char steamid[20];
    if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
    {
        ReplyToCommand(client, "%N [%s] cleared scores below %i on %s", client, steamid, floor, timeBuffer);
        LogMessage("%N [%s] cleared scores below %i on %s", client, steamid, floor, timeBuffer);
        CleanLowScores(floor);
        return Plugin_Handled;
    }
    return Plugin_Handled;
}

public Action WipeDB(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "This action cannot be made from the CONSOLE/Server side");
        return Plugin_Handled;
    }
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_lp_wipe <password defined in plugin source>");
        return Plugin_Handled;
    }
    static char cmdBuffer[32];
    GetCmdArgString(cmdBuffer, sizeof(cmdBuffer));
    if (!StrEqual(cmdBuffer, WIPE_PASSWORD))
    {
        ReplyToCommand(client, "Wrond password for database wipe");
        ReplyToCommand(client, "Usage: sm_lp_wipe <password defined in plugin source>");
        return Plugin_Handled;
    }
    static char steamid[20];
    if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
    {
        static char timeBuffer[32];
        FormatTime(timeBuffer, sizeof(timeBuffer), NULL_STRING, GetTime());
        LogMessage("%N [%s] wiped database on %s", client, steamid, timeBuffer);
        WipeDatabase();
        return Plugin_Handled;
    }
    return Plugin_Handled;
}

public Action RankMenu(int client, int args)
{
    if (!client)
        return Plugin_Handled;

    Menu rankMenu = new Menu(RankMenuHandler);
    static char menuBuffer[96];
    static char playerName[MAX_NAME_LENGTH];
    static char formattedPlayTime[128];

    GetClientName(client, playerName, sizeof(playerName));
    FormatPlayTime(client, PlayerPlayTime[client], formattedPlayTime, sizeof(formattedPlayTime), playerName);

    int playerScore = CalculateScore(client);

    char rankTitle[32];
    GetRankTitle(playerScore, rankTitle, sizeof(rankTitle));  // Convertimos playerScore a float por compatibilidad

    rankMenu.SetTitle(formattedPlayTime);
    rankMenu.AddItem("Spacer", "-====\\====-", ITEMDRAW_RAWLINE);

    char translatedRank[64];
    PrintToServer("RankTitle before format: %s", rankTitle);
    Format(translatedRank, sizeof(translatedRank), "%T", rankTitle, client);
    PrintToServer("Translated Rank: %s", translatedRank);

    Format(menuBuffer, sizeof(menuBuffer), "%T", "Rank", client, translatedRank);
    rankMenu.AddItem("Rank", menuBuffer, ITEMDRAW_DISABLED);

    Format(menuBuffer, sizeof(menuBuffer), "%T", "Score", client, playerScore);
    rankMenu.AddItem("Score", menuBuffer, ITEMDRAW_DISABLED);

    Format(menuBuffer, sizeof(menuBuffer), "%T", "CommonKilled", client, CIKills[client]);
    rankMenu.AddItem("CIKills", menuBuffer, ITEMDRAW_DISABLED);

    Format(menuBuffer, sizeof(menuBuffer), "%T", "SpecialKilled", client, SIKills[client]);
    rankMenu.AddItem("SIKills", menuBuffer, ITEMDRAW_DISABLED);

    Format(menuBuffer, sizeof(menuBuffer), "%T", "Headshots", client, Headshots[client]);
    rankMenu.AddItem("Headshots", menuBuffer, ITEMDRAW_DISABLED);

    float headshotsPerKill = float(Headshots[client]) / float((SIKills[client] + CIKills[client]));
    Format(menuBuffer, sizeof(menuBuffer), "%T", "HeadshotsPerKill", client, headshotsPerKill);
    rankMenu.AddItem("HeadshotsPerKill", menuBuffer, ITEMDRAW_DISABLED);

    Format(menuBuffer, sizeof(menuBuffer), "%T", "HeadshotDamage", client, HeadshotDamage[client]);
    rankMenu.AddItem("HeadshotDamage", menuBuffer, ITEMDRAW_DISABLED);

    rankMenu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public Action Top10Menu(int client, int args)
{
    if (!client)
        return Plugin_Handled;

    GetTop10(client);
    return Plugin_Handled;
}

public int RankMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_End:
            delete menu;
    }
    return 0;
}

// Function to retrieve the top 10 players
public void GetTop10(int client)
{
    static char query[96];

    // Construct the query to get top 10 scores
    Format(query, sizeof(query), "SELECT steamid, name, Score FROM lp_simple_rank ORDER BY Score DESC LIMIT 10;");

    // Execute the query with a callback to process the results
    SQL_TQuery(rankDB, Top10Callback, query, client);
}

// Callback function to process the top 10 results
public void Top10Callback(Handle db, Handle query, const char[] error, any data)
{
    int client = data;
    if (StrEqual(error, ""))
    {
        int rank = 0;
        char playerName[MAX_NAME_LENGTH * 2];
        char unescapedName[MAX_NAME_LENGTH];
        char steamid[64];
        int score;

        // Iterate through the results
        while (SQL_FetchRow(query))
        {
            // Fetch the name and score from the current row
            SQL_FetchString(query, 0, steamid, sizeof(steamid));
            SQL_FetchString(query, 1, playerName, sizeof(playerName));
            score = SQL_FetchInt(query, 2);
            // Unescape the name
            UnescapeSingleQuotes(playerName, unescapedName, sizeof(unescapedName));

            strcopy(Top10SteamID[rank], sizeof(steamid), steamid);
            strcopy(Top10Names[rank], MAX_NAME_LENGTH, unescapedName);
            Top10Score[rank] = score;
            rank++;
        }
        // Now create and display the menu
        if (IsValidClient(client))
            Top10MenuShow(client);
    }
    else
    {
        // Handle SQL error
        LogError("SQL Error in top10 callback: %s", error);
    }
}

// Function to create and display the Top 10 menu
public void Top10MenuShow(int client)
{
    static char menuBuffer[64];
    static char info[64];
    Menu top10Menu = new Menu(Top10MenuHandler);
    top10Menu.SetTitle("     - Top 10 Players -     ");

    for (int i = 0; i < sizeof(Top10Score); i++)
    {
        if (Top10Score[i] != 0)
        {
            Format(menuBuffer, sizeof(menuBuffer), "%s: %i", Top10Names[i], Top10Score[i]);
            Format(info, sizeof(info), "Top10Pos%i", i + 1);
            top10Menu.AddItem(info, menuBuffer, ITEMDRAW_DEFAULT);
        }
    }

    top10Menu.Display(client, MENU_TIME_FOREVER);
}

public int Top10MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            int client = param1;
            int selectedPlayer = param2;
            GetRankFromTop10(client, selectedPlayer);
        }
        case MenuAction_End:
            delete menu;
    }
    return 0;
}

public void GetRankFromTop10(int client, int selectedPlayer)
{
    static char query[320];
    Format(query, sizeof(query), "SELECT name, CIKills, SIKills, Headshots, HeadshotDamage, Score, PlayTime FROM lp_simple_rank WHERE steamid = '%s';", Top10SteamID[selectedPlayer]);
    SQL_TQuery(rankDB, RankTop10PrintMenu, query, client);
}

public void RankTop10PrintMenu(Handle db, Handle query, const char[] error, any data)
{
    int client = data;

    // Verifica si no hay errores en la consulta SQL
    if (StrEqual(error, ""))
    {
        // Verifica si la consulta devolvió resultados y luego extrae los datos
        if (SQL_HasResultSet(query) && SQL_FetchRow(query))
        {
            static char playerName[MAX_NAME_LENGTH];
            // Obtén los valores de la consulta SQL y asignarlos a las variables correspondientes
            int ciKills = SQL_FetchInt(query, 1);         // Muertos comunes
            int siKills = SQL_FetchInt(query, 2);         // Muertos especiales
            int headshots = SQL_FetchInt(query, 3);       // Headshots
            int headshotDamage = SQL_FetchInt(query, 4);  // Daño de headshots
            int score = SQL_FetchInt(query, 5);           // Puntuación
            int playTime = SQL_FetchInt(query, 6);        // Tiempo jugado

            // Obtén el nombre del jugador de la consulta SQL
            SQL_FetchString(query, 0, playerName, sizeof(playerName));

            // Muestra el menú con la clasificación
            RankTop10MenuShow(playerName, client, ciKills, siKills, headshots, headshotDamage, score, playTime);
        }
    }
    else
    {
        // Maneja el caso en que la consulta tenga un error
        LogError("SQL Error in RankTop10PrintMenu callback: %s", error);
    }
}

// Show a players stats from the top10 menu
public void RankTop10MenuShow(char[] playerName, int client, int ciKills, int siKills, int headshots, int headshotdamage, int score, int playtime)
{
    Menu rankTop10Choice = new Menu(SpecificPlayerMenu);
    static char formattedTime[128];
    static char menuBuffer[96];
    FormatPlayTime(client, playtime, formattedTime, sizeof(formattedTime), playerName, true);
    rankTop10Choice.SetTitle(formattedTime);

    Format(menuBuffer, sizeof(menuBuffer), "%T", "Score", client, score);
    rankTop10Choice.AddItem("Score", menuBuffer, ITEMDRAW_DISABLED);

    Format(menuBuffer, sizeof(menuBuffer), "%T", "CommonKilled", client, ciKills);
    rankTop10Choice.AddItem("CIKills", menuBuffer, ITEMDRAW_DISABLED);

    Format(menuBuffer, sizeof(menuBuffer), "%T", "SpecialKilled", client, siKills);
    rankTop10Choice.AddItem("SIKills", menuBuffer, ITEMDRAW_DISABLED);

    Format(menuBuffer, sizeof(menuBuffer), "%T", "Headshots", client, headshots);
    rankTop10Choice.AddItem("Headshots", menuBuffer, ITEMDRAW_DISABLED);

    float headshotsPerKill = float(headshots) / float((siKills + ciKills));
    Format(menuBuffer, sizeof(menuBuffer), "%T", "HeadshotsPerKill", client, headshotsPerKill);
    rankTop10Choice.AddItem("HeadshotsPerKill", menuBuffer, ITEMDRAW_DISABLED);

    Format(menuBuffer, sizeof(menuBuffer), "%T", "HeadshotDamage", client, headshotdamage);
    rankTop10Choice.AddItem("HeadshotDamage", menuBuffer, ITEMDRAW_DISABLED);

    rankTop10Choice.ExitBackButton = true;
    rankTop10Choice.Display(client, MENU_TIME_FOREVER);
}

int SpecificPlayerMenu(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Cancel:
        {
            int client = param1;
            int endReason = param2;
            if (endReason == MenuCancel_ExitBack)
                Top10MenuShow(client);
        }
        case MenuAction_End:
            delete menu;
    }
    return 0;
}

//
// Admins commands
//

public void WipeDatabase()
{
    for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || IsFakeClient(i))
			continue;

        CIKills[i] = SIKills[i] = Headshots[i] = HeadshotDamage[i] = 0;
    }
    static char query[136];

    // Construct the query to update all entries, setting all columns except PlayTime and the primary key to their default values
    Format(query, sizeof(query), "UPDATE lp_simple_rank SET CIKills = 0, SIKills = 0, Headshots = 0, HeadshotDamage = 0, Score = 0 WHERE steamid IS NOT NULL;");

    // Execute the query
    SQL_TQuery(rankDB, WipeDatabaseCallback, query);
}

// Optional: Callback function to handle the result or errors
public void WipeDatabaseCallback(Handle db, Handle query, const char[] error, any data)
{
    if (StrEqual(error, ""))
    {
        LogMessage("Database wiped successfully.");
    }
    else
    {
        LogError("SQL Error during wipe: %s", error);
    }
}


public void CleanLowScores(int minScore)
{
    static char query[96];

    // Construct the query to delete entries with a score lower than minScore
    Format(query, sizeof(query), "DELETE FROM lp_simple_rank WHERE Score < %d;", minScore);

    // Execute the query
    SQL_TQuery(rankDB, CleanLowScoresCallback, query);
}

// Optional: Callback function to handle the result or errors
public void CleanLowScoresCallback(Handle db, Handle query, const char[] error, any data)
{
    if (StrEqual(error, ""))
    {
        LogMessage("Low scores have been cleaned from the database.");
    }
    else
    {
        // Handle SQL error
        LogError("SQL Error during cleaning: %s", error);
    }
}

//
// Misc methods
//

void FormatPlayTime(int client, int playTime, char[] buffer, int maxlen, char[] playerName, bool top10Menu = false, bool welcomeMessage = false)
{
    int months = playTime / 2592000;
    int days = (playTime % 2592000) / 86400;
    int hours = (playTime % 86400) / 3600;
    int minutes = (playTime % 3600) / 60;

    if (welcomeMessage)
    {
        days = playTime / 86400;
        Format(buffer, maxlen, "%T", "LoginMessage", client, playerName, days, hours, minutes);
        return;
    }

    if (top10Menu)
    {
        Format(buffer, maxlen, "%T", "SeeOtherPlayer", client, playerName, months, days, hours, minutes);
        return;
    }

    if (months > 0)
        Format(buffer, maxlen, "%T", "WelcomeMonths", client, playerName, months, days, hours, minutes);
    else
        Format(buffer, maxlen, "%T", "WelcomeDays", client, playerName, days, hours, minutes);
}

public void EscapeSingleQuotes(const char[] input, char[] output, int outputLen)
{
    int len = strlen(input);
    int outIndex = 0;

    for (int i = 0; i < len && outIndex < outputLen - 1; i++)
    {
        if (input[i] == '\'')
        {
            if (outIndex < outputLen - 2)
            {
                output[outIndex++] = '\'';
            }
            else
            {
                break;
            }
        }
        output[outIndex++] = input[i];
    }

    output[outIndex] = '\0';
}

public void UnescapeSingleQuotes(const char[] escapedName, char[] originalName, int maxLength)
{
    int i = 0, j = 0;

    // Check if there's any double single quote to unescape
    bool hasEscapedQuote = StrContains(escapedName, "''") != -1;

    if (!hasEscapedQuote)
    {
        // No need to unescape, just copy the original name
        strcopy(originalName, maxLength, escapedName);
        return;
    }

    // If the name contains escaped quotes, proceed with unescaping
    while (escapedName[i] != '\0' && j < maxLength - 1)
    {
        if (escapedName[i] == '\'' && escapedName[i + 1] == '\'')
        {
            // Skip one of the single quotes
            i++;
        }
        originalName[j++] = escapedName[i++];
    }
    originalName[j] = '\0';
}

int ClampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

// Function to remove quotes
void RemoveQuotes(char[] input, char[] output, int maxlen)
{
    int j = 0;
    for (int i = 0; i < strlen(input) && j < maxlen - 1; i++)
    {
        if (input[i] == '"' || input[i] == '\'')  // Check for quotes or apostrophes
            continue;  // Skip quotes
        output[j++] = input[i];
    }
    output[j] = '\0';  // Null-terminate the output string
}
