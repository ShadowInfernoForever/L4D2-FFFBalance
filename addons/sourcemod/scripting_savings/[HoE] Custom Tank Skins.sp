#pragma semicolon 1

#include <sourcemod>  
#include <sdktools>

public Plugin myinfo = 
{
	name = "Custom Tank Skins",
	author = "Claucker",
	description = "Adds new tank skins",
	version = "0.1",
	url = ""
}

// INFECTED
//#define MODEL_HELLTANK		    "models/infected/helltank/helltank.mdl"
#define MODEL_METRO		        "models/infected/metro/metro.mdl"
#define MODEL_GONOME		    "models/infected/gonome/gonome.mdl"
//#define MODEL_NAPAD		        "models/infected/napad/napad.mdl"
//#define MODEL_NEMESIS	        "models/infected/nemesis/nemesis.mdl"
//#define MODEL_FOOTBALL		    "models/infected/footballtank/hulk.mdl"
//#define MODEL_GUNKTANK		    "models/infected/gunk/gulk.mdl"

int g_index = 0;

char g_tankModels[][] = { 

 //MODEL_HELLTANK,
 MODEL_METRO,
 MODEL_GONOME
// MODEL_NAPAD,	
// MODEL_NEMESIS,  
// MODEL_FOOTBALL,
//MODEL_GUNKTANK	
 
};

const int g_ammount = sizeof( g_tankModels );

public void PrecacheTankModelList()
{
	//Precache TANKS
	for (int i = 0; i < g_ammount; i++ )
	{
		PrecacheCustomModels( g_tankModels[ i ] );
	}
}

public void PrecacheCustomModels( const char[] MODEL )
{
	if (!IsModelPrecached(MODEL))
		PrecacheModel(MODEL, false);
}


public Action TankSpawn( Event event, const char[] name, bool dontBroadcast ) 
{
	int client =  GetClientOfUserId(GetEventInt(event, "userid")); 
	
	SetEntityModel( client, g_tankModels[ g_index ] );
	g_index++;
	
	g_index = ( g_index % ( g_ammount ) );
}

public OnPluginStart()  
{
	HookEvent("tank_spawn", TankSpawn);
}

public OnMapStart()
{
	//MODELS
	PrecacheTankModelList();
}