#include <sourcemod>
#include <sdktools>
#include <gunxpmod>
#include <colors>

#define PLUGIN_VERSION "1.1"

#define MENU_DISPLAY_TIME 30

public Plugin:myinfo =
{
    name = "Gun Xp Mod Shop",
    author = "xbatista",
    description = "Shop to buy items",
    version = PLUGIN_VERSION,
    url = "www.laikiux.lt"
};

new const String:TEAM_NAMES[][] = {
	"None",
	"None",
	"Survivor",
	"Infected"
}

#define MAX_UNLOCKS 25
#define MAX_UNLOCKS_NAME_SIZE 64
#define MAX_UNLOCKS_DESC_SIZE 128

new g_NumItems;

//new Handle:g_ItemBought = INVALID_HANDLE;

new bool:g_PlayerItem[MAXPLAYERS + 1][MAX_UNLOCKS];

new Handle:g_ItemID[MAX_UNLOCKS] = INVALID_HANDLE;
new g_ItemCost[MAX_UNLOCKS];
new g_ItemTeam[MAX_UNLOCKS];
new String:g_ItemName[MAX_UNLOCKS][MAX_UNLOCKS_NAME_SIZE]
new String:g_ItemDesc[MAX_UNLOCKS][MAX_UNLOCKS_DESC_SIZE]

public OnPluginStart()
{
	CreateConVar("gunxpmod_shop", PLUGIN_VERSION, "Gun Xp Mod Shop", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegConsoleCmd("say", Say_Command);
}

public OnClientPutInServer(client)
{
	if ( IsValidClient(client) )
	{
		for(new i = 0; i < MAX_UNLOCKS; i++) 
		{
			g_PlayerItem[client][i] = false;
		}
	}
}

public Action:Say_Command(client, args)
{
	if ( !IsValidClient(client) )
		return Plugin_Continue;
	
	decl String:Text[192];
	decl String:szArg1[16]
	GetCmdArgString(Text, sizeof(Text));

	StripQuotes(Text)

	BreakString(Text, szArg1, sizeof(szArg1))
	
	if( StrEqual(szArg1, "!tienda") || StrEqual(szArg1, "tienda") )
	{
		MainUnlockMenu(client);
	
		return Plugin_Handled;
	}
	
	return Plugin_Continue
}
public MainUnlockMenu(client)
{
	decl String:szMsg[64];
	decl String:szItems[512]
	new GetXp = get_p_xp( client );
	
	Format(szMsg, sizeof( szMsg ), "Unlocks Shop : [XP - %d]", GetXp );
	new Handle:menu = CreateMenu(UnlockMenu);

	SetMenuTitle(menu, szMsg);
	
	for (new item_id = 1; item_id < g_NumItems + 1; item_id++)
	{
		if( GetXp < g_ItemCost[item_id] ) 
		{
			if( g_PlayerItem[client][item_id] ) 
			{
				Format(szItems, sizeof( szItems ), "%s - (Bought)", g_ItemName[item_id], g_ItemCost[item_id] )

				AddMenuItem(menu, "class_id", szItems, ITEMDRAW_DISABLED)
			}
			else
			{
				Format(szItems, sizeof( szItems ), "%s - (Need Xp %d) - Not Bought", g_ItemName[item_id], g_ItemCost[item_id] )

				AddMenuItem(menu, "class_id", szItems, ITEMDRAW_DISABLED)
			}
		}
		else if ( GetClientTeam(client) != g_ItemTeam[item_id] )
		{
			Format(szItems, sizeof( szItems ), "%s - (Not Bought) Team: %s", g_ItemName[item_id], g_ItemCost[item_id], TEAM_NAMES[g_ItemTeam[item_id]] )

			AddMenuItem(menu, "class_id", szItems, ITEMDRAW_DISABLED)
		}
		else if ( g_PlayerItem[client][item_id] )
		{
			Format(szItems, sizeof( szItems ), "%s - (Bought)", g_ItemName[item_id], g_ItemCost[item_id] )

			AddMenuItem(menu, "class_id", szItems, ITEMDRAW_DISABLED)
		}
		else
		{
			Format(szItems, sizeof( szItems ), "%s - (Xp %d) - Not Bought", g_ItemName[item_id], g_ItemCost[item_id] )

			AddMenuItem(menu, "class_id", szItems)
		}

	}

	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, MENU_DISPLAY_TIME );
}
public UnlockMenu(Handle:menu, MenuAction:action, client, item_id)
{
	if( action == MenuAction_Select )
	{	
		new fixed_id = item_id + 1;
		
		new GetXp = get_p_xp( client );
		new iCost = g_ItemCost[fixed_id];
		new Handle:plugin_id = g_ItemID[fixed_id];
		new Function:func = GetFunctionByName (plugin_id, "GXM_Item_Enabled");
		
		if( GetXp >= iCost )
		{
			Call_StartFunction(plugin_id, func);
			Call_PushCell( client );
			Call_Finish();
			
			g_PlayerItem[client][fixed_id] = true;
			
			set_p_xp( client, GetXp - iCost );
			
			CPrintToChat(client, "{default}Item Bought Successfully, Item: {blue}%s{default}.", g_ItemName[fixed_id] ) 
			CPrintToChat(client, "{default}Description: {blue}%s{default}.", g_ItemDesc[fixed_id] ) 
		}
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
}

public register_item_gxm(Handle:item_index, const String:item_name[], const String:item_desc[], item_cost, item_team)
{
	if( g_NumItems == MAX_UNLOCKS )
	{
		return -2;
	}
	
	g_NumItems++;
	g_ItemID[g_NumItems] = item_index;
	Format(g_ItemName[g_NumItems], MAX_UNLOCKS_NAME_SIZE , item_name)
	Format(g_ItemDesc[g_NumItems], MAX_UNLOCKS_DESC_SIZE, item_desc)
	g_ItemCost[g_NumItems] = item_cost;
	g_ItemTeam[g_NumItems] = item_team;
	
	return g_NumItems;
}