#include <sourcemod>
#include <gunxpmod>

public Plugin:myinfo =
{
    name = "Infected Punisher",
    author = "xbatista",
    description = "none",
    version = "1.0",
    url = "www.laikiux.lt"
};

#define EXTRA_DAMAGE 0.15 // ~ 15%

#define ITEM_COST 400 // 400 Xp that item costs

#define EXTRA_GUN "weapon_rifle_ak47"

new bool:g_ItemEnabled[MAXPLAYERS + 1];

public OnPluginStart()
{
	// We are registering item
	register_gxm_item("AK-47 Common Destroyer", "Deals more damage for common infected", ITEM_COST, TEAM_SURVIVOR)

	HookEvent("infected_hurt", Event_InfectedHurtPre, EventHookMode_Pre);
}

// Called when item/unlock was selected by menu
public GXM_Item_Enabled(client)
{
	g_ItemEnabled[client] = true;
}

// Take the item/unlock from the player
public OnClientDisconnect(client)
{
	if ( IsClientInGame(client) )
	{
		g_ItemEnabled[client] = false;
	}
}

public Event_InfectedHurtPre (Handle:event, const String:name[], bool:dontBroadcast)
{
	new Att = GetClientOfUserId(GetEventInt( event, "attacker" ) );

	if ( !IsValidAlive(Att) )
		return;

	decl String:szWeapon[32];

	GetClientWeapon( Att, szWeapon, sizeof(szWeapon) );

	if ( GetClientTeam(Att) == TEAM_SURVIVOR && StrEqual( szWeapon, EXTRA_GUN ) )
	{
		new iEntid = GetEventInt( event, "entityid");
		new aDmg = GetEventInt(event,"amount");
		new dDmg = RoundToNearest( aDmg * EXTRA_DAMAGE);

		SetEntProp( iEntid, Prop_Data, "m_iHealth", GetEntProp( iEntid, Prop_Data, "m_iHealth")-dDmg );
	}
}