#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

#define Tracer "weapon_tracers_incendiary"

new Float:g_fClientDelay[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Awp and Scout Tracers",
	author = "Edited by Shadow",
	description = "Gives the Snipers AWP and SCOUT, incendiary tracers. for cool effect :)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	HookEvent("bullet_impact", OnBulletImpact);
}

public void OnMapStart()
{
	PrecacheParticle(Tracer);

	for (new i = 1; i < sizeof(g_fClientDelay); i++)
	{
		g_fClientDelay[i] = 0.0;		// Reset delay
	}

}

public OnClientDisconnect_Post(client)
{
	g_fClientDelay[client] = 0.0;		// Reset delay
}

public OnBulletImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    new Float:_game_time = GetGameTime();
    
    if (g_fClientDelay[client] > _game_time) return; // Is delayed? stop

    decl Float:bulletDestination[3];
    bulletDestination[0] = GetEventFloat(event, "x");
    bulletDestination[1] = GetEventFloat(event, "y");
    bulletDestination[2] = GetEventFloat(event, "z");

    decl Float:bulletOrigin[3];
    GetClientEyePosition(client, bulletOrigin);

    new Float:distance = GetVectorDistance(bulletOrigin, bulletDestination);
    new Float:percentage = 0.4 / (distance / 100);
    
    decl Float:newBulletOrigin[3];
    newBulletOrigin[0] = bulletOrigin[0] + ((bulletDestination[0] - bulletOrigin[0]) * percentage);
    newBulletOrigin[1] = bulletOrigin[1] + ((bulletDestination[1] - bulletOrigin[1]) * percentage) - 0.08;
    newBulletOrigin[2] = bulletOrigin[2] + ((bulletDestination[2] - bulletOrigin[2]) * percentage);
    
    //CreateBulletTrace(newBulletOrigin, bulletDestination, fSpeed, fStartWidth, fEndWidth, sRGB);
    
    /***  Make us only process bolt action snipers  ***/
    new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (weapon != -1)
    {
        decl String:g_szWeapon[32];
        GetEdictClassname(weapon, g_szWeapon, sizeof(g_szWeapon));
        if ( StrEqual(g_szWeapon, "weapon_sniper_awp", false) || StrEqual(g_szWeapon, "weapon_sniper_scout", false))
        {
        	DisplayRicochet(newBulletOrigin, bulletDestination);
            return;
        }
    }
    /***  -------------------------------  ***/
    
    g_fClientDelay[client] = _game_time + 0.1; // Setting delay. To avoid lagging because of entity spam
}

void DisplayRicochet(float vStart[3], float vEnd[3])
{  
 	char szName[16];
	int iEntity = CreateEntityByName("info_particle_target");
	
	if (iEntity == -1)
		return;
	
	Format(szName, sizeof szName, "IInfo%d", iEntity);
	DispatchKeyValue(iEntity, "targetname", szName);	
	
	TeleportEntity(iEntity, vEnd, NULL_VECTOR, NULL_VECTOR); 
	ActivateEntity(iEntity); 
	
	SetVariantString("OnUser4 !self:Kill::1.1:-1");
	AcceptEntityInput(iEntity, "AddOutput");
	AcceptEntityInput(iEntity, "FireUser4");
	
	iEntity = CreateEntityByName("info_particle_system");
	
	if (iEntity == -1)
		return;
	
	DispatchKeyValue(iEntity, "effect_name", Tracer);
	DispatchKeyValue(iEntity, "cpoint1", szName);
	
	TeleportEntity(iEntity, vStart, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(iEntity);
	ActivateEntity(iEntity); 
	
	AcceptEntityInput(iEntity, "Start");
	
	SetVariantString("OnUser4 !self:Kill::1.1:-1");
	AcceptEntityInput(iEntity, "AddOutput");
	AcceptEntityInput(iEntity, "FireUser4");
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;

	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}