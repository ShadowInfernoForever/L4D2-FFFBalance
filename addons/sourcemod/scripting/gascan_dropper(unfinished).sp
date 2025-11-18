#include <sourcemod>
#include <sdktools>
#include <colors>
#define ITEM_COOLDOWN 5.0

enum GasCanItemType
{
    GAS_CAN,
    PROPANE_TANK,
    OXYGEN_TANK
}

new g_PlayerCooldown[MAXPLAYERS + 1];
new g_PlayerItem[MAXPLAYERS + 1];

public void OnPluginStart()
{
    HookUserMessage(GetUserMessageId("UserCmd"), OnPlayerRunCmd);
}

public Action OnPlayerRunCmd(int client, CUserCmd &cmd)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Continue;

    // Retrieve button states
    int buttons = cmd.buttons;

    // Check if middle mouse (IN_ATTACK2) is pressed
    if (buttons & IN_ATTACK2 && g_PlayerCooldown[client] < GetGameTime())
    {
        g_PlayerCooldown[client] = GetGameTime() + ITEM_COOLDOWN;

        float origin[3];
        GetClientAbsOrigin(client, origin);

        float angles[3];
        GetClientAbsAngles(client, angles);

        char itemName[64];
        switch (g_PlayerItem[client])
        {
            case GAS_CAN:
                StrCopy(itemName, sizeof(itemName), "weapon_gascan");
                break;
            case PROPANE_TANK:
                StrCopy(itemName, sizeof(itemName), "weapon_propane_tank");
                break;
            case OXYGEN_TANK:
                StrCopy(itemName, sizeof(itemName), "weapon_oxygentank");
                break;
            default:
                return Plugin_Continue; // Invalid item type
        }

        int entity = CreateEntityByName(itemName);
        if (IsValidEntity(entity))
        {
            TeleportEntity(entity, origin, angles, NULL_VECTOR);
            DispatchSpawn(entity);
        }
    }

    return Plugin_Continue;
}
