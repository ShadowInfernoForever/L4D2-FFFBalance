#include <left4dhooks>
#include <sourcemod>
#include <sdktools>

#define HITGROUP_GENERIC     0
#define HITGROUP_HEAD        1
#define HITGROUP_CHEST       2
#define HITGROUP_STOMACH     3
#define HITGROUP_LEFTARM     4
#define HITGROUP_RIGHTARM    5
#define HITGROUP_LEFTLEG     6
#define HITGROUP_RIGHTLEG    7
#define HITGROUP_GEAR        10
#define isEdictIndex(%1) (MaxClients < %1 <= 2048)

/**
 * EASY = 1
 * NORMAL = 2
 * ADVANCED = 3
 * EXPERT = 4
 */
enum DIFFICULTY
{
    INVALID_DIFFICULTY = -1,
    EASY = 1,
    NORMAL = 2,
    ADVANCED = 3,
    EXPERT = 4
}

/**
 * Checks "if (client <= 0 || client > MaxClients || !IsClientInGame(client))"
 */
stock bool IsValidClient(int client, bool replaycheck = true)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
        return false;
    if (replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
        return false;
    return true;
}

stock bool EasyOrNormal(ConVar Difficulty)
{
	return GetDifficulty(Difficulty) == EASY || GetDifficulty(Difficulty) == NORMAL;
}

stock bool AdvancedOrExpert(ConVar Difficulty)
{
    return GetDifficulty(Difficulty) == ADVANCED || GetDifficulty(Difficulty) == EXPERT;
}

/*
 * Returns the current difficulty as a easy to read enum value
 *
 * @param   difficultyConvar ConVar object of z_difficulty
 * @return	Current difficulty enum value
 * @error	Will return "INVALID_DIFFICULTY" if difficulty is invalid
 */
stock DIFFICULTY GetDifficulty(ConVar difficultyConvar)
{
    char cDifficulty[16];
    difficultyConvar.GetString(cDifficulty, sizeof(cDifficulty));

    switch(CharToLower(cDifficulty[0])) // Convert the first character to lowercase
    {
        case 'e':
            return EASY;
        case 'n':
            return NORMAL;
        case 'h':
            return ADVANCED;
        case 'i':
            return EXPERT;
        default: {
            LogError("Could not find a valid difficulty!!");
            return INVALID_DIFFICULTY;
        }
    }
}

stock bool CheckGamemode(ConVar gamemode, char[] strGamemode)
{
    char cGamemode[16];
    gamemode.GetString(cGamemode, sizeof(cGamemode));
    return StrEqual(cGamemode, strGamemode, false);
}

stock bool InflictorCheck(int inflictor, int attacker)
{
    if (IsValidClient(inflictor) && attacker == inflictor)
        return true;

    return false;
}

stock bool IsZombieClass(int client, L4D2ZombieClassType class)
{
	return L4D2_GetPlayerZombieClass(client) == class;
}

stock bool IsOnFire(int client)
{
    if (!IsValidClient(client))
	    return false;

    return L4D_IsPlayerOnFire(client);
}

/**
 * Returns if this player is on the infected team
 */
stock bool OnInfectedTeam(int client)
{
    if (!IsValidClient(client))
		return false;

    return L4D_GetClientTeam(client) == L4DTeam_Infected;
}

/**
 * Returns if this player in on the survivor team
 */
stock bool OnSurvivorTeam(int client)
{
    if (!IsValidClient(client))
		return false;

    return L4D_GetClientTeam(client) == L4DTeam_Survivor;
}

stock bool IsTank(int client)
{
    if (!IsValidClient(client))
		return false;

    return OnInfectedTeam(client) && L4D2_GetPlayerZombieClass(client) == L4D2ZombieClass_Tank;
}

stock bool IsCharger(int client)
{
    if (!IsValidClient(client))
		return false;

    return OnInfectedTeam(client) && L4D2_GetPlayerZombieClass(client) == L4D2ZombieClass_Charger;
}