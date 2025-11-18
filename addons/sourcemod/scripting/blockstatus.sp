#include <sourcemod>
#pragma semicolon 1

ConVar g_hCommandAccess;
public void OnPluginStart()
{
    g_hCommandAccess = CreateConVar("l4d_status_commands_access_flag", "z", "Players with these flags have access to use status command. (Empty = Everyone, -1: Nobody)", FCVAR_NOTIFY);
    
    RegConsoleCmd("status", Command_Block);
}

public Action Command_Block(int client, int args)
{
    if (client == 0 ) //server console
        return Plugin_Continue;

    decl String:person[128];

    GetClientName( client, person, sizeof(person) );
    
    if(HasAccess(client) == false)
    {
        //PrintToChatAll(" %s    INTENTO USAR EL COMANDO STATUS", person);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

bool HasAccess (int client)
{
    char g_sAcclvl[16];
    g_hCommandAccess.GetString(g_sAcclvl,sizeof(g_sAcclvl));
    
    // no permissions set
    if (strlen(g_sAcclvl) == 0)
        return true;

    else if (StrEqual(g_sAcclvl, "-1"))
        return false;

    // check permissions
    int flag = GetUserFlagBits(client);
    if ( flag & ReadFlagString(g_sAcclvl) )
    {
        return true;
    }

    return false;
} 