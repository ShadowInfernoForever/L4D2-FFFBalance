#pragma semicolon 1
#include <sourcemod>  
#include <sdktools>   
#include <sdkhooks>
#include <colors>

public Plugin myinfo = {
 name = "[L4D2] Vote Display in Chat",
 author = "",
 description = "Displays colored publicity as chat message",
 version = "1.0",
 url = " ><> "
};

public void OnPluginStart()
{
    // When vote start, vote starter and target made vote in same tick.
    HookEvent("vote_started", vote_started); // issue #L4D_vote_kick_player
    HookEvent("vote_cast_yes", vote_started);
    HookEvent("vote_cast_no", vote_started);
    HookEvent("vote_failed", vote_started);
    HookEvent("vote_passed", vote_started); // details #L4D_vote_passed_kick_player
}

public void vote_started(Event event, const char[] name, bool dontBroadcast)
{
    static int tick = 0;
    static int target = 0;

    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    decl String:initiatorName[MAX_NAME_LENGTH];
    GetClientName(client, initiatorName, sizeof(initiatorName));



    if(StrEqual(name, "vote_started", false))
    {
        char buffer[30];
        event.GetString("issue", buffer, sizeof(buffer), " ");

        if(StrEqual(buffer, "#L4D_vote_kick_player", false))
        {
            tick = GetGameTickCount();
            CPrintToChatAllEx(client, "<{green}%s{default}> {teamcolor}Inició una votación", initiatorName);
        }
        return;
    }
    else if(StrEqual(name, "vote_passed", false))
    {
        char buffer[30];
        event.GetString("details", buffer, sizeof(buffer), " ");

        if(StrEqual(buffer, "#L4D_vote_passed_kick_player", false))
        {
            //KickClient(GetClientOfUserId(target), "You have been voted off");
            CreateTimer(10.0, delay, target);
        }

        //return;
    }
    else if(StrEqual(name, "vote_cast_yes", false))
    {
        if(GetGameTickCount() == tick)
        {
            target = GetClientUserId(event.GetInt("entityid")); // If vote starter vote itself
            CPrintToChatAllEx(client, "<{green}%s{default}> {teamcolor}Votó que {olive}SI", initiatorName);
        }

        return;
    }
    else if(StrEqual(name, "vote_cast_no", false))
    {
        if(GetGameTickCount() == tick)
        {
            target = GetClientUserId(event.GetInt("entityid"));
            CPrintToChatAllEx(client, "<{green}%s{default}> {teamcolor}Votó que {olive}NO", initiatorName);
        }

        return;
    }

    target = 0;
}


public Action delay(Handle timer, any userid)
{
    int target = GetClientOfUserId(userid);

    // Works only if client is still in server
    if(target && IsClientConnected(target) && !IsClientInKickQueue(target))
    {
        KickClient(target, "You have been voted off");
    }

    return Plugin_Continue;
} 