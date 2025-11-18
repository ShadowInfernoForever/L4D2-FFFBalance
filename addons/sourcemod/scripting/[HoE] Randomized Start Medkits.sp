#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

new Float:SurvivorStart[3]

public Plugin:myinfo = 
{
	name = "[L4D2] No Safe Room Medkits",
	author = "Crimson_Fox",
	description = "Replaces safe room random healing items",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1032403"
}

public OnPluginStart()
{
	CreateConVar("l4d2_nsrm_version", PLUGIN_VERSION,"No Safe Room Medkits Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post)
	//Look up what game we're running,
	decl String:game[64]
	GetGameFolderName(game, sizeof(game))
	//and don't load if it's not L4D2.
	if (!StrEqual(game, "left4dead2", false)) SetFailState("Plugin supports Left 4 Dead 2 only.")
}

public Action:Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	// Set a timer to call the functions after 1 second
    CreateTimer(1.0, Timer_RoundStart, event, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_RoundStart(Handle:event)
{
    // Find where the survivors start so we know which medkits to replace
    FindSurvivorStart();
    // Replace the medkits with pills
    ReplaceMedkits();

    // Stop the timer after executing the functions once
    return Plugin_Stop;
}

public FindSurvivorStart()
{
	new EntityCount = GetEntityCount()
	new String:EdictClassName[128]
	new Float:Location[3]
	//Search entities for either a locked saferoom door,
	for (new i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
			if ((StrContains(EdictClassName, "prop_door_rotating_checkpoint", false) != -1) && (GetEntProp(i, Prop_Send, "m_bLocked")==1))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location)
				SurvivorStart = Location
				return
			}
		}
	}
	//or a survivor start point.
	for (new i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
			if (StrContains(EdictClassName, "info_survivor_position", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location)
				SurvivorStart = Location
				return
			}
		}
	}
}

public ReplaceMedkits()
{
	new EntityCount = GetEntityCount()
	new String:EdictClassName[128]
	new Float:NearestMedkit[3]
	new Float:Location[3]
	decl String:randwepMsg[][64] = {
    "weapon_pain_pills_spawn",
    "weapon_adrenaline_spawn",
    "weapon_defibrillator_spawn",
    "weapon_first_aid_kit_spawn",
    };

	//Look for the nearest medkit from where the survivors start,
	for (new i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location)
				//If NearestMedkit is zero, then this must be the first medkit we found.
				if ((NearestMedkit[0] + NearestMedkit[1] + NearestMedkit[2]) == 0.0)
				{
					NearestMedkit = Location
					continue
				}
				//If this medkit is closer than the last medkit, record its location.
				if (GetVectorDistance(SurvivorStart, Location, false) < GetVectorDistance(SurvivorStart, NearestMedkit, false)) NearestMedkit = Location
			}
		}
	}
	//then replace the medkits near it with pain pills.
	for (new i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location)
				if (GetVectorDistance(NearestMedkit, Location, false) > 1)
				{
					new index = CreateEntityByName(randwepMsg[GetRandomInt(0, sizeof(randwepMsg) - 1)])
					if (index != -1)
					{
						new Float:Angle[3]
						GetEntPropVector(i, Prop_Send, "m_angRotation", Angle)
						TeleportEntity(index, Location, Angle, NULL_VECTOR)
						DispatchSpawn(index)
					}				
					AcceptEntityInput(i, "Kill")
				}
			}
		}
	}
}
