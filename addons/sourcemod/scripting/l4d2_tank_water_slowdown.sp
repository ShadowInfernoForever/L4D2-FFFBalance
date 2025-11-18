#define PLUGIN_VERSION "1.1.2"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin:myinfo =
{
    name = "L4D2 Water Slowdown",
    author = "Machine",
    description = "Automated Water Slowdown",
    version = PLUGIN_VERSION,
    url = "www.AlliedMods.net"
};

#define F1_xy(%1,%2)        Pow( GetConVarFloat( Factor[%2 % 2]) , float(GetEntProp(%1, Prop_Send, "m_nWaterLevel")) * 0.1* %2 )

ConVar Factor[2];
Handle h_timer[32];

public OnPluginStart()
{
    Factor[0] = CreateConVar("X_Water_Factor_Survivor" , "0.68" ,"Water Resistance Factor For Survivor [1.0 : Disable effects]", FCVAR_NOTIFY, true ,0.6 ,true ,1.0);
    Factor[1] = CreateConVar("X_Water_Factor_Infected" , "0.68" ,"Water Resistance Factor For Infected [1.0 : Disable effects]", FCVAR_NOTIFY, true ,0.6 ,true ,1.0);
}

public OnClientPostAdminCheck(client)
{
    h_timer[client] = CreateTimer(0.5 ,Timer_Refresh_Speed , client ,TIMER_REPEAT);
}

public Action Timer_Refresh_Speed(Handle Timer ,any client)
{
    SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", F1_xy(client , GetClientTeam(client)) );
    return Plugin_Continue;
}

public OnClientDisconnect(client)
{
    delete h_timer[client];   
} 