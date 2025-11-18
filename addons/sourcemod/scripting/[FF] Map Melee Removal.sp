#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#define NUM_MELEE_WEAPONS 13

public Plugin:myinfo = 
{
	name = "[FF] 80% Melee Removal",
	author = "ShadowInferno",
	description = "Removes 80% melees in the map",
	version = "1.0",
	url = ""
}

// List of melee weapon entity names
new String:meleeWeapons[NUM_MELEE_WEAPONS][25] =
{
    "weapon_melee_spawn",
    "weapon_chainsaw_spawn",
    "cricket_bat",
    "crowbar",
    "baseball_bat",
    "electric_guitar",
    "fireaxe",
    "katana",
    "tonfa",
    "golfclub",
    "machete",
    "frying_pan",
    "riotshield"
};

public void OnPluginStart()
{
    // Hook the map change event
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post)
}

public Action:Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
    // Delay execution to ensure entities are fully loaded
    CreateTimer(1.0, Timer_RemoveMeleeWeapons);
}

public Action Timer_RemoveMeleeWeapons(Handle timer)
{
    int meleeEntities[256]; // Arbitrary size, adjust as needed
    int count = 0;

    // Find all melee weapons
    for (int i = 1; i <= 2048; i++) // Iterate through possible entity indices
    {
        if (IsValidEntity(i))
        {
            char classname[25];
            GetEntityClassname(i, classname, sizeof(classname));
            
            for (int j = 0; j < NUM_MELEE_WEAPONS; j++)
            {
                if (StrEqual(classname, meleeWeapons[j]))
                {
                    meleeEntities[count++] = i;
                    break;
                }
            }
        }
    }

    // Calculate the number of melee weapons to remove
    int toRemove = RoundToNearest(count * 0.8); // Correct function for rounding
    
    // Randomly remove the melee weapons
    for (int i = 0; i < toRemove && count > 0; i++)
    {
        int index = GetRandomInt(0, count - 1); // Use GetRandomInt to get a random index
        RemoveMeleeWeapon(meleeEntities[index]);
        
        // Remove the weapon from the array and adjust count
        meleeEntities[index] = meleeEntities[--count];
    }
    
    return Plugin_Stop; // Use Action_Continue instead of Action_Stop
}

void RemoveMeleeWeapon(int entity)
{
    // Remove the entity
    if (IsValidEntity(entity))
    {
        // This function will remove the entity from the game
        AcceptEntityInput(entity, "Kill"); // Kill the entity to remove it
    }
}