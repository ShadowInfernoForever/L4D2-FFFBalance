#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
    name = "[FF] Laser Box Remover",
    author = "ShadowInferno",
    description = "Eliminate (upgrade_laser_sight) when initiating a round",
    version = "1.0",
    url = ""
};

#define LASER_BOX_CLASSNAME "upgrade_laser_sight"

public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    CreateTimer(0.1, Timer_RemoveLaserBoxes);
    return Plugin_Continue;
}

public Action Timer_RemoveLaserBoxes(Handle timer)
{
    for (int i = 1; i <= 2048; i++)
    {
        if (IsValidEntity(i))
        {
            char classname[64];
            GetEntityClassname(i, classname, sizeof(classname));

            if (StrEqual(classname, LASER_BOX_CLASSNAME))
            {
                AcceptEntityInput(i, "Kill");
            }
        }
    }
    return Plugin_Stop;
}