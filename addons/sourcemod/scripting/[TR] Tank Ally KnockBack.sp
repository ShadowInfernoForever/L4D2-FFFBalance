#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

public Plugin:myinfo = 
{
    name = "[FF] Tank Ally Push",
    author = "Shadow",
    description = "Makes tanks push each other horizontally and vertically when punching fellow tank teammates.",
    version = "1.1",
    url = ""
}

#define TEAM_INFECTED 3

public void OnPluginStart()
{
    LoadTranslations("tankallyknockback.phrases");
    HookAllClients();
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void HookAllClients()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    // Valid clients
    if (!IsValidClient(victim) || !IsValidClient(attacker))
        return Plugin_Continue;

    // Both must be tanks in the infected team
    // Else survivors will push tanks XD, or vice versa
    if (IsTank(victim) && IsTank(attacker) &&
        GetClientTeam(victim) == TEAM_INFECTED &&
        GetClientTeam(attacker) == TEAM_INFECTED)
    {
        // Cancel damage
        damage = 0.0;

        // Apply push
        Smash(attacker, victim, 500.0, 1.4, 0.9);

        return Plugin_Handled;  // Damage fully blocked
    }

    return Plugin_Continue;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

bool IsTank(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

void Smash(int client, int target, float power, float powHor, float powVec)
{
    float HeadingVector[3];
    float AimVector[3];
    GetClientEyeAngles(client, HeadingVector);

    AimVector[0] = Cosine(DegToRad(HeadingVector[1])) * (power * powHor);
    AimVector[1] = Sine(DegToRad(HeadingVector[1])) * (power * powHor);

    float current[3];
    GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);

    float resulting[3];
    resulting[0] = current[0] + AimVector[0];
    resulting[1] = current[1] + AimVector[1];
    resulting[2] = power * powVec;

    if (!IsOnGround(target)) {
        resulting[2] += 300.0;
        resulting[0] += AimVector[0] * 0.5;
        resulting[1] += AimVector[1] * 0.5;
    }

    CPrintToChatAll("%T", "TankCatapult", LANG_SERVER, client, target);

    TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

bool IsOnGround(int entity)
{
    int flags = GetEntProp(entity, Prop_Send, "m_fFlags");
    return (flags & FL_ONGROUND) != 0;
}