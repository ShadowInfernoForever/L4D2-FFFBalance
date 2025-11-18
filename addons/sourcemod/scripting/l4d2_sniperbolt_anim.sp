#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
    name = "Survivor Sniper Bolt Animation",
    author = "Shadow",
    description = "Plays the shotgun bolt animation when firing Scout/AWP",
    version = "2",
    url = ""
};

public void OnPluginStart() {
    HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Post);
}

public void OnWeaponFire(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    char weaponName[64];
    
    GetEventString(event, "weapon", weaponName, sizeof(weaponName));
    if (client <= 0) return;

    // Define the properties
    int sequencePrimaryAttack = 27; // Replace with actual sequence index
    int activityPrimaryAttack = 6;  // Replace with actual activity index
    float currentTime = GetGameTime();

    if (strcmp(weaponName, "weapon_sniper_awp", false) == 0) {
        // Set properties for AWP
        SetEntProp(client, Prop_Send, "m_nSequence", sequencePrimaryAttack);
        SetEntProp(client, Prop_Send, "m_NetGestureActivity", activityPrimaryAttack);
        SetEntPropFloat(client, Prop_Send, "m_NetGestureStartTime", currentTime);
        // Use a timer to delay the execution
        CreateTimer(0.2, SetReloadEndProperties, client);
    }
    else if (strcmp(weaponName, "weapon_sniper_scout", false) == 0) {
        // Set properties for Scout
        SetEntProp(client, Prop_Send, "m_nSequence", sequencePrimaryAttack);
        SetEntProp(client, Prop_Send, "m_NetGestureActivity", activityPrimaryAttack);
        SetEntPropFloat(client, Prop_Send, "m_NetGestureStartTime", currentTime);
        // Use a timer to delay the execution
        CreateTimer(0.1, SetReloadEndProperties, client);
    }
}

// Timer callback function to set reload end properties
public Action SetReloadEndProperties(Handle timer, int client) {
    int sequenceReloadEnd = 28; // Replace with actual reload end sequence index
    int activityReloadEnd = 7;   // Replace with actual reload end activity index
    float currentTime = GetGameTime();
    
    SetEntProp(client, Prop_Send, "m_nSequence", sequenceReloadEnd);
    SetEntProp(client, Prop_Send, "m_NetGestureActivity", activityReloadEnd);
    SetEntPropFloat(client, Prop_Send, "m_NetGestureStartTime", currentTime);
    
    return Plugin_Continue;
}