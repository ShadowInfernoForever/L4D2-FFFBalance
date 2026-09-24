#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

//  Colors
#define whiteColor {255,255,255,255} // White

new Sprite1;

new Handle:TrailsProjectileEnabled;

public Plugin:myinfo =
{
    name = "Trails_Projectile",
    author = "Fredd, Mister Game Over",
    description = "Trails Projectile",
    version = "1.0",
    url = "https://vk.com/club151027520"
}

public OnPluginStart()
{
	TrailsProjectileEnabled	=	CreateConVar("trails_enables",	"1",	"Enables/Disables plugin",	FCVAR_NOTIFY|FCVAR_PLUGIN);		
}
    
public OnMapStart()
{
    Sprite1 = PrecacheModel("materials/sprites/laserbeam.vmt");    
}
		
public OnEntityCreated(Entity, const String:Classname[])
{
	if(GetConVarInt(TrailsProjectileEnabled) != 1)
		return;
		
	// Cambiamos la duración de la estela de Float:2.0 a Float:4.0 (2 segundos más)
	
	if(strcmp(Classname, "pipe_bomb_projectile") == 0)
    {
		TE_SetupBeamFollow(Entity, Sprite1, 0, Float:4.0, Float:1.5, Float:1.5, 1, whiteColor);  
		TE_SendToAll();                                 
    }
	else if(strcmp(Classname, "molotov_projectile") == 0)
    {
		TE_SetupBeamFollow(Entity, Sprite1, 0, Float:4.0, Float:1.5, Float:1.5, 1, whiteColor);
		TE_SendToAll();                                 
    }
	else if(strcmp(Classname, "vomitjar_projectile") == 0)
    {
		TE_SetupBeamFollow(Entity, Sprite1, 0, Float:4.0, Float:1.5, Float:1.5, 1, whiteColor);
		TE_SendToAll();                                 
    }          
	else if(strcmp(Classname, "grenade_launcher_projectile") == 0)
    {
		TE_SetupBeamFollow(Entity, Sprite1, 0, Float:4.0, Float:1.5, Float:1.5, 1, whiteColor);
		TE_SendToAll();                                                             
    }    
	else if(strcmp(Classname, "tank_rock") == 0)
    {
		TE_SetupBeamFollow(Entity, Sprite1, 0, Float:4.0, Float:1.5, Float:1.5, 1, whiteColor);
		TE_SendToAll();                                 
    }        
	return;
}