#include <sourcemod>
#include <autoexecconfig>
#include <steamworks>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.6"

#define TEAM_SURVIVORS 2
#define MAXCLIENTS 64 

public Plugin myinfo = 
{
    name = "[FF] Steam Group FF only",
    author = "Shadow",
    description = "Restricts friendly fire to group members",
    version = PLUGIN_VERSION,
    url = ""
}

ConVar g_hGroupIds;
int g_iGroupIds[100];
int g_iNumGroups;
new bool:g_isGroupMember[MAXPLAYERS + 1];


public void OnPluginStart()
{
    AutoExecConfig_SetFile("plugin.steamgrouprestrict");

    g_hGroupIds = AutoExecConfig_CreateConVar("sm_steamgrouprestrict_groupids", "https://steamcommunity.com/groups/asado-con-los-pibe", "List of group ids separated by a comma.", FCVAR_PROTECTED);
    
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    g_hGroupIds.AddChangeHook(OnCvarChanged);
}

public void OnCvarChanged(Handle cvar, const char[] oldValue, const char[] newValue)
{
    if (cvar == g_hGroupIds)
    {
        RefreshGroupIds();
    }
}

void RefreshGroupIds()
{
    char sGroupIds[1024];
    g_hGroupIds.GetString(sGroupIds, sizeof(sGroupIds));
    
    char sGroupBuf[sizeof(g_iGroupIds)][12];
    int count = 0;
    int explodes = ExplodeString(sGroupIds, ",", sGroupBuf, sizeof(sGroupBuf), sizeof(sGroupBuf[]));
    
    for (int i = 0; i < explodes; i++)
    {
        TrimString(sGroupBuf[i]);
        int tmp = StringToInt(sGroupBuf[i]);
        if (tmp > 0)
        {
            g_iGroupIds[count] = tmp;
            count++;
        }
    }
    g_iNumGroups = count;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if (IsSurvivor(victim) && IsSurvivor(attacker))
    {
        if (!IsGroupMember(attacker))
        {
            damage = 0.0; // Prevent friendly fire
            return Plugin_Changed;
        }
    }
    return Plugin_Continue; 
}

bool:IsGroupMember(int client)
{
    int accountId = GetSteamAccountID(client);

    // Reset to false before checking
    g_isGroupMember[client] = false;

    // Query all groups
    for (int i = 0; i < g_iNumGroups; i++)
    {
        SteamWorks_GetUserGroupStatusAuthID(accountId, g_iGroupIds[i]);
    }

    // Return the current known state (may be updated asynchronously)
    return g_isGroupMember[client];
}

public int SteamWorks_OnClientGroupStatus(int accountId, int groupId, bool isMember, bool isOfficer)
{
    int client = GetClientOfAccountId(accountId);
    if (client != -1)
    {
        g_isGroupMember[client] = isMember; // Update the membership status
    }
    return 0;
}

int GetClientOfAccountId(int accountId)
{
    for (int i = 1; i <= MAXCLIENTS; i++)
    {
        if (IsClientConnected(i) && GetSteamAccountID(i) == accountId)
        {
            return i;
        }
    }
    return -1; // Not found
}

bool:IsValidClient(client) 
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

bool:IsSurvivor(client) 
{
    return (IsValidClient(client) && GetClientTeam(client) == TEAM_SURVIVORS);
}