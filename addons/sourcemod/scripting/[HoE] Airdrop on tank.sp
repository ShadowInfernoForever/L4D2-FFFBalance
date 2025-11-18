#pragma semicolon 1
//#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define SOUND_CLEARED "ui/pickup_misc42.wav"
#define SOUND_RADIO "insanity/z_radiosupply.mp3"
#define SOUND_RADIO2 "insanity/z_radiosupply2.mp3"
#define sColor        "255,50,50"

enum struct GlobalSettings
{
	float maxheight;	
	
	char usestring[64];
	
	bool skyboxonly;
}

GlobalSettings g_Globals;

new Handle:cTankChance;
new Handle:cSkyboxOnly;

native bool CreateAirdrop( const float vOrigin[3], const float vAngles[3], int initiator = 0, bool trace_to_sky = true );

public void OnPluginStart()
{
	HookEvent("tank_killed", tank_killed);

	cTankChance = CreateConVar("airdroptank_chance", "50", "Chance de dropear un supply drop al matar un tank");
	cSkyboxOnly = CreateConVar("airdroptank_skybox_only", "1", "Habilitar skybox?");

}

public void OnMapStart()
{
	PrecacheSound(SOUND_CLEARED);
	PrecacheSound(SOUND_RADIO);
	PrecacheSound(SOUND_RADIO2);
}

stock bool GetSkyOrigin( const float vOrigin[3], float out[3], bool skyonly = false )
{	
	Handle ray = TR_TraceRayFilterEx(vOrigin, view_as<float>({-89.0, 0.0, 0.0}), MASK_ALL, RayType_Infinite, __TraceFilter);

	g_Globals.skyboxonly = GetConVarInt(cSkyboxOnly);
	
	if ( !TR_DidHit(ray) )
	{
		delete ray;
		return false;
	}
	
	if ( skyonly && !(TR_GetSurfaceFlags(ray) & (SURF_SKY | SURF_SKY2D)) )
	{
		delete ray;
		return false;
	}
	
	float vVec[3];
	TR_GetEndPosition(vVec, ray);

	if ( g_Globals.maxheight != 0.0 && GetVectorDistance(vOrigin, vVec) >= g_Globals.maxheight )
	{
		vVec[2] = vOrigin[2] + g_Globals.maxheight;
	}
	else
	{
		vVec[2] -= 20.0;
	}
	
	out = vVec;
	delete ray;
	return true;
}

public bool __TraceFilter( int entity, int mask )
{
	return entity <= 0;
}

public void tank_killed( Event event, const char[] name, bool noReplicate )
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if ( !client || !IsClientInGame(client) )
		return;
		
	float vOrigin[3], vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	if ( !GetSkyOrigin(vOrigin, vOrigin, g_Globals.skyboxonly) )
		return;

	if( GetRandomInt(1, 100) <= GetConVarInt(cTankChance) )
		return;	

	decl String:randMelonMsg[][] = {
            {"{red} ➤ [Radio]:  {default}¡ Transmisión Delta 07 !"}, 
            {"{red} ➤ [Radio]: {default}¡ Transmisión Bravo 001 !"},
            {"{red} ➤ [Radio]: {default}¡ Transmisión Charlie 05!"},
            {"{red} ➤ [Radio]: {default}¡ Transmisión Delta 50 !"},
    };

   
	
	CreateAirdrop(vOrigin, vAngles, .trace_to_sky = true);

	//CPrintToChatAll( randMelonMsg[GetRandomInt(0, sizeof(randMelonMsg) - 1)], client );

	decl String:randsound[][] = {
            {"insanity/z_radiosupply.mp3"},
            {"insanity/z_radiosupply2.mp3"},
    };

	for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {
            EmitSoundToClient(i, SOUND_CLEARED);
            //EmitSoundToClient(i, randsound[GetRandomInt(0, sizeof(randsound) - 1)]);
        }
        
    }

}
