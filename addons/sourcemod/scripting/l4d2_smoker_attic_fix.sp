#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define ARRAY_SIZE 6
#define SEQUENCE_TONGUE 27
#define ACTIVITY_TONGUE 27

public Plugin myinfo =
{
    name = "Smoker Antic Fix",
    author = "Shadow",
    description = "Fixes Smoker Animation on higher difficulties",
    version = "2",
    url = ""
}

public void OnPluginStart() {
    HookEvent("ability_use", OnAbilityUse, EventHookMode_Post);
}

public void OnAbilityUse(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    char abilityName[64];
    
    GetEventString(event, "ability", abilityName, sizeof(abilityName));
    int context = event.GetInt("context");

    if (client > 0 && strcmp(abilityName, "ability_tongue", false) == 0 && context == 1) {
        // Get and set the model for the player
        new String:model[128];
        GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
        SetEntityModel(client, model);

        // Set animation and properties
        SetEntProp(client, Prop_Send, "m_nSequence", SEQUENCE_TONGUE);
        SetEntProp(client, Prop_Send, "m_NetGestureActivity", ACTIVITY_TONGUE);
        float currentTime = GetGameTime() + 6;
        SetEntPropFloat(client, Prop_Send, "m_NetGestureStartTime", 6);
    }
}